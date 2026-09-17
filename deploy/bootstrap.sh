#!/usr/bin/env bash
# Ubuntu 22.04/24.04. Запускать с sudo на VPS.
# Архив: dist/vagmarket-deploy.tar.gz  (без .env и SID)
set -euo pipefail

ROOT=/opt/vagmarket
ARCHIVE="${1:-$HOME/vagmarket-deploy.tar.gz}"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Нет архива $ARCHIVE" >&2
  exit 1
fi

apt-get update
apt-get install -y python3 python3-venv python3-pip nginx

mkdir -p "$ROOT"
tar -xzf "$ARCHIVE" -C "$ROOT"

cd "$ROOT/server"
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Впишите STOCRM_SID и BFF_SECRET в $ROOT/server/.env" >&2
fi

install -m 644 "$ROOT/deploy/vagmarket-api.service" /etc/systemd/system/vagmarket-api.service
systemctl daemon-reload
systemctl enable --now vagmarket-api

echo "nginx: скопируйте deploy/nginx-vagmarket.conf в sites-available и certbot --nginx"
echo "curl -s http://127.0.0.1:8080/health"
