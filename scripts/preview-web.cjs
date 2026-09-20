'use strict';
// Local release preview, including the same API handler used by Vercel.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
for (const line of fs.readFileSync(path.join(root, '.env'), 'utf8').split(/\r?\n/)) {
  const match = line.match(/^\s*(GEMINI_API_KEY|GEMINI_MODEL)\s*=\s*(.*?)\s*$/);
  if (match) process.env[match[1]] = match[2].replace(/^(['"])(.*)\1$/, '$2');
}
process.env.GEMINI_MODEL ||= 'gemini-3.8-flash';
const handler = require('../api/gemini.js');
const webRoot = path.join(root, 'build/web');
const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.svg': 'image/svg+xml', '.ttf': 'font/ttf' };
http.createServer(async (req, res) => {
  res.status = code => { res.statusCode = code; return res; };
  res.json = body => { res.setHeader('Content-Type', 'application/json'); res.end(JSON.stringify(body)); };
  const url = new URL(req.url, 'http://localhost');
  if (url.pathname === '/api/gemini') {
    let body = '';
    for await (const chunk of req) {
      body += chunk;
      if (Buffer.byteLength(body) > 64000) { res.status(413).json({ error: 'Request too large' }); return; }
    }
    req.body = body;
    return handler(req, res);
  }
  let relative;
  try { relative = decodeURIComponent(url.pathname); } catch { res.statusCode = 400; return res.end(); }
  const file = path.resolve(webRoot, '.' + (relative === '/' ? '/index.html' : relative));
  if (!file.startsWith(webRoot + path.sep) || !fs.existsSync(file) || !fs.statSync(file).isFile()) {
    res.statusCode = 404; return res.end('Not found');
  }
  res.setHeader('Content-Type', types[path.extname(file)] || 'application/octet-stream');
  res.setHeader('Cache-Control', 'no-store');
  fs.createReadStream(file).pipe(res);
}).listen(8080, '127.0.0.1', () => console.log('Riyal release preview: http://127.0.0.1:8080'));
