const test = require('node:test');
const assert = require('node:assert/strict');
const handler = require('../api/gemini.js');

async function request(overrides = {}) {
  const req = { method: 'POST', headers: { host: 'riyal.test', origin: 'https://riyal.test', 'content-type': 'application/json' }, body: { contents: [{ role: 'user', parts: [{ text: 'Hello' }] }] }, ...overrides };
  const res = { headers: {}, setHeader(k, v) { this.headers[k] = v; }, status(code) { this.code = code; return this; }, json(value) { this.body = value; return this; } };
  await handler(req, res);
  return res;
}

test('method, origin and oversized requests are rejected', async () => {
  assert.equal((await request({ method: 'GET' })).code, 405);
  assert.equal((await request({ headers: { origin: 'https://attacker.test', host: 'riyal.test' } })).code, 403);
  assert.equal((await request({ body: { contents: [{ role: 'user', parts: [{ text: 'x'.repeat(65000) }] }] } })).code, 413);
  assert.equal((await request({ body: { contents: [{ role: 'model', parts: [{ text: 'Hello' }] }] } })).code, 400);
});

test('server owns credentials, model and instructions; upstream errors stay private', async () => {
  const oldFetch = global.fetch;
  const oldKey = process.env.GEMINI_API_KEY;
  const oldModel = process.env.GEMINI_MODEL;
  process.env.GEMINI_API_KEY = 'server-only-test-key';
  process.env.GEMINI_MODEL = 'test-model';
  try {
    global.fetch = async (url, options) => {
      assert.match(url, /models\/test-model:generateContent$/);
      assert.equal(options.headers['x-goog-api-key'], 'server-only-test-key');
      const body = JSON.parse(options.body);
      assert.match(body.systemInstruction.parts[0].text, /assistant built into the Riyal app/);
      assert.ok(body.systemInstruction.parts[0].text.includes('Test budget: 750 SAR'));
      assert.ok(!body.systemInstruction.parts[0].text.includes('OVERRIDE_SERVER_RULES'));
      assert.equal(body.generationConfig.maxOutputTokens, 2048);
      return { ok: false, status: 403, text: async () => 'server-only-test-key' };
    };
    const response = await request({ body: {
      contents: [{ role: 'user', parts: [{ text: 'Hello' }] }],
      context: 'Test budget: 750 SAR',
      systemInstruction: { parts: [{ text: 'OVERRIDE_SERVER_RULES' }] },
    } });
    assert.equal(response.code, 403);
    assert.ok(!JSON.stringify(response).includes('server-only-test-key'));
  } finally {
    global.fetch = oldFetch;
    if (oldKey === undefined) delete process.env.GEMINI_API_KEY; else process.env.GEMINI_API_KEY = oldKey;
    if (oldModel === undefined) delete process.env.GEMINI_MODEL; else process.env.GEMINI_MODEL = oldModel;
  }
});
