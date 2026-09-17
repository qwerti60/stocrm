"""Снять карту Public API STOCRM. SID только в server/.env."""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from app.config import settings  # noqa: E402
from app.main import probe  # noqa: E402


def main() -> None:
    data = probe(x_bff_secret=settings.bff_secret)
    print(json.dumps(data, ensure_ascii=False, indent=2))
    ok = sum(1 for r in data["results"] if r.get("ok"))
    fail = sum(1 for r in data["results"] if r.get("ok") is False and not r.get("skipped"))
    print(f"\nOK {ok} · fail {fail} · base {data['base']}", file=sys.stderr)


if __name__ == "__main__":
    main()
