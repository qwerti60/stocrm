"""Список USER_ID сотрудников STOCRM (users/get_from_filter, wiki WIKI-A-720)."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.config import settings  # noqa: E402
from app.stocrm import StoCrm, _crm_phone_digits  # noqa: E402


def main() -> None:
    st = StoCrm()
    mgr = _crm_phone_digits(settings.stocrm_manager_phone)
    rid = st.booking_responsible_user_id()
    print(f"STOCRM_MANAGER_PHONE → {settings.stocrm_manager_phone!r} ({mgr or '—'})")
    print(f"STOCRM_BOOKING_RESPONSIBLE_ID / resolved → {settings.stocrm_booking_responsible_id!r} / {rid}")
    print()
    for u in sorted(st.users(), key=lambda x: int(x.get("USER_ID") or 0)):
        uid = int(u.get("USER_ID") or 0)
        title = (u.get("TITLE") or "").strip() or f"{u.get('LAST_NAME')} {u.get('FIRST_NAME')}".strip()
        p = _crm_phone_digits(u.get("PHONE"))
        w = _crm_phone_digits(u.get("WORK_PHONE"))
        mark = " ← manager" if mgr and (p == mgr or w == mgr) else ""
        print(f"{uid:6}  {title[:40]:40}  phone={p or '-':11}  work={w or '-'}{mark}")


if __name__ == "__main__":
    main()
