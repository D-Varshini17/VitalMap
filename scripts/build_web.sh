#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_VERSION=3.47.2
if ! command -v flutter >/dev/null 2>&1; then
  SDK="$ROOT/.flutter-sdk"
  if [[ ! -x "$SDK/bin/flutter" ]]; then
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$SDK"
  fi
  export PATH="$SDK/bin:$PATH"
fi
flutter --version
cd "$ROOT/frontend"
flutter clean
flutter pub get --enforce-lockfile
flutter build web --release
node "$ROOT/scripts/write-build-info.cjs"