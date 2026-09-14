"""Audit releasable source without printing any matched credential values."""
import hashlib
import json
import os
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
excluded = {'.git', '.venv', 'venv', 'build', '.dart_tool', '.gradle', '.kotlin', '__pycache__', '.pytest_cache', 'artifacts', 'temporary_git_transport', '.vercel', '.idea', '.vscode', 'ephemeral', 'vercel-dist', 'releases', '.agents', '.codex'}
patterns = [re.compile(r'sk-[A-Za-z0-9_-]{25,}'), re.compile(r'gh[pousr]_[A-Za-z0-9]{30,}'), re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----'), re.compile(r'AKIA[0-9A-Z]{16}')]
findings = []
manifest = {}
for directory, directories, filenames in os.walk(root):
    directories[:] = [name for name in directories if name not in excluded]
    for name in filenames:
        path = Path(directory) / name
        if (name.startswith('.env') and name != '.env.example') or name in {'local.properties', 'key.properties', '.flutter-plugins-dependencies', 'Generated.xcconfig', 'flutter_export_environment.sh'} or path.suffix in {'.apk', '.aab', '.jks', '.keystore', '.p12', '.pfx', '.log', '.pyc'}:
            continue
        data = path.read_bytes()
        relative = path.relative_to(root).as_posix()
        manifest[relative] = hashlib.sha256(data).hexdigest()
        if len(data) < 2_000_000 and b'\0' not in data:
            text = data.decode('utf-8', errors='replace')
            if any(pattern.search(text) for pattern in patterns):
                findings.append(relative)
preserved = {}
for name in ['backend/app/formulas.py', 'frontend/lib/core/local_analysis_engine.dart', 'frontend/assets/images/body_health_map.png']:
    before = root / 'artifacts/source-before-release' / name
    preserved[name] = before.exists() and before.read_bytes() == (root / name).read_bytes()
result = {'credential_pattern_findings': findings, 'preserved_source': preserved, 'source_files': len(manifest)}
(root / 'artifacts/source-manifest.json').write_text(json.dumps(manifest, indent=2))
(root / 'artifacts/security-audit.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
raise SystemExit(bool(findings) or not all(preserved.values()))
