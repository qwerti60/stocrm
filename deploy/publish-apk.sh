#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${VPS_HOST:-45.81.33.7}"
USER="${VPS_USER:-root}"
KEY="${VPS_KEY:-$HOME/.ssh/vagmarket_vps}"
for f in VAG-Market-32bit.apk VAG-Market-64bit.apk; do
  [[ -f "$ROOT/dist/$f" ]] || { echo "Нет $ROOT/dist/$f — сначала bash deploy/build-apk.sh" >&2; exit 1; }
done
rsync -avz -e "ssh -i $KEY -o StrictHostKeyChecking=no" \
  "$ROOT/dist/VAG-Market-32bit.apk" "$ROOT/dist/VAG-Market-64bit.apk" \
  "$USER@$HOST:/opt/vagmarket/dist/"
ssh -i "$KEY" -o StrictHostKeyChecking=no "$USER@$HOST" 'chown www-data:www-data /opt/vagmarket/dist/*.apk'
echo "64-bit: http://$HOST/apk/VAG-Market-64bit.apk"
echo "32-bit: http://$HOST/apk/VAG-Market-32bit.apk"
