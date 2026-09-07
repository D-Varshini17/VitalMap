const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const reportRoot = path.join(root, 'artifacts/test-reports');
const excelRoot = path.join(reportRoot, 'excel');
fs.mkdirSync(reportRoot, { recursive: true });
fs.mkdirSync(excelRoot, { recursive: true });

function readJson(file) {
  try {
    return JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
  } catch (error) {
    return { missing: true, file, error: error.message };
  }
}

function rowsFromObject(object, prefix = '') {
  return Object.entries(object || {}).map(([key, value]) => ({
    Metric: prefix ? `${prefix}.${key}` : key,
    Value: value == null || typeof value !== 'object' ? value : JSON.stringify(value),
  }));
}

function flattenTrivyResults(trivy) {
  const results = Array.isArray(trivy.Results) ? trivy.Results : [];
  return {
    vulnerabilities: results.flatMap(result => (result.Vulnerabilities || []).map(item => ({
      Target: result.Target,
      Type: result.Type,
      VulnerabilityID: item.VulnerabilityID,
      Package: item.PkgName,
      InstalledVersion: item.InstalledVersion,
      FixedVersion: item.FixedVersion || '',
      Severity: item.Severity,
      Title: item.Title || '',
      PrimaryURL: item.PrimaryURL || '',
    }))),
    secrets: results.flatMap(result => (result.Secrets || []).map(item => ({
      Target: result.Target,
      RuleID: item.RuleID,
      Category: item.Category,
      Severity: item.Severity,
      Title: item.Title || '',
    }))),
    misconfigs: results.flatMap(result => (result.Misconfigurations || []).map(item => ({
      Target: result.Target,
      ID: item.ID,
      Type: item.Type,
      Severity: item.Severity,
      Title: item.Title || '',
      Message: item.Message || '',
    }))),
  };
}

function writeWorkbook(fileName, sheets) {
  let XLSX;
  try {
    XLSX = require('xlsx');
  } catch (error) {
    fs.writeFileSync(
      path.join(excelRoot, 'EXCEL_GENERATION_SKIPPED.txt'),
      `Install the npm package "xlsx" before running this script to generate Excel workbooks.\n${error.message}\n`,
    );
    return false;
  }
  const workbook = XLSX.utils.book_new();
  for (const [sheetName, rows] of Object.entries(sheets)) {
    const safeName = sheetName.slice(0, 31);
    const sheet = XLSX.utils.json_to_sheet(rows.length ? rows : [{ Message: 'No records found' }]);
    XLSX.utils.book_append_sheet(workbook, sheet, safeName);
  }
  XLSX.writeFile(workbook, path.join(excelRoot, fileName));
  return true;
}

const reports = {
  generatedAt: new Date().toISOString(),
  commit: process.env.GITHUB_SHA || process.env.REVISION || 'local',
  load: readJson('artifacts/test-reports/load/load-test.json'),
  appium: readJson('artifacts/test-reports/appium/appium-flutter-smoke.json'),
  trivy: readJson('artifacts/test-reports/security/trivy-results.json'),
};

const security = flattenTrivyResults(reports.trivy);
reports.securitySummary = {
  vulnerabilities: security.vulnerabilities.length,
  secrets: security.secrets.length,
  misconfigurations: security.misconfigs.length,
  criticalVulnerabilities: security.vulnerabilities.filter(v => v.Severity === 'CRITICAL').length,
  highVulnerabilities: security.vulnerabilities.filter(v => v.Severity === 'HIGH').length,
};
reports.pass = reports.load.pass === true && reports.appium.pass === true && reports.securitySummary.criticalVulnerabilities === 0;

const summaryRows = [
  { Area: 'Overall', Result: reports.pass ? 'PASS' : 'REVIEW', Detail: reports.commit },
  { Area: 'Load Testing', Result: reports.load.pass ? 'PASS' : 'FAIL/MISSING', Detail: `${reports.load.totalRequests ?? 'n/a'} requests, ${reports.load.failedRequests ?? 'n/a'} failed, p95 ${reports.load.latencyMs?.p95 ?? 'n/a'} ms` },
  { Area: 'Appium Flutter Android', Result: reports.appium.pass ? 'PASS' : 'FAIL/MISSING', Detail: reports.appium.automation ?? 'n/a' },
  { Area: 'Vulnerability Scan', Result: reports.securitySummary.criticalVulnerabilities === 0 ? 'PASS' : 'REVIEW', Detail: `${reports.securitySummary.vulnerabilities} vulnerabilities, ${reports.securitySummary.secrets} secrets, ${reports.securitySummary.misconfigurations} misconfigurations` },
];

const appiumSteps = Array.isArray(reports.appium.steps) ? reports.appium.steps : [];
const loadFailures = Array.isArray(reports.load.failures) ? reports.load.failures : [];

const excelGenerated = [
  writeWorkbook('load-test-report.xlsx', {
    Summary: rowsFromObject(reports.load),
    Latency: rowsFromObject(reports.load.latencyMs || {}, 'latencyMs'),
    Failures: loadFailures,
  }),
  writeWorkbook('appium-flutter-report.xlsx', {
    Summary: rowsFromObject(reports.appium),
    Steps: appiumSteps,
  }),
  writeWorkbook('vulnerability-report.xlsx', {
    Summary: rowsFromObject(reports.securitySummary),
    Vulnerabilities: security.vulnerabilities,
    Secrets: security.secrets,
    Misconfigurations: security.misconfigs,
  }),
  writeWorkbook('master-test-report.xlsx', {
    Summary: summaryRows,
    Load: rowsFromObject(reports.load),
    Appium: appiumSteps,
    Security: rowsFromObject(reports.securitySummary),
    Vulnerabilities: security.vulnerabilities,
  }),
].some(Boolean);

reports.excel = {
  generated: excelGenerated,
  files: excelGenerated ? [
    'excel/master-test-report.xlsx',
    'excel/load-test-report.xlsx',
    'excel/appium-flutter-report.xlsx',
    'excel/vulnerability-report.xlsx',
  ] : [],
};

const markdown = `# VitalMap Master Test Report\n\n- Commit: ${reports.commit}\n- Generated: ${reports.generatedAt}\n- Overall result: ${reports.pass ? 'PASS' : 'REVIEW'}\n\n## Load Testing\n\n- Result: ${reports.load.pass ? 'PASS' : 'FAIL/MISSING'}\n- Total requests: ${reports.load.totalRequests ?? 'n/a'}\n- Failed requests: ${reports.load.failedRequests ?? 'n/a'}\n- Requests/sec: ${reports.load.requestsPerSecond ?? 'n/a'}\n- p95 latency: ${reports.load.latencyMs?.p95 ?? 'n/a'} ms\n\n## Appium Flutter Android\n\n- Result: ${reports.appium.pass ? 'PASS' : 'FAIL/MISSING'}\n- Automation: ${reports.appium.automation ?? 'n/a'}\n- APK: ${reports.appium.apkPath ?? 'n/a'}\n\n## Vulnerability Scan\n\n- Scanner: Trivy filesystem scan\n- Vulnerabilities: ${reports.securitySummary.vulnerabilities}\n- Critical vulnerabilities: ${reports.securitySummary.criticalVulnerabilities}\n- High vulnerabilities: ${reports.securitySummary.highVulnerabilities}\n- Secrets: ${reports.securitySummary.secrets}\n- Misconfigurations: ${reports.securitySummary.misconfigurations}\n\n## Excel Workbooks\n\n${reports.excel.generated ? reports.excel.files.map(file => `- ${file}`).join('\n') : '- Excel generation skipped because the xlsx package was unavailable.'}\n\nDetailed JSON, Markdown, and Excel reports are included in this artifact directory.\n`;

fs.writeFileSync(path.join(reportRoot, 'master-test-report.json'), JSON.stringify(reports, null, 2));
fs.writeFileSync(path.join(reportRoot, 'MASTER_TEST_REPORT.md'), markdown);
console.log(markdown);
