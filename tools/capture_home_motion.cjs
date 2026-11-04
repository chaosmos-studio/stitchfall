const { spawn } = require('node:child_process');
const { mkdir, rm } = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require('playwright');

async function main() {
  const project = path.resolve(__dirname, '..');
  const results = path.join(project, 'build', 'test-results');
  const server = spawn('python3', ['-m', 'http.server', '8770', '--directory', path.join(project, 'build', 'web')], { stdio: 'ignore' });
  let browser;
  try {
    await mkdir(results, { recursive: true });
    for (let attempt = 0; attempt < 50; attempt++) {
      try {
        if ((await fetch('http://127.0.0.1:8770/')).ok) break;
      } catch (_) { /* Server is starting. */ }
      if (attempt === 49) throw new Error('Web server did not start');
      await new Promise(resolve => setTimeout(resolve, 200));
    }
    browser = await chromium.launch({ headless: true, executablePath: process.env.CHROME_PATH, args: [
      '--enable-webgl', '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'
    ] });
    const context = await browser.newContext({ viewport: { width: 844, height: 390 } });
    const page = await context.newPage();
    await page.goto('http://127.0.0.1:8770/', { timeout: 180000 });
    await page.waitForFunction(() => document.getElementById('loading')?.hidden, null, { timeout: 90000 });
    const frames = path.join(results, 'home-motion-frames');
    await mkdir(frames, { recursive: true });
    for (let index = 0; index < 80; index++) {
      await page.screenshot({ path: path.join(frames, `${String(index).padStart(3, '0')}.png`) });
      await page.waitForTimeout(90);
    }
    await context.close();
    const encode = spawn('ffmpeg', [
      '-y', '-loglevel', 'error', '-framerate', '8', '-i', path.join(frames, '%03d.png'),
      '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', '26', path.join(results, 'home-motion.webm')
    ]);
    const exitCode = await new Promise(resolve => encode.once('exit', resolve));
    if (exitCode !== 0) throw new Error(`Video encoding failed with exit code ${exitCode}`);
    await rm(frames, { recursive: true });
  } finally {
    if (browser) await browser.close();
    server.kill();
  }
}

main().catch(error => { console.error(error); process.exitCode = 1; });
