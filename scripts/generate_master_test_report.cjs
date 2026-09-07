const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const reportRoot = path.join(root, 'artifacts/test-reports');
fs.mkdirSync(reportRoot, { recursive: true });

function readJson(file) {
  try { return JSON.parse(fs.readFileSync(path.join(root, file), 'utf8')); }
  catch (error) { return { missing: true, file, error: error.message }; }
}

const reports = {
  generatedAt: new Date().toISOString(),
  commit: process.env.GITHUB_SHA || process.env.REVISION || 'local',
  load: readJson('artifacts/test-reports/load/load-test.json'),
  appium: readJson('artifacts/test-reports/appium/appium-flutter-smoke.json'),
  trivy: readJson('artifacts/test-reports/security/trivy-results.json'),
};

const trivyResults = Array.isArray(reports.trivy.Results) ? reports.trivy.Results : [];
const vulnerabilities = trivyResults.flatMap(r => r.Vulnerabilities || []);
const secrets = trivyResults.flatMap(r => r.Secrets || []);
const misconfigs = trivyResults.flatMap(r => r.Misconfigurations || []);
reports.securitySummary = {
  vulnerabilities: vulnerabilities.length,
  secrets: secrets.length,
  misconfigurations: misconfigs.length,
  criticalVulnerabilities: vulnerabilities.filter(v => v.Severity === 'CRITICAL').length,
  highVulnerabilities: vulnerabilities.filter(v => v.Severity === 'HIGH').length,
};
reports.pass = reports.load.pass === true && reports.appium.pass === true && reports.securitySummary.criticalVulnerabilities === 0;

const markdown = `# VitalMap Master Test Report\n\n- Commit: ${reports.commit}\n- Generated: ${reports.generatedAt}\n- Overall result: ${reports.pass ? 'PASS' : 'REVIEW'}\n\n## Load Testing\n\n- Result: ${reports.load.pass ? 'PASS' : 'FAIL/MISSING'}\n- Total requests: ${reports.load.totalRequests ?? 'n/a'}\n- Failed requests: ${reports.load.failedRequests ?? 'n/a'}\n- Requests/sec: ${reports.load.requestsPerSecond ?? 'n/a'}\n- p95 latency: ${reports.load.latencyMs?.p95 ?? 'n/a'} ms\n\n## Appium Flutter Android\n\n- Result: ${reports.appium.pass ? 'PASS' : 'FAIL/MISSING'}\n- Automation: ${reports.appium.automation ?? 'n/a'}\n- APK: ${reports.appium.apkPath ?? 'n/a'}\n\n## Vulnerability Scan\n\n- Scanner: Trivy filesystem scan\n- Vulnerabilities: ${reports.securitySummary.vulnerabilities}\n- Critical vulnerabilities: ${reports.securitySummary.criticalVulnerabilities}\n- High vulnerabilities: ${reports.securitySummary.highVulnerabilities}\n- Secrets: ${reports.securitySummary.secrets}\n- Misconfigurations: ${reports.securitySummary.misconfigurations}\n\nDetailed JSON/Markdown reports are included in this artifact directory.\n`;

fs.writeFileSync(path.join(reportRoot, 'master-test-report.json'), JSON.stringify(reports, null, 2));
fs.writeFileSync(path.join(reportRoot, 'MASTER_TEST_REPORT.md'), markdown);
console.log(markdown);
