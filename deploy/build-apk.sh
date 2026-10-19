#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="${API_BASE:-http://45.81.33.7}"
export GRADLE_USER_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
cd "$ROOT/prototype"
flutter pub get
flutter build apk --split-per-abi --no-tree-shake-icons --dart-define=API_BASE="$API"
mkdir -p "$ROOT/dist"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "$ROOT/dist/VAG-Market-32bit.apk"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$ROOT/dist/VAG-Market-64bit.apk"
echo "OK: dist/VAG-Market-{32,64}bit.apk → bash deploy/publish-apk.sh"
