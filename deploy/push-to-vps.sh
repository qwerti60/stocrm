#!/usr/bin/env bash
# Заливка на VPS 45.81.33.7. Пароль: VPS_PASS или server/.vps-pass (gitignore).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST="${VPS_HOST:-45.81.33.7}"
USER="${VPS_USER:-root}"
PASSFILE="$ROOT/server/.vps-pass"
ARCHIVE="$ROOT/dist/vagmarket-deploy.tar.gz"
ENVFILE="$ROOT/server/.env"
BOOT="$ROOT/deploy/bootstrap.sh"
KEY="$HOME/.ssh/vagmarket_vps"

if [[ -z "${VPS_PASS:-}" && -f "$PASSFILE" ]]; then
  VPS_PASS="$(tr -d '\r\n' < "$PASSFILE")"
fi
if [[ -z "${VPS_PASS:-}" ]]; then
  echo "Нет пароля root. Сохраните его в $PASSFILE (файл не в git) и повторите: bash deploy/push-to-vps.sh" >&2
  exit 1
fi
if [[ ! -f "$ENVFILE" ]]; then
  echo "Нет $ENVFILE" >&2
  exit 1
fi
if [[ ! -f "$KEY" ]]; then
  ssh-keygen -t ed25519 -N "" -f "$KEY" -C "vagmarket-vps"
fi
chmod +x "$BOOT"

python3 - "$ARCHIVE" "$ROOT" <<'PY'
import os, tarfile, sys
archive, root = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(archive), exist_ok=True)
skip = {".venv", "__pycache__", ".env", ".vps-pass"}
def filt(info):
    if any(p in skip or p.endswith(".pyc") for p in info.name.split("/")):
        return None
    return info
with tarfile.open(archive, "w:gz") as tar:
    for name in ("server", "deploy", "docs", "screenshots", "plan.html", "tz.html", "kp.html", "dogovor.html"):
        path = os.path.join(root, name)
        if os.path.exists(path):
            tar.add(path, arcname=name, filter=filt)
print("wrote", archive)
PY

export VPS_PASS HOST USER ARCHIVE ENVFILE BOOT KEY
expect <<'EOF'
set timeout 600
set pass $env(VPS_PASS)
set user $env(USER)
set host $env(HOST)
log_user 1

proc waitpass {} {
  global pass
  expect {
    -re "(?i)are you sure you want to continue connecting" { send "yes\r"; exp_continue }
    -re "(?i)password:" { send -- "$pass\r" }
    timeout { puts stderr "timeout on password"; exit 1 }
  }
}

spawn scp -o StrictHostKeyChecking=accept-new $env(ARCHIVE) $env(ENVFILE) $env(BOOT) $env(KEY).pub ${user}@${host}:/root/
waitpass
expect {
  eof {}
  timeout { puts stderr "scp timeout"; exit 1 }
}
if {[lindex [wait] 3] != 0} { puts stderr "scp failed"; exit 1 }

spawn ssh -o StrictHostKeyChecking=accept-new ${user}@${host} {set -eux
mkdir -p /root/.ssh
chmod 700 /root/.ssh
grep -q vagmarket-vps /root/.ssh/authorized_keys 2>/dev/null || cat /root/vagmarket_vps.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
rm -f /root/vagmarket_vps.pub
chmod +x /root/bootstrap.sh
bash /root/bootstrap.sh /root/vagmarket-deploy.tar.gz
systemctl restart vagmarket-api
curl -sS http://127.0.0.1:8080/health
}
waitpass
expect {
  eof {}
  timeout { puts stderr "ssh timeout"; exit 1 }
}
if {[lindex [wait] 3] != 0} { puts stderr "remote setup failed"; exit 1 }
EOF

echo "Проверка снаружи:"
curl -sS --max-time 15 "http://$HOST/health" || true
echo
