from __future__ import annotations

from typing import Any

import httpx
import time

from app.config import settings


class StoCrmError(RuntimeError):
    def __init__(self, path: str, status: int, body: Any):
        super().__init__(f"STOCRM {path} → {status}: {body}")
        self.path = path
        self.status = status
        self.body = body


class StoCrm:
    def __init__(self) -> None:
        self._client = httpx.Client(timeout=60.0)
        self._statuses: list[dict[str, Any]] | None = None

    def close(self) -> None:
        self._client.close()

    def call(self, path: str, payload: dict[str, Any] | None = None, method: str = "POST") -> Any:
        last: Any = None
        for attempt in range(3):
            last = self._request(path, payload=payload, method=method)
            if not _is_rate_limited(last):
                return self._check(path, 200, last)
            time.sleep(1.2 * (attempt + 1))
        return self._check(path, 200, last)

    def call_get(self, path: str, params: list[tuple[str, str]] | None = None) -> Any:
        last: Any = None
        for attempt in range(3):
            last = self._request(path, params=params, method="GET")
            if not _is_rate_limited(last):
                return self._check(path, 200, last)
            time.sleep(1.2 * (attempt + 1))
        return self._check(path, 200, last)

    def _request(
        self,
        path: str,
        payload: dict[str, Any] | None = None,
        params: list[tuple[str, str]] | None = None,
        method: str = "POST",
    ) -> Any:
        if not settings.stocrm_sid:
            raise StoCrmError(path, 0, "STOCRM_SID пустой — пропишите server/.env")
        url = f"{settings.base_url}/{path.lstrip('/')}"
        if method == "GET":
            if params is not None:
                qs = [("SID", settings.stocrm_sid), *params]
                r = self._client.get(url, params=qs)
            else:
                body = {"SID": settings.stocrm_sid, **(payload or {})}
                r = self._client.get(url, params=body)
        else:
            body = {"SID": settings.stocrm_sid, **(payload or {})}
            r = self._client.post(url, json=body)
        try:
            data = r.json()
        except Exception:
            data = r.text
        if r.status_code >= 400:
            raise StoCrmError(path, r.status_code, data)
        return data

    def _check(self, path: str, status: int, data: Any) -> Any:
        if isinstance(data, dict):
            if data.get("IS_AUTHORIZE") is False:
                raise StoCrmError(path, status, data)
            code = data.get("CODE")
            msg = str(data.get("MESSAGE") or "")
            if data.get("RESPONSE") is False and "не найден" in msg.lower():
                return {"RESPONSE": {"DATA": [], "TOTAL_COUNT": 0}, "CODE": 200}
            if code == 666 or (isinstance(code, int) and code >= 400):
                raise StoCrmError(path, status, data)
        return data

    def probe(self, path: str, payload: dict[str, Any] | None = None) -> dict[str, Any]:
        try:
            data = self.call(path, payload)
            snippet = data
            if isinstance(data, dict):
                resp = data.get("RESPONSE", data)
                if isinstance(resp, list):
                    snippet = {"count": len(resp), "sample": resp[:2]}
                elif isinstance(resp, dict):
                    snippet = {"keys": list(resp.keys())[:24], "sample": _trim(resp)}
            return {"ok": True, "path": path, "data": snippet}
        except StoCrmError as e:
            return {"ok": False, "path": path, "status": e.status, "error": str(e.body)[:800]}
        except Exception as e:
            return {"ok": False, "path": path, "error": str(e)[:800]}

    def find_contact(self, phone: str) -> dict[str, Any] | None:
        seen: set[int] = set()
        found: dict[str, Any] | None = None
        for v in (phone, phone[1:] if phone.startswith("7") else phone, f"+{phone}"):
            for c in self.contacts_by_phone(v):
                cid = int(c.get("CONTACT_ID") or c.get("ID") or 0)
                if cid and cid not in seen:
                    seen.add(cid)
                    found = found or c
        return found

    def contact_properties(self, contact_id: int) -> list[dict[str, Any]]:
        data = self.call(
            "contact/properties/get_filtered",
            {"FILTER": {"CONTACT_ID": int(contact_id)}, "PAGE": 1, "LIMIT": 50},
        )
        return _as_list(data)

    def contact_email(self, contact_id: int) -> str | None:
        for p in self.contact_properties(contact_id):
            ptype = str(p.get("TYPE") or "").lower()
            if int(p.get("PROP_TYPE_ID") or 0) != 2 and ptype != "email":
                continue
            val = str(p.get("VALUE") or "").strip()
            if val and "@" in val:
                return val.lower()
        return None

    def contact_set_email(self, contact_id: int, email: str) -> Any:
        email = email.strip().lower()
        existing = None
        for p in self.contact_properties(contact_id):
            ptype = str(p.get("TYPE") or "").lower()
            if int(p.get("PROP_TYPE_ID") or 0) == 2 or ptype == "email":
                existing = p
                break
        if existing and existing.get("CONTACT_PROPERTY_ID"):
            prop = {
                "ACTION": "UPDATE",
                "CONTACT_PROPERTY_ID": int(existing["CONTACT_PROPERTY_ID"]),
                "PROP_TYPE_ID": 2,
                "VALUE": email,
                "MAIN": "Y",
            }
        else:
            prop = {"ACTION": "CREATE", "PROP_TYPE_ID": 2, "VALUE": email, "MAIN": "Y"}
        return self.call("contact/update", {"CONTACT_ID": int(contact_id), "PROP": [prop]})

    def contact_create(self, phone: str, email: str, firstname: str = "") -> int:
        params = [
            ("PROPERTIES[1][0][VALUE]", phone),
            ("PROPERTIES[1][0][MAIN]", "Y"),
            ("PROPERTIES[2][0][VALUE]", email.strip().lower()),
            ("PROPERTIES[2][0][MAIN]", "Y"),
        ]
        if firstname.strip():
            params.append(("FLAT[FIRSTNAME]", firstname.strip()))
        data = self.call_get("contact/create", params)
        cid = _as_id(data)
        if not cid:
            raise StoCrmError("contact/create", 0, data)
        return cid

    def car_add(
        self,
        contact_id: int,
        *,
        title: str,
        plate: str = "",
        vin: str = "",
        year: int | None = None,
        mileage: int | None = None,
    ) -> int:
        payload: dict[str, Any] = {"CONTACT_ID": int(contact_id), "TITLE": (title or "Авто").strip() or "Авто"}
        if plate.strip():
            plate_u = plate.strip().upper()
            payload["LICENSE_PLATE"] = plate_u
            payload["LICENSE_PLATE_NUMBER"] = plate_u
        if vin.strip():
            payload["VIN"] = vin.strip().upper()
        if year:
            payload["YEAR"] = int(year)
        if mileage is not None:
            payload["MILEAGE"] = int(mileage)
        data = self.call("contact/add_car", payload)
        cid = _as_id(data)
        if not cid:
            raise StoCrmError("contact/add_car", 0, data)
        return cid

    def car_mark_sold(self, car_id: int) -> bool:
        payload = {"CAR_PROFILE_ID": int(car_id), "FLAT": {"SOLD": "Y"}}
        try:
            data = self.call("car/edit", payload)
        except StoCrmError:
            return False
        if isinstance(data, dict) and int(data.get("CODE") or 0) >= 400:
            return False
        resp = data.get("RESPONSE") if isinstance(data, dict) else data
        return resp in (True, "ok", "OK") or (isinstance(resp, dict) and bool(resp))

    def contacts_by_phone(self, phone: str) -> list[dict[str, Any]]:
        data = self.call(
            "contacts/get_from_filter",
            {"FILTER": {"MAIN_PHONE": phone}, "PAGE": 1, "LIMIT": 20},
        )
        return _as_list(data)

    def cars_by_contact(self, contact_id: int) -> list[dict[str, Any]]:
        data = self.call(
            "car_profile/get_filtered_profiles",
            {"FILTER": {"CONTACT_ID": contact_id}, "PAGE": 1, "LIMIT": 50},
        )
        return _as_list(data)

    def offers_by_contact(
        self,
        contact_id: int,
        *,
        board_id: int | None = None,
        all_boards: bool = False,
        pages: int = 1,
    ) -> list[dict[str, Any]]:
        filt: dict[str, Any] = {"CONTACT_ID": int(contact_id)}
        if not all_boards:
            filt["BOARD_ID"] = board_id or settings.stocrm_board_id or 1097
        out: list[dict[str, Any]] = []
        max_pages = max(int(pages or 1), 1)
        for page in range(1, max_pages + 1):
            data = self.call(
                "offers/get_from_filter",
                {"FILTER": filt, "PAGE": page, "LIMIT": 50},
            )
            rows = _as_list(data)
            out.extend(rows)
            total = _total_count(data)
            if not rows or len(rows) < 50:
                break
            if total and len(out) >= total:
                break
        return out

    def customers(self) -> list[dict[str, Any]]:
        data = self.call("customers/get_filtered", {"FILTER": {}, "PAGE": 1, "LIMIT": 50})
        return _as_list(data)

    def offer_new(
        self,
        contact_id: int,
        comment: str,
        car_id: int | None = None,
        board_id: int | None = None,
        customer_id: int | None = None,
    ) -> Any:
        payload: dict[str, Any] = {
            "CONTACT_ID": contact_id,
            "BOARD_ID": board_id or settings.stocrm_board_id or 1097,
            "COMMENT": comment,
        }
        if car_id:
            payload["CAR_PROFILE_ID"] = car_id
        if customer_id:
            payload["CUSTOMER_ID"] = customer_id
        if settings.stocrm_source_id is not None:
            payload["SOURCE_ID"] = settings.stocrm_source_id
        try:
            return self.call("offer/new", payload)
        except StoCrmError:
            if not customer_id:
                raise
            payload.pop("CUSTOMER_ID", None)
            return self.call("offer/new", payload)

    def offer_statuses(self, board_id: int | None = None) -> list[dict[str, Any]]:
        if self._statuses is None:
            data = self.call("offer/all_statuses", {"BOARD_ID": board_id or settings.stocrm_board_id or 1097})
            self._statuses = _as_list(data)
        return self._statuses

    def calendar_cards(self, customer_id: int, date_ts: int) -> list[dict[str, Any]]:
        data = self.call("calendar/card/get", {"CUSTOMER_ID": customer_id, "DATE": date_ts})
        return _as_list(data)

    def calendar_posts(self, customer_id: int) -> list[dict[str, Any]]:
        data = self.call(
            "calendar/post/get_filtered",
            {"FILTER": {"CUSTOMER_ID": customer_id}, "PAGE": 1, "LIMIT": 50},
        )
        return _as_list(data)

    def works_index(self, offer_ids: list[int] | None = None) -> dict[int, list[str]]:
        rows: list[dict[str, Any]] = []
        try:
            rows = _as_list(self.call("work/get_filtered", {"FILTER": {}, "PAGE": 1, "LIMIT": 80}))
        except StoCrmError:
            rows = []
        wanted = {int(x) for x in (offer_ids or []) if x}
        out: dict[int, list[str]] = {}
        for w in rows:
            oid = int(w.get("OFFER_ID") or 0)
            if not oid:
                continue
            if wanted and oid not in wanted:
                continue
            desc = str(
                w.get("DESCRIPTION") or w.get("TITLE") or w.get("NAME") or w.get("WORK_NAME") or ""
            ).strip()
            if desc:
                out.setdefault(oid, []).append(desc[:160])
        missing = [oid for oid in wanted if oid not in out][:8]
        for oid in missing:
            try:
                extra = _as_list(
                    self.call("work/get_filtered", {"FILTER": {"OFFER_ID": oid}, "PAGE": 1, "LIMIT": 20})
                )
            except StoCrmError:
                continue
            for w in extra:
                desc = str(
                    w.get("DESCRIPTION") or w.get("TITLE") or w.get("NAME") or w.get("WORK_NAME") or ""
                ).strip()
                if desc:
                    out.setdefault(oid, []).append(desc[:160])
        return out


def _is_rate_limited(data: Any) -> bool:
    if not isinstance(data, dict):
        return False
    msg = str(data.get("MESSAGE") or data.get("RESPONSE") or "")
    code = data.get("CODE")
    return "частые запросы" in msg.lower() or code == 500123456789


def _as_id(data: Any) -> int | None:
    if isinstance(data, int):
        return data if data else None
    if isinstance(data, str) and data.isdigit():
        return int(data)
    if isinstance(data, dict):
        resp = data.get("RESPONSE", data)
        if isinstance(resp, int):
            return resp if resp else None
        if isinstance(resp, str) and str(resp).isdigit():
            return int(resp)
        if isinstance(resp, dict):
            for key in ("CONTACT_ID", "CAR_PROFILE_ID", "ID", "id"):
                v = resp.get(key)
                if v in (None, False, "", 0, "0"):
                    continue
                try:
                    return int(v)
                except (TypeError, ValueError):
                    continue
    return None


def _total_count(data: Any) -> int:
    if not isinstance(data, dict):
        return 0
    resp = data.get("RESPONSE")
    if isinstance(resp, dict):
        try:
            return int(resp.get("TOTAL_COUNT") or 0)
        except (TypeError, ValueError):
            return 0
    return 0


def _as_list(data: Any) -> list[dict[str, Any]]:
    if isinstance(data, list):
        return [x for x in data if isinstance(x, dict)]
    if isinstance(data, dict):
        resp = data.get("RESPONSE", data)
        if isinstance(resp, list):
            return [x for x in resp if isinstance(x, dict)]
        if isinstance(resp, dict):
            rows = resp.get("DATA")
            if isinstance(rows, list):
                return [x for x in rows if isinstance(x, dict)]
            if all(str(k).isdigit() for k in resp.keys()):
                return [v for v in resp.values() if isinstance(v, dict)]
            if "CODE" in resp and resp.get("CODE") not in (200, None, "200"):
                return []
            return [resp]
    return []


_REDACT = {
    "PASSWORD",
    "SID",
    "MAIN_PHONE",
    "PHONE",
    "PHONES",
    "EMAIL",
    "VIN",
    "CAR_PROFILE_VIN",
    "CONTACT_PROPERTY_PHONE",
    "OWNER_ADDRESS",
    "LICENSE_PLATE",
    "CAR_NUMBER_FLAT",
}


def _trim(obj: Any, depth: int = 0) -> Any:
    if depth > 2:
        return "…"
    if isinstance(obj, dict):
        out = {}
        for i, (k, v) in enumerate(obj.items()):
            if i >= 12:
                break
            if str(k).upper() in _REDACT:
                out[k] = "…"
            else:
                out[k] = _trim(v, depth + 1)
        return out
    if isinstance(obj, list):
        return [_trim(x, depth + 1) for x in obj[:2]]
    if isinstance(obj, str) and len(obj) > 120:
        return obj[:120] + "…"
    return obj


stocrm = StoCrm()
