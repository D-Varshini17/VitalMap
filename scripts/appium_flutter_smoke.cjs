const fs = require('fs');
const path = require('path');

const outDir = path.resolve(__dirname, '../artifacts/test-reports/appium');
fs.mkdirSync(outDir, { recursive: true });

const report = {
  name: 'VitalMap Appium Flutter Android smoke test',
  automation: 'Appium UiAutomator2 against the Flutter Android APK',
  apkPath: process.env.APP_PATH || process.env.APK_PATH || 'frontend/build/app/outputs/flutter-apk/app-release.apk',
  startedAt: new Date().toISOString(),
  steps: [],
  pass: false,
};

function addStep(name, status, details = {}) {
  report.steps.push({ name, status, ...details });
}

(async () => {
  try {
    const { remote } = require('webdriverio');
    const appPath = path.resolve(process.cwd(), report.apkPath);
    if (!fs.existsSync(appPath)) throw new Error(`APK not found at ${appPath}`);
    addStep('APK exists', 'passed', { appPath });

    const driver = await remote({
      hostname: process.env.APPIUM_HOST || '127.0.0.1',
      port: Number(process.env.APPIUM_PORT || 4723),
      path: '/',
      logLevel: 'warn',
      capabilities: {
        platformName: 'Android',
        'appium:automationName': 'UiAutomator2',
        'appium:deviceName': process.env.APPIUM_DEVICE_NAME || 'Android Emulator',
        'appium:app': appPath,
        'appium:autoGrantPermissions': true,
        'appium:newCommandTimeout': 120,
      },
    });
    addStep('Appium session created', 'passed');

    await driver.pause(7000);
    const source = await driver.getPageSource();
    fs.writeFileSync(path.join(outDir, 'appium-page-source.xml'), source);
    const expected = ['Welcome to VitalMap', 'Create account'];
    for (const text of expected) {
      if (!source.includes(text)) throw new Error(`Expected text not found: ${text}`);
      addStep(`Visible text: ${text}`, 'passed');
    }

    await driver.deleteSession();
    addStep('Appium session closed', 'passed');
    report.pass = true;
  } catch (error) {
    addStep('Appium smoke test failed', 'failed', { error: error.message, stack: error.stack });
    report.error = error.message;
  } finally {
    report.finishedAt = new Date().toISOString();
    fs.writeFileSync(path.join(outDir, 'appium-flutter-smoke.json'), JSON.stringify(report, null, 2));
    fs.writeFileSync(path.join(outDir, 'appium-flutter-smoke.md'), `# Appium Flutter Android Smoke Report\n\n- Automation: ${report.automation}\n- APK: ${report.apkPath}\n- Result: ${report.pass ? 'PASS' : 'FAIL'}\n\n## Steps\n\n${report.steps.map(s => `- ${s.status.toUpperCase()}: ${s.name}${s.error ? ` — ${s.error}` : ''}`).join('\n')}\n`);
    console.log(JSON.stringify(report, null, 2));
    if (!report.pass) process.exit(1);
  }
})();
