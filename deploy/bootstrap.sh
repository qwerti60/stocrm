#!/usr/bin/env bash
# Ubuntu 22.04/24.04. Запускать с root на VPS.
# Архив: /root/vagmarket-deploy.tar.gz  (без SID)
set -euo pipefail

ROOT=/opt/vagmarket
ARCHIVE="${1:-/root/vagmarket-deploy.tar.gz}"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Нет архива $ARCHIVE" >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python3 python3-venv python3-pip nginx

mkdir -p "$ROOT"
tar -xzf "$ARCHIVE" -C "$ROOT"

cd "$ROOT/server"
python3 -m venv .venv
.venv/bin/pip install -U pip
.venv/bin/pip install -r requirements.txt

if [[ -f /root/.env ]]; then
  install -m 640 /root/.env "$ROOT/server/.env"
elif [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Нет .env — скопируйте с локальной машины (SID)." >&2
fi

chown -R www-data:www-data "$ROOT"
chmod 640 "$ROOT/server/.env" || true

install -m 644 "$ROOT/deploy/vagmarket-api.service" /etc/systemd/system/vagmarket-api.service
rm -f /etc/nginx/sites-enabled/default
install -m 644 "$ROOT/deploy/nginx-vagmarket.conf" /etc/nginx/sites-available/vagmarket
ln -sfn /etc/nginx/sites-available/vagmarket /etc/nginx/sites-enabled/vagmarket
nginx -t
systemctl daemon-reload
systemctl enable --now vagmarket-api nginx
systemctl reload nginx

if command -v ufw >/dev/null; then
  ufw allow OpenSSH || true
  ufw allow 80/tcp || true
  ufw allow 443/tcp || true
fi

curl -sS http://127.0.0.1:8080/health || true
echo "Публично: http://45.81.33.7/health"
