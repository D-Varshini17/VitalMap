const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const revision = process.env.VERCEL_GIT_COMMIT_SHA || execFileSync('git', ['rev-parse', 'HEAD'], {cwd: root, encoding: 'utf8'}).trim();
// Vercel excludes legacy artifacts using .vercelignore. Those omitted files can
// make the checkout look dirty even when the application source is untouched.
const sourceChanges = execFileSync('git', ['diff', '--name-only', 'HEAD', '--',
  'frontend/lib', 'frontend/web', 'frontend/pubspec.yaml', 'frontend/pubspec.lock'],
  {cwd: root, encoding: 'utf8'}).trim().split('\n').filter(Boolean);
if (process.env.VERCEL && sourceChanges.length) {
  throw new Error('Application source changed during the release build');
}
fs.writeFileSync(path.join(root, 'frontend/build/web/build-info.json'), JSON.stringify({
  revision, sourceChanges, dirty: sourceChanges.length > 0,
  builtAt: new Date().toISOString(),
}, null, 2));
