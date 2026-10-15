#!/usr/bin/env bash
# Сборка веб-клиента для http://45.81.33.7/app/
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API="${API_BASE:-http://45.81.33.7}"
cd "$ROOT/prototype"
flutter pub get
flutter build web --release --no-tree-shake-icons \
  --base-href=/app/ \
  --dart-define=API_BASE="$API"
echo "OK: $ROOT/prototype/build/web → деплой: bash deploy/publish-web.sh"
