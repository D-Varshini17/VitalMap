#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
echo "Installing packages..."
flutter pub get
echo "Generating launcher icons..."
flutter pub run flutter_launcher_icons:main
echo "Icons generated."