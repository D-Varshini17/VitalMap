const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const root = path.resolve(__dirname, '..');
const revision = process.env.VERCEL_GIT_COMMIT_SHA || execFileSync('git', ['rev-parse', 'HEAD'], {cwd: root, encoding: 'utf8'}).trim();
const dirty = execFileSync('git', ['status', '--porcelain', '--untracked-files=no'], {cwd: root, encoding: 'utf8'}).trim().length > 0;
fs.writeFileSync(path.join(root, 'frontend/build/web/build-info.json'), JSON.stringify({revision, dirty, builtAt: new Date().toISOString()}, null, 2));