// Reuses the app's existing vector artwork for browsers without U+20C1.
// Development-only tools: npm install --prefix .tools svg2ttf svgpath
const fs = require('node:fs');
const path = require('node:path');
const svg2ttf = require('../.tools/node_modules/svg2ttf');
const svgpath = require('../.tools/node_modules/svgpath');
const root = path.resolve(__dirname, '..');
const svg = fs.readFileSync(path.join(root, 'assets/icons/saudi_riyal.svg'), 'utf8');
const outline = [...svg.matchAll(/<path[^>]*\sd="([^"]+)"/g)]
  .map(match => svgpath(match[1]).matrix([0.58, 0, 0, -0.58, 45, 760]).round(2).toString())
  .join(' ');
if (!outline) throw new Error('No Riyal vector paths found');
const font = `<svg xmlns="http://www.w3.org/2000/svg"><defs><font id="RiyalSymbol" horiz-adv-x="750"><font-face font-family="RiyalSymbol" units-per-em="1000" ascent="800" descent="-200"/><missing-glyph horiz-adv-x="750"/><glyph glyph-name="riyal" unicode="&#x20C1;" horiz-adv-x="750" d="${outline}"/></font></defs></svg>`;
const directory = path.join(root, 'assets/fonts/RiyalSymbol');
fs.mkdirSync(directory, { recursive: true });
fs.writeFileSync(path.join(directory, 'RiyalSymbol.ttf'), Buffer.from(svg2ttf(font, { ts: 0 }).buffer));
console.log('Generated RiyalSymbol.ttf from the existing Saudi riyal SVG.');
