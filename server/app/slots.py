from __future__ import annotations

from datetime import date, datetime, time, timedelta
from typing import Any
from zoneinfo import ZoneInfo

MSK = ZoneInfo("Europe/Moscow")


def day_bounds(day: date) -> tuple[datetime, datetime]:
    if day.weekday() >= 5:
        start = datetime.combine(day, time(10, 0), tzinfo=MSK)
        end = datetime.combine(day, time(18, 0), tzinfo=MSK)
    else:
        start = datetime.combine(day, time(9, 0), tzinfo=MSK)
        end = datetime.combine(day, time(21, 0), tzinfo=MSK)
    return start, end


def unix(dt: datetime) -> int:
    return int(dt.timestamp())


def as_unix(v: Any) -> int | None:
    if v is None or v is False:
        return None
    if isinstance(v, (int, float)):
        n = int(v)
        if n > 10_000_000_000:
            return n // 1000
        return n
    s = str(v).strip()
    if s.isdigit():
        return as_unix(int(s))
    try:
        dt = datetime.fromisoformat(s.replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=MSK)
        return int(dt.timestamp())
    except Exception:
        return None


def parse_busy(
    cards: list[dict[str, Any]],
    *,
    exclude_offer_ids: set[int] | None = None,
) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    excluded = exclude_offer_ids or set()
    for c in cards:
        if str(c.get("DEACTIVATE") or "N").upper() == "Y":
            continue
        if excluded:
            oid = c.get("OFFER_ID")
            try:
                if int(oid) in excluded:
                    continue
            except (TypeError, ValueError):
                pass
        a = as_unix(c.get("DATE_FROM"))
        b = as_unix(c.get("DATE_TO"))
        if a is None or b is None or b <= a:
            continue
        out.append({"from": a, "to": b, "post": c.get("POST_ID"), "offer_id": c.get("OFFER_ID")})
    return out


def build_slots(
    *,
    day: date,
    cards: list[dict[str, Any]],
    post_ids: list[Any],
    now: datetime | None = None,
    exclude_offer_ids: set[int] | None = None,
) -> list[dict[str, Any]]:
    start, end = day_bounds(day)
    busy = parse_busy(cards, exclude_offer_ids=exclude_offer_ids)
    posts = {p for p in post_ids if p not in (None, "", 0, "0")}
    posts |= {c["post"] for c in busy if c["post"] not in (None, "", 0, "0")}
    capacity = max(len(posts), 2)
    now = now or datetime.now(MSK)
    out: list[dict[str, Any]] = []
    t = start
    hour = timedelta(hours=1)
    while t + hour <= end:
        ts0, ts1 = unix(t), unix(t + hour)
        occupied: set[Any] = set()
        anon = 0
        for c in busy:
            if c["from"] < ts1 and c["to"] > ts0:
                if c["post"] not in (None, "", 0, "0"):
                    occupied.add(c["post"])
                else:
                    anon += 1
                    occupied.add(f"anon:{anon}")
        free = max(capacity - len(occupied), 0)
        if free > 0 and (t + hour) > now:
            out.append(
                {
                    "at": t.isoformat(),
                    "label": t.strftime("%H:%M"),
                    "free": free,
                    "capacity": capacity,
                }
            )
        t += hour
    return out


def hour_start(dt: datetime) -> datetime:
    loc = dt.astimezone(MSK)
    return loc.replace(minute=0, second=0, microsecond=0)


def slot_free_at(
    *,
    when: datetime,
    day: date,
    cards: list[dict[str, Any]],
    post_ids: list[Any],
    exclude_offer_ids: set[int] | None = None,
) -> bool:
    """True if the hourly window at `when` has at least one free post."""
    target = hour_start(when)
    for s in build_slots(
        day=day,
        cards=cards,
        post_ids=post_ids,
        exclude_offer_ids=exclude_offer_ids,
    ):
        try:
            at = datetime.fromisoformat(str(s.get("at")).replace("Z", "+00:00"))
            if at.tzinfo is None:
                at = at.replace(tzinfo=MSK)
            if hour_start(at) == target:
                return int(s.get("free") or 0) > 0
        except (TypeError, ValueError):
            continue
    return False
