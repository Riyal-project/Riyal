'use strict';
const { chromium } = require('../.tools/node_modules/playwright-core');
const fs = require('node:fs');
const path = require('node:path');
let browser;
let page;

(async () => {
  browser = await chromium.launch({ executablePath: 'C:/Program Files/Google/Chrome/Application/chrome.exe', headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  page = await context.newPage();
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  fs.mkdirSync(path.join(__dirname, '../build/qa'), { recursive: true });
  const baseUrl = process.env.RIYAL_TEST_URL || 'http://127.0.0.1:8080';
  await page.goto(baseUrl, { waitUntil: 'networkidle', timeout: 90000 });
  await page.waitForSelector('flutter-view', { timeout: 60000 });
  await page.waitForTimeout(15000);
  // Use real canvas pointer input through the coin Hero transition.
  // Enabling Flutter's semantics overlay before this transition leaves its
  // form subtree absent in Flutter 3.38; enable it after creating the account.
  await page.screenshot({ path: 'build/qa/desktop.png' });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'build/qa/mobile.png' });
  await page.mouse.click(195, 611);
  await page.waitForTimeout(1000);
  await page.mouse.click(350, 26);
  await page.waitForTimeout(1500);
  await page.screenshot({ path: 'build/qa/login-mobile.png' });
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.waitForTimeout(700);
  await page.mouse.click(720, 674);
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'build/qa/signup-desktop.png' });
  const values = ['Web Preview', 'web-preview@example.com', 'DemoOnly123!', 'DemoOnly123!'];
  for (let i = 0; i < values.length; i++) {
    await page.mouse.click(720, [459, 487, 515, 542][i]);
    await page.waitForTimeout(500);
    await page.keyboard.type(values[i], { delay: 25 });
    await page.waitForTimeout(200);
  }
  await page.mouse.click(720, 568);
  await page.waitForTimeout(2000);
  for (let i = 0; i < 3; i++) {
    await page.mouse.click(720, [276, 344, 412][i]);
    await page.keyboard.type('750', { delay: 25 });
  }
  await page.mouse.click(720, 472);
  await page.waitForTimeout(1500);
  const enable = page.locator('flt-semantics-placeholder');
  if (await enable.count()) await enable.evaluate(element => element.click());
  await page.getByRole('button', { name: /Skip now/ }).click();
  await page.getByText('Hi, Web', { exact: true }).waitFor({ timeout: 30000 });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.waitForTimeout(1000);
  console.log('Home content:', (await page.locator('body').innerText()).slice(0, 2000));
  await page.screenshot({ path: 'build/qa/home-mobile.png' });
  await page.setViewportSize({ width: 1440, height: 900 });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'build/qa/home-desktop.png' });
  await page.setViewportSize({ width: 768, height: 1024 });
  await page.waitForTimeout(700);
  await page.screenshot({ path: 'build/qa/home-tablet.png' });
  const deviceBefore = await page.evaluate(() => {
    const key = Object.keys(localStorage).find(key => key.includes('device_id'));
    return key ? localStorage.getItem(key) : null;
  });
  if (!deviceBefore) throw new Error('Browser device identity was not persisted');
  await page.getByRole('button', { name: /Riyal/ }).click();
  await page.waitForTimeout(1000);
  await page.getByRole('textbox').filter({ visible: true }).fill('What is my subscriptions budget? State the exact amount in SAR.');
  const outgoing = page.waitForRequest(request => request.url().endsWith('/api/gemini'));
  const reply = page.waitForResponse(response => response.url().endsWith('/api/gemini'), { timeout: 60000 });
  await page.getByRole('button', { name: 'Send', exact: true }).click();
  const sent = (await outgoing).postDataJSON();
  if (!sent.context?.includes('750.00')) throw new Error('Current app budget missing from bot context');
  if (sent.systemInstruction || sent.apiKey) throw new Error('Client must not supply server instructions or credentials');
  const response = await reply;
  if (response.status() !== 200) throw new Error('Bot endpoint returned HTTP ' + response.status());
  const data = await response.json();
  if (!data.candidates?.[0]?.content?.parts?.some(part => part.text)) throw new Error('Bot returned no text');
  if (!data.candidates[0].content.parts.some(part => part.text?.includes('750'))) throw new Error('Bot did not use the supplied budget');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'build/qa/bot-tablet.png' });
  console.log('Browser bot round trip: passed');
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(7000);
  const deviceAfter = await page.evaluate(() => {
    const key = Object.keys(localStorage).find(key => key.includes('device_id'));
    return key ? localStorage.getItem(key) : null;
  });
  if (deviceBefore !== deviceAfter) throw new Error('Device identity changed after reload');
  console.log('Device identity survives reload: passed');
  console.log('Runtime error count:', errors.length);
  for (const error of errors) console.log(error.replace(/https?:\/\/[^\s]+/g, '<url>').slice(0, 500));
  await browser.close();
  if (errors.length) process.exitCode = 1;
})().catch(async error => {
  console.error(error.message);
  if (page) {
    await page.screenshot({ path: 'build/qa/failure.png' }).catch(() => {});
    console.error((await page.locator('body').innerText().catch(() => '')).slice(0, 1800));
  }
  await browser?.close();
  process.exitCode = 1;
});

