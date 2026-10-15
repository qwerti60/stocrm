#!/usr/bin/env bash
# Залить build/web на VPS (нужен ~/.ssh/vagmarket_vps).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${VPS_HOST:-45.81.33.7}"
USER="${VPS_USER:-root}"
KEY="${VPS_KEY:-$HOME/.ssh/vagmarket_vps}"
WEB="$ROOT/prototype/build/web"

if [[ ! -f "$WEB/index.html" ]]; then
  echo "Нет сборки. Сначала: bash deploy/build-web.sh" >&2
  exit 1
fi

ssh -i "$KEY" -o StrictHostKeyChecking=no "$USER@$HOST" 'mkdir -p /opt/vagmarket/prototype/build/web'
rsync -avz --delete -e "ssh -i $KEY -o StrictHostKeyChecking=no" \
  "$WEB/" "$USER@$HOST:/opt/vagmarket/prototype/build/web/"
ssh -i "$KEY" -o StrictHostKeyChecking=no "$USER@$HOST" \
  'chown -R www-data:www-data /opt/vagmarket/prototype/build/web && systemctl restart vagmarket-api'
echo "Web: http://$HOST/app/"
