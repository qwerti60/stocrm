from __future__ import annotations

from typing import Any

import httpx

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

    def close(self) -> None:
        self._client.close()

    def call(self, path: str, payload: dict[str, Any] | None = None, method: str = "POST") -> Any:
        if not settings.stocrm_sid:
            raise StoCrmError(path, 0, "STOCRM_SID пустой — пропишите server/.env")
        body = {"SID": settings.stocrm_sid, **(payload or {})}
        url = f"{settings.base_url}/{path.lstrip('/')}"
        if method == "GET":
            r = self._client.get(url, params=body)
        else:
            r = self._client.post(url, json=body)
        try:
            data = r.json()
        except Exception:
            data = r.text
        if r.status_code >= 400:
            raise StoCrmError(path, r.status_code, data)
        if isinstance(data, dict):
            if data.get("IS_AUTHORIZE") is False:
                raise StoCrmError(path, r.status_code, data)
            code = data.get("CODE")
            msg = str(data.get("MESSAGE") or "")
            if data.get("RESPONSE") is False and "не найден" in msg.lower():
                return {"RESPONSE": {"DATA": [], "TOTAL_COUNT": 0}, "CODE": 200}
            if code == 666 or (isinstance(code, int) and code >= 400):
                raise StoCrmError(path, r.status_code, data)
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

    def offers_by_contact(self, contact_id: int) -> list[dict[str, Any]]:
        data = self.call(
            "offers/get_from_filter",
            {
                "FILTER": {"CONTACT_ID": contact_id, "BOARD_ID": settings.stocrm_board_id or 1097},
                "PAGE": 1,
                "LIMIT": 50,
            },
        )
        return _as_list(data)

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

    def offer_statuses(self, board_id: int) -> Any:
        return self.call("offer/all_statuses", {"BOARD_ID": board_id})

    def calendar_day(self, customer_id: int, date_ts: int) -> Any:
        return self.call("calendar/card/get", {"CUSTOMER_ID": customer_id, "DATE": date_ts})


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
