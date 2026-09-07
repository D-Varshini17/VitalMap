const http = require('http');
const fs = require('fs');
const path = require('path');
const { performance } = require('perf_hooks');

const root = path.resolve(__dirname, '../frontend/build/web');
const outDir = path.resolve(__dirname, '../artifacts/test-reports/load');
fs.mkdirSync(outDir, { recursive: true });

const durationMs = Number(process.env.LOAD_TEST_DURATION_MS || 15000);
const concurrency = Number(process.env.LOAD_TEST_CONCURRENCY || 12);
const paths = ['/', '/build-info.json', '/manifest.json'];
const contentTypes = new Map([
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'application/javascript; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.css', 'text/css; charset=utf-8'],
  ['.png', 'image/png'],
  ['.svg', 'image/svg+xml'],
  ['.wasm', 'application/wasm'],
]);

function serveFile(req, res) {
  const url = new URL(req.url, 'http://127.0.0.1');
  let filePath = path.join(root, decodeURIComponent(url.pathname));
  if (url.pathname === '/' || url.pathname.endsWith('/')) filePath = path.join(root, 'index.html');
  if (!filePath.startsWith(root)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    res.writeHead(200, { 'content-type': contentTypes.get(path.extname(filePath)) || 'application/octet-stream' });
    res.end(data);
  });
}

async function request(base, route) {
  const started = performance.now();
  return new Promise(resolve => {
    const req = http.get(`${base}${route}`, res => {
      res.resume();
      res.on('end', () => resolve({ route, status: res.statusCode, ms: performance.now() - started }));
    });
    req.setTimeout(10000, () => req.destroy(new Error('timeout')));
    req.on('error', error => resolve({ route, status: 0, ms: performance.now() - started, error: error.message }));
  });
}

function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.ceil((p / 100) * sorted.length) - 1;
  return sorted[Math.max(0, Math.min(sorted.length - 1, index))];
}

(async () => {
  if (!fs.existsSync(path.join(root, 'index.html'))) {
    throw new Error('frontend/build/web/index.html not found. Run flutter build web --release first.');
  }
  const server = http.createServer(serveFile);
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  const base = `http://127.0.0.1:${server.address().port}`;
  const results = [];
  const endAt = Date.now() + durationMs;
  let cursor = 0;

  async function worker() {
    while (Date.now() < endAt) {
      const route = paths[cursor++ % paths.length];
      results.push(await request(base, route));
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));
  server.close();

  const latencies = results.map(r => r.ms);
  const failed = results.filter(r => r.status < 200 || r.status >= 400);
  const report = {
    name: 'VitalMap web load smoke test',
    target: 'local production Flutter web build',
    durationMs,
    concurrency,
    totalRequests: results.length,
    failedRequests: failed.length,
    requestsPerSecond: Number((results.length / (durationMs / 1000)).toFixed(2)),
    latencyMs: {
      min: Number(Math.min(...latencies).toFixed(2)),
      p50: Number(percentile(latencies, 50).toFixed(2)),
      p95: Number(percentile(latencies, 95).toFixed(2)),
      max: Number(Math.max(...latencies).toFixed(2)),
    },
    pass: failed.length === 0 && percentile(latencies, 95) < 1000,
    failures: failed.slice(0, 25),
  };
  fs.writeFileSync(path.join(outDir, 'load-test.json'), JSON.stringify(report, null, 2));
  fs.writeFileSync(path.join(outDir, 'load-test.md'), `# Load Test Report\n\n- Target: ${report.target}\n- Duration: ${durationMs} ms\n- Concurrency: ${concurrency}\n- Total requests: ${report.totalRequests}\n- Failed requests: ${report.failedRequests}\n- Requests/sec: ${report.requestsPerSecond}\n- p95 latency: ${report.latencyMs.p95} ms\n- Result: ${report.pass ? 'PASS' : 'FAIL'}\n`);
  console.log(JSON.stringify(report, null, 2));
  if (!report.pass) process.exit(1);
})();
