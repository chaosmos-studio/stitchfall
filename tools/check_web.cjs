const { spawn } = require('node:child_process');
const { mkdir } = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require('playwright');

const PHONE = { viewport: { width: 844, height: 390 }, isMobile: true, hasTouch: true };
const DESKTOP = { viewport: { width: 1280, height: 720 } };

// The buttons the check presses, as hud.gd's Rect2(x, y, width, height) in the 1920 x 1080 design.
const HUD = {
  // _build_home: the browser build has no Shop, so its five rows are 88 apart.
  home: { play: [146, 428, 560, 82], levels: [146, 516, 560, 82], guide: [146, 692, 560, 82], settings: [146, 780, 560, 82] },
  // _build_help: Back, and the play tag that starts the room.
  guide: { back: [1560, 130, 112, 105], start: [1490, 810, 145, 126] },
  // _build_settings: tags four to a row, FULLSCREEN last in the first row and ABOUT third in the second.
  settings: { back: [1420, 125, 105, 105], fullscreen: [1245, 250, 255, 270], about: [970, 550, 255, 270] },
  // _build_about: Back, which leads to Settings.
  about: { back: [1510, 138, 112, 105] },
  // _build_levels: a chapter a page, Next beside Home, and the chapter's fifth room tile.
  levels: { next: [1580, 102, 100, 101], fifthRoom: [1470, 330, 310, 360] },
  // _build_pause: HOME, right of RESUME.
  pause: { home: [1120, 500, 230, 255] },
};

// The 1920 x 1080 design is stretched with canvas_items and aspect expand, so a screen wider than 16:9 shows a root
// wider than 1920. Home is laid out from the root's left edge, every other page is 1920 wide and centred in it, and
// the pause tag (112 x 108 at y 18, 1.2 times larger on a touchscreen) keeps 28 from its right edge (hud.gd _layout).
// The browser build carries no banner, so no page shrinks for one.
function screen({ width, height }, touch) {
  const scale = Math.min(width / 1920, height / 1080);
  const rootWidth = width / scale;
  const centre = ([x, y, w, h], left) => ({ x: (left + x + w / 2) * scale, y: (y + h / 2) * scale });
  const tag = touch ? 1.2 : 1.0;
  return {
    home: rect => centre(rect, 0),
    page: rect => centre(rect, (rootWidth - 1920) / 2),
    pause: () => centre([rootWidth - 28 - 112 * tag, 18, 112 * tag, 108 * tag], 0),
  };
}

// Resolves on the next line the game prints that is `marker` or starts with it and a space, so START 5 never
// answers for START 50.
function printed(page, marker, timeout = 10000) {
  return page.waitForEvent('console', { predicate: message => message.text() === marker || message.text().startsWith(`${marker} `), timeout });
}

// A fresh browser has only the first room open. This save has skipped room 9, which opens room 10 on the Levels
// second page while Levels still opens on the first. Godot keeps user:// in Emscripten's IDBFS: an IndexedDB
// database named after the /userfs mount, holding an entry for every directory and file under it.
async function seedSave(context, baseUrl, text) {
  const page = await context.newPage();
  await page.goto(new URL('build-info.json', baseUrl).toString());
  await page.evaluate(async text => {
    const db = await new Promise((resolve, reject) => {
      const request = indexedDB.open('/userfs', 21);
      request.onupgradeneeded = () => request.result.createObjectStore('FILE_DATA').createIndex('timestamp', 'timestamp', { unique: false });
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
    const transaction = db.transaction('FILE_DATA', 'readwrite');
    const store = transaction.objectStore('FILE_DATA');
    const timestamp = new Date();
    for (const folder of ['/userfs/godot', '/userfs/godot/app_userdata', '/userfs/godot/app_userdata/Stitchfall']) {
      store.put({ timestamp, mode: 0o40775 }, folder);
    }
    store.put({ timestamp, mode: 0o100666, contents: new TextEncoder().encode(text) }, '/userfs/godot/app_userdata/Stitchfall/progress.cfg');
    await new Promise((resolve, reject) => {
      transaction.oncomplete = resolve;
      transaction.onerror = () => reject(transaction.error);
    });
    db.close();
  }, text);
  await page.close();
}

async function main() {
  const project = path.resolve(__dirname, '..');
  const baseUrl = process.env.WEB_TEST_URL || 'http://127.0.0.1:8769/';
  const server = spawn('python3', ['-m', 'http.server', '8769', '--directory', path.join(project, 'build', 'web')], { stdio: 'ignore' });
  let browser;
  try {
    for (let attempt = 0; attempt < 50; attempt++) {
      try {
        if ((await fetch('http://127.0.0.1:8769/')).ok) break;
      } catch (_) { /* Server is starting. */ }
      if (attempt === 49) throw new Error('Web server did not start');
      await new Promise(resolve => setTimeout(resolve, 200));
    }
    browser = await chromium.launch({ headless: true, executablePath: process.env.CHROME_PATH, args: [
      '--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'
    ] });
    const phone = screen(PHONE.viewport, true);
    const tap = async (page, point, settle = 250) => {
      await page.touchscreen.tap(point.x, point.y);
      await page.waitForTimeout(settle);
    };
    const context = await browser.newContext(PHONE);
    await seedSave(context, baseUrl, '[skipped]\n\n8=true\n');
    const page = await context.newPage();
    const errors = [];
    const shifts = [];
    page.on('pageerror', error => errors.push(String(error)));
    page.on('console', message => {
      if (message.type() === 'error') errors.push(message.text());
      if (message.text().startsWith('STITCHFALL_SHIFT ')) shifts.push(message.text());
    });
    await page.goto(baseUrl, { timeout: 180000 });
    await page.waitForFunction(() => /\d+\.\d+ \/ \d+\.\d+ MB/.test(document.getElementById('bytes')?.textContent ?? ''), null, { timeout: 10000 });
    const results = path.join(project, 'build', 'test-results');
    await mkdir(results, { recursive: true });
    await page.screenshot({ path: path.join(results, 'loading.png') });
    try {
      await page.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
    } catch (error) {
      const progress = await page.locator('#bytes').textContent();
      const failure = await page.locator('#error').textContent();
      throw new Error(`Game loading stalled at ${progress}: ${failure || error}`);
    }
    if (await page.locator('#error').textContent()) throw new Error(await page.locator('#error').textContent());
    await page.waitForTimeout(800);
    if (errors.length) throw new Error(errors.join('\n'));
    await page.screenshot({ path: path.join(results, 'intro.png') });
    if (await page.locator('#fullscreen').count()) throw new Error('Fullscreen should live inside Settings');
    const needleCursor = await page.locator('#canvas').evaluate(() => [...document.styleSheets].some(sheet =>
      [...sheet.cssRules].some(rule => rule.selectorText === 'canvas' && rule.style.cursor.includes('sewing_cursor.png'))));
    if (!needleCursor) throw new Error('The needle cursor is missing from the playfield');
    await page.waitForTimeout(600);
    await page.screenshot({ path: path.join(results, 'intro-dance.png') });
    await page.waitForTimeout(2500);
    await page.screenshot({ path: path.join(results, 'intro-air-early.png') });
    await page.waitForTimeout(5300);
    await page.screenshot({ path: path.join(results, 'intro-air-late.png') });
    await tap(page, phone.home(HUD.home.play));
    await page.screenshot({ path: path.join(results, 'first-play-guide.png') });
    await tap(page, phone.page(HUD.guide.back));
    await tap(page, phone.home(HUD.home.settings));
    await page.screenshot({ path: path.join(results, 'settings.png') });
    if (await page.evaluate(() => document.fullscreenEnabled)) {
      await tap(page, phone.page(HUD.settings.fullscreen), 0);
      await page.waitForFunction(() => document.fullscreenElement, null, { timeout: 5000 });
      await page.evaluate(() => document.exitFullscreen());
    }
    await tap(page, phone.page(HUD.settings.about));
    await page.screenshot({ path: path.join(results, 'about.png') });
    await tap(page, phone.page(HUD.about.back));
    await tap(page, phone.page(HUD.settings.back));
    await tap(page, phone.home(HUD.home.levels));
    await page.screenshot({ path: path.join(results, 'levels.png') });
    await tap(page, phone.page(HUD.levels.next));
    await page.screenshot({ path: path.join(results, 'levels-second.png') });
    let marker = printed(page, 'STITCHFALL_START 9');
    await tap(page, phone.page(HUD.levels.fifthRoom), 0);
    await marker.catch(error => { throw new Error(`Room 10 did not start from the Levels second page, so the seeded save may not have loaded: ${error}`); });
    await page.waitForTimeout(300);
    await tap(page, phone.pause());
    await page.screenshot({ path: path.join(results, 'pause.png') });
    await tap(page, phone.page(HUD.pause.home));
    await page.screenshot({ path: path.join(results, 'home-return.png') });
    await tap(page, phone.home(HUD.home.guide));
    await page.screenshot({ path: path.join(results, 'help.png') });
    await page.waitForTimeout(650);
    await page.screenshot({ path: path.join(results, 'help-next.png') });
    marker = printed(page, 'STITCHFALL_START 9');
    await tap(page, phone.page(HUD.guide.start), 0);
    await marker;
    await page.waitForTimeout(600);
    if (shifts.length) throw new Error('Starting the game turned gravity');
    const cdp = await page.context().newCDPSession(page);
    marker = printed(page, 'STITCHFALL_JUMP');
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 550, y: 315, id: 0 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 550, y: 170, id: 0 }] });
    await marker;
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(results, 'jump.png') });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 550, y: 195, id: 0 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 550, y: 335, id: 0 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(120);
    await page.screenshot({ path: path.join(results, 'crouch.png') });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x: 310, y: 275, id: 0 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: 455, y: 275, id: 0 }] });
    await page.waitForTimeout(280);
    await page.screenshot({ path: path.join(results, 'run.png') });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    if (shifts.length) throw new Error(`A movement gesture turned gravity: ${shifts.join(', ')}`);
    marker = printed(page, 'STITCHFALL_SHIFT');
    await page.touchscreen.tap(680, 260);
    await marker;
    await page.waitForTimeout(300);
    if (shifts.length !== 1) throw new Error(`One tap turned gravity ${shifts.length} times`);
    if (errors.length) throw new Error(errors.join('\n'));
    await page.screenshot({ path: path.join(results, 'mobile.png') });
    await context.close();
    const desktop = await browser.newPage(DESKTOP);
    await desktop.goto(baseUrl, { timeout: 180000 });
    await desktop.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
    await desktop.waitForTimeout(800);
    const desktopStart = printed(desktop, 'STITCHFALL_START 0');
    const play = screen(DESKTOP.viewport, false).home(HUD.home.play);
    await desktop.mouse.click(play.x, play.y);
    await desktopStart;
    await desktop.locator('#canvas').focus();
    await desktop.waitForTimeout(350);
    const desktopJump = printed(desktop, 'STITCHFALL_JUMP');
    await desktop.keyboard.press('w');
    await desktopJump;
    await desktop.keyboard.down('s');
    await desktop.waitForTimeout(140);
    await desktop.keyboard.up('s');
    const desktopShift = printed(desktop, 'STITCHFALL_SHIFT');
    await desktop.keyboard.press('Shift');
    await desktopShift;
    await desktop.screenshot({ path: path.join(results, 'desktop.png') });
    await desktop.close();
    // The first room of each chapter with a look of its own.
    for (const [room, chapter] of [[15, 'seams'], [20, 'moths'], [25, 'patch'], [30, 'water'], [35, 'dunes'], [40, 'canopy'], [45, 'night'], [50, 'rain'], [55, 'frost']]) {
      const preview = await browser.newPage(PHONE);
      const previewErrors = [];
      preview.on('pageerror', error => previewErrors.push(String(error)));
      const roomLoaded = printed(preview, `STITCHFALL_ROOM ${room}`, 90000);
      await preview.goto(new URL(`?room=${room}`, baseUrl).toString(), { timeout: 180000 });
      await roomLoaded;
      await preview.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
      const started = printed(preview, `STITCHFALL_START ${room}`);
      await tap(preview, phone.home(HUD.home.play));
      await tap(preview, phone.page(HUD.guide.start), 0);
      await started;
      await preview.waitForTimeout(400);
      await preview.screenshot({ path: path.join(results, `${chapter}.png`) });
      if (previewErrors.length) throw new Error(previewErrors.join('\n'));
      await preview.close();
    }
    console.log('MOBILE_WEB_OK stitchfall');
  } finally {
    if (browser) await browser.close();
    if (server.exitCode === null) {
      server.kill();
      await new Promise(resolve => server.once('exit', resolve));
    }
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
