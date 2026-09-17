#!/usr/bin/env bash
# Локальный BFF + публичный HTTPS (Pinggy, ~60 мин на бесплатном тарифе).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/server"
if ! lsof -nP -iTCP:8080 -sTCP:LISTEN >/dev/null 2>&1; then
  .venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8080 &
  sleep 2
fi
exec ssh -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=30 \
  -p 443 -R0:127.0.0.1:8080 nokey@a.pinggy.io
