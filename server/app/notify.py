from __future__ import annotations

import threading
import time
import uuid
from typing import Any

import httpx

from app.config import settings
from app.store import fcm_contact_ids, fcm_tokens, register_fcm_token

_lock = threading.Lock()
last_status: dict[tuple[int, int], int] = {}
inbox: dict[int, list[dict[str, Any]]] = {}
seen_contacts: set[int] = set()
_fcm_creds: Any = None


def register_device(contact_id: int, token: str) -> None:
    if not token or not contact_id:
        return
    register_fcm_token(int(contact_id), token)


def add_note(contact_id: int, title: str, body: str, offer_id: Any = None, kind: str = "ready") -> dict[str, Any]:
    note = {
        "id": uuid.uuid4().hex[:12],
        "title": title,
        "body": body,
        "offer_id": offer_id,
        "created": int(time.time()),
        "read": False,
        "kind": kind,
    }
    with _lock:
        inbox.setdefault(int(contact_id), []).insert(0, note)
    tokens = fcm_tokens(int(contact_id))
    for tok in tokens:
        send_fcm(tok, title, body)
    return note


def list_notes(contact_id: int) -> list[dict[str, Any]]:
    with _lock:
        return list(inbox.get(int(contact_id), []))


def known_contact_ids() -> list[int]:
    with _lock:
        ids = set(int(c) for c in inbox.keys())
        ids.update(int(c) for c in seen_contacts)
    ids.update(fcm_contact_ids())
    return sorted(ids)


def mark_read(contact_id: int, note_id: str) -> None:
    with _lock:
        for n in inbox.get(int(contact_id), []):
            if n["id"] == note_id:
                n["read"] = True


def is_ready_status(status_id: int | None, title: str) -> bool:
    t = (title or "").lower()
    if status_id in (6, 17953, 6845):
        return True
    return any(x in t for x in ("готов", "успешн", "выполнен"))


def poll_once(stocrm: Any, contact_ids: list[int]) -> int:
    created = 0
    unique = sorted({int(c) for c in contact_ids if c})
    for cid in unique:
        first = cid not in seen_contacts
        try:
            offers = stocrm.offers_by_contact(cid)
        except Exception:
            continue
        for o in offers:
            oid = int(o.get("OFFER_ID") or 0)
            if not oid:
                continue
            sid = int(o.get("OFFER_STATUS_ID") or 0)
            title = str(o.get("STATUS_NAME") or "")
            key = (cid, oid)
            with _lock:
                prev = last_status.get(key)
                last_status[key] = sid
            if first:
                continue
            became_ready = prev is not None and prev != sid and is_ready_status(sid, title) and not is_ready_status(prev, "")
            if became_ready:
                add_note(cid, "Ваша машина готова!", f"{title}. Заберите авто в сервисе.", oid)
                created += 1
        seen_contacts.add(cid)
    return created


def send_fcm(token: str, title: str, body: str) -> None:
    if not token:
        return
    access, project_id = _fcm_access()
    if not access or not project_id:
        return
    try:
        httpx.post(
            f"https://fcm.googleapis.com/v1/projects/{project_id}/messages:send",
            headers={"Authorization": f"Bearer {access}", "Content-Type": "application/json"},
            json={
                "message": {
                    "token": token,
                    "notification": {"title": title, "body": body},
                    "data": {"type": "ready"},
                    "android": {
                        "priority": "HIGH",
                        "notification": {"sound": "default", "channel_id": "vagmarket"},
                    },
                }
            },
            timeout=12.0,
        )
    except Exception:
        return


def _fcm_access() -> tuple[str, str]:
    global _fcm_creds
    path = settings.fcm_credentials_path
    if not path.is_file():
        return "", ""
    try:
        from google.auth.transport.requests import Request
        from google.oauth2 import service_account
    except ImportError:
        return "", ""
    try:
        with _lock:
            if _fcm_creds is None:
                _fcm_creds = service_account.Credentials.from_service_account_file(
                    str(path),
                    scopes=["https://www.googleapis.com/auth/firebase.messaging"],
                )
            if not _fcm_creds.valid:
                _fcm_creds.refresh(Request())
            project_id = str(getattr(_fcm_creds, "project_id", "") or "")
            if not project_id:
                import json

                project_id = str(json.loads(path.read_text(encoding="utf-8")).get("project_id") or "")
            return str(_fcm_creds.token or ""), project_id
    except Exception:
        return "", ""
