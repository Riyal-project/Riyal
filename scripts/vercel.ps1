param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CliArgs)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$nodeDirectory = Get-ChildItem -LiteralPath "$projectRoot/.tools" -Directory -Filter 'node-v*-win-x64' | Select-Object -First 1
if (!$nodeDirectory) { throw 'Local Node.js has not been prepared.' }
$env:Path = $nodeDirectory.FullName + ';' + $env:Path
$env:VERCEL_TELEMETRY_DISABLED = '1'
# The build script preserves this folder's .vercel project link.
Set-Location -LiteralPath "$projectRoot/build/vercel"
& "$projectRoot/.tools/node_modules/.bin/vercel.cmd" @CliArgs
exit $LASTEXITCODE
