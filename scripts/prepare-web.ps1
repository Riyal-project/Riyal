param([switch]$Build, [switch]$StageOnly)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $projectRoot
$values = @{}
foreach ($line in Get-Content -LiteralPath '.env' -Encoding UTF8) {
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
        $values[$Matches[1]] = $Matches[2].Trim().Trim('"').Trim("'")
    }
}
foreach ($name in @('SUPABASE_URL', 'SUPABASE_ANON_KEY')) {
    if ([string]::IsNullOrWhiteSpace($values[$name])) { throw "Missing $name in .env" }
}
if ($values.SUPABASE_URL -notmatch '^https://[^/]+/?$') { throw 'Expected an HTTPS Supabase project URL.' }
$publicKey = $values.SUPABASE_ANON_KEY
if ($publicKey -notlike 'sb_publishable_*') {
    try {
        $part = $publicKey.Split('.')[1].Replace('-', '+').Replace('_', '/')
        $part = $part.PadRight($part.Length + ((4 - $part.Length % 4) % 4), '=')
        $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($part)) | ConvertFrom-Json
        if ($claims.role -ne 'anon') { throw 'Not an anonymous client key' }
    } catch { throw 'SUPABASE_ANON_KEY must be a publishable key or an anon JWT, never a server secret.' }
}
$utf8 = New-Object Text.UTF8Encoding($false)
New-Item -ItemType Directory -Path 'assets/config' -Force | Out-Null
# Explicit allowlist: never copy the source .env into a client build.
$publicLines = @(
    ('SUPABASE_URL=' + $values.SUPABASE_URL)
    ('SUPABASE_ANON_KEY=' + $publicKey)
)
if ($values.GEMINI_PROXY_URL) { $publicLines += 'GEMINI_PROXY_URL=' + $values.GEMINI_PROXY_URL }
[IO.File]::WriteAllText((Join-Path $projectRoot 'assets/config/public.env'), ($publicLines -join "`n") + "`n", $utf8)
Write-Host 'Public client configuration prepared. No server keys copied.'
if (!$Build -and !$StageOnly) { exit 0 }
if (!$StageOnly) {
    & flutter build web --release
    if ($LASTEXITCODE -ne 0) { throw 'Flutter web build failed.' }
}
if (!(Test-Path -LiteralPath 'build/web/main.dart.js')) { throw 'Build the web release first.' }
if (!$StageOnly) {
    $revision = (& git rev-parse HEAD).Trim()
    $buildInfo = @{ sourceRevision = $revision; builtAtUtc = [DateTime]::UtcNow.ToString('o') } | ConvertTo-Json
    [IO.File]::WriteAllText((Join-Path $projectRoot 'build/web/build-info.json'), $buildInfo, $utf8)
}
# Remove only stale output left by the old asset declaration.
$staleEnv = Join-Path $projectRoot 'build/web/assets/.env'
if (Test-Path -LiteralPath $staleEnv) { Remove-Item -LiteralPath $staleEnv }
$secretNames = @('GEMINI_API_KEY', 'LEAN_APP_TOKEN', 'SUPABASE_SERVICE_ROLE_KEY')
foreach ($file in Get-ChildItem -LiteralPath 'build/web' -File -Recurse -Force) {
    $content = [Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($file.FullName))
    foreach ($name in $secretNames) {
        $secret = $values[$name]
        if ($secret -and $secret.Length -gt 8 -and $content.Contains($secret)) {
            throw "Secret scan failed for $name. Deployment staging stopped."
        }
    }
}
# Keep the deployable folder separate from the source tree and all local secrets.
$stage = Join-Path $projectRoot 'build/vercel'
if (Test-Path -LiteralPath $stage) {
    $resolved = (Resolve-Path -LiteralPath $stage).Path
    if ($resolved -ne (Join-Path $projectRoot 'build/vercel').Replace('/', '\')) { throw 'Unexpected staging path.' }
    # Keep Vercel's project link across builds. Clear only generated artifacts.
    foreach ($child in Get-ChildItem -LiteralPath $resolved -Force) {
        if ($child.Name -eq '.vercel') { continue }
        if (!$child.FullName.StartsWith($resolved + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Unexpected staging child.' }
        Remove-Item -LiteralPath $child.FullName -Recurse -Force
    }
}
New-Item -ItemType Directory -Path "$stage/public", "$stage/api" -Force | Out-Null
Copy-Item -Path 'build/web/*' -Destination "$stage/public" -Recurse
Copy-Item -LiteralPath 'api/gemini.js' -Destination "$stage/api/gemini.js"
# Use exactly the same Riyal instructions as the native app, without duplicating them.
$promptSource = Get-Content -LiteralPath 'lib/services/riyal_bot_prompt.dart' -Raw -Encoding UTF8
$prompt = [regex]::Match($promptSource, "(?s)const riyalBotPrompt = '''(.*?)''';").Groups[1].Value
if (!$prompt) { throw 'Could not extract the Riyal Bot instructions.' }
[IO.File]::WriteAllText("$stage/api/prompt.json", (ConvertTo-Json -InputObject $prompt), $utf8)
Copy-Item -LiteralPath 'vercel.json' -Destination "$stage/vercel.json"
[IO.File]::WriteAllText("$stage/package.json", '{"private":true,"engines":{"node":"22.x"}}', $utf8)
Write-Host 'Release built and secret scan passed. Deployable project: build/vercel'
