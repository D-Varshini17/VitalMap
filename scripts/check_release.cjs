const {execFileSync} = require('node:child_process');
const revision = execFileSync('git', ['rev-parse', 'HEAD'], {encoding: 'utf8'}).trim();
const credential = execFileSync('git', ['credential', 'fill'], {
  input: 'protocol=https\nhost=github.com\n\n', encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'],
});
const token = credential.split('\n').find(line => line.startsWith('password='))?.slice(9);
if (!token) throw new Error('No saved GitHub credential available');
const headers = {Authorization: `Bearer ${token}`, Accept: 'application/vnd.github+json'};
const base = 'https://api.github.com/repos/D-Varshini17/VitalMap';
async function get(url) {
  const response = await fetch(url, {headers});
  if (!response.ok) throw new Error(`GitHub status request failed: ${response.status}`);
  return response.json();
}
(async () => {
  const [status, runs] = await Promise.all([get(`${base}/commits/${revision}/status`), get(`${base}/actions/runs?head_sha=${revision}`)]);
  console.log(JSON.stringify({revision, deployments: status.statuses.map(s => ({name: s.context, state: s.state, url: s.target_url})), runs: runs.workflow_runs.map(r => ({id: r.id, status: r.status, conclusion: r.conclusion, url: r.html_url}))}, null, 2));
  for (const run of runs.workflow_runs) {
    if (process.argv.includes('--download-apk')) {
      const list = await get(`${base}/actions/runs/${run.id}/artifacts`);
      const artifact = list.artifacts.find(a => a.name === 'vitalmap-release-apk' && !a.expired);
      if (artifact) {
        const redirect = await fetch(`${base}/actions/artifacts/${artifact.id}/zip`, {headers, redirect: 'manual'});
        const location = redirect.headers.get('location');
        if (!location) throw new Error('Artifact download redirect missing');
        // The signed artifact URL needs no GitHub Authorization header.
        const download = await fetch(location);
        if (!download.ok) throw new Error('Artifact download failed');
        const fs = require('node:fs');
        fs.mkdirSync('artifacts/android-release', {recursive: true});
        fs.writeFileSync('artifacts/android-release/apk.zip', Buffer.from(await download.arrayBuffer()));
        console.log('Downloaded artifacts/android-release/apk.zip');
      }
    }
    const jobs = await get(`${base}/actions/runs/${run.id}/jobs`);
    console.log(JSON.stringify(jobs.jobs.map(j => ({id: j.id, status: j.status, conclusion: j.conclusion, steps: j.steps.map(s => ({name: s.name, status: s.status, conclusion: s.conclusion}))})), null, 2));
    if (run.conclusion === 'failure') {
      const checks = await get(`${base}/commits/${revision}/check-runs`);
      for (const check of checks.check_runs) {
        const notes = await get(`${base}/check-runs/${check.id}/annotations`);
        console.log(JSON.stringify(notes.map(n => ({path: n.path, message: n.message})), null, 2));
      }
    }
  }
})().catch(() => {console.error('Unable to retrieve authenticated release status.');process.exitCode = 1;});
