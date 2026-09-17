from __future__ import annotations

import re
import secrets
from typing import Any

from contextlib import asynccontextmanager

from fastapi import FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from app.config import settings
from app.site import mount_site
from app.stocrm import StoCrmError, stocrm

@asynccontextmanager
async def lifespan(_: FastAPI):
    yield
    stocrm.close()


app = FastAPI(
    title="VAG Market BFF",
    version="0.2.0",
    lifespan=lifespan,
    docs_url="/internal/swagger" if settings.is_dev_secret else None,
    redoc_url=None,
    openapi_url="/internal/openapi.json" if settings.is_dev_secret else None,
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

otp_box: dict[str, str] = {}
sessions: dict[str, dict[str, Any]] = {}


def digits_phone(raw: str) -> str:
    d = re.sub(r"\D", "", raw)
    if d.startswith("8") and len(d) == 11:
        d = "7" + d[1:]
    if d.startswith("7") and len(d) == 11:
        return d
    if len(d) == 10:
        return "7" + d
    raise HTTPException(400, "Нужен номер РФ, 10 цифр после +7")


def require_user(authorization: str | None) -> dict[str, Any]:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "Нет сессии")
    token = authorization.split(" ", 1)[1].strip()
    user = sessions.get(token)
    if not user:
        raise HTTPException(401, "Сессия истекла")
    return user


def _car_out(c: dict[str, Any]) -> dict[str, Any]:
    title = c.get("TITLE") or " ".join(x for x in (c.get("BRAND_NAME"), c.get("MODEL_NAME")) if x).strip()
    return {
        "id": int(c.get("CAR_PROFILE_ID") or 0),
        "title": title,
        "brand": c.get("BRAND_NAME"),
        "model": c.get("MODEL_NAME"),
        "generation": c.get("GENERATION_NAME"),
        "year": c.get("YEAR"),
        "vin": c.get("VIN"),
        "plate": c.get("LICENSE_PLATE"),
        "mileage": c.get("MILEAGE"),
        "sold": c.get("SOLD"),
        "color": c.get("COLOR"),
    }


def _offer_out(o: dict[str, Any]) -> dict[str, Any]:
    return {
        "id": o.get("OFFER_ID"),
        "status": o.get("STATUS_NAME"),
        "status_id": o.get("OFFER_STATUS_ID"),
        "board": o.get("BOARD_NAME"),
        "sum": o.get("OFFER_SUM"),
        "works_sum": o.get("WORKS_SUM"),
        "car": o.get("CAR_TITLE"),
        "branch": o.get("OFFER_CUSTOMER_NAME"),
        "branch_id": o.get("CUSTOMER_ID"),
        "created": o.get("OFFER_DATE_CREATE_FRONTEND_TIMESTAMP"),
        "calendar_from": o.get("CALENDAR_RECORD_DATE_FROM"),
        "calendar_to": o.get("CALENDAR_RECORD_DATE_TO"),
    }


class PhoneIn(BaseModel):
    phone: str


class OtpIn(BaseModel):
    phone: str
    code: str


class BookingIn(BaseModel):
    car_id: int | None = None
    branch_id: str | None = None
    when: str | None = None
    comment: str = Field(default="Запись из приложения VAG Market")


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "stocrm_domain": settings.stocrm_domain,
        "sid_set": bool(settings.stocrm_sid),
        "board_id": settings.stocrm_board_id,
    }


@app.get("/internal/stocrm/probe")
def probe(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    """Карта методов на боевом SID. Снаружи только с заголовком X-BFF-Secret."""
    if not settings.is_dev_secret and x_bff_secret != settings.bff_secret:
        raise HTTPException(404, "Not found")
    checks = [
        ("contacts/get_from_filter", {"FILTER": {}, "PAGE": 1, "LIMIT": 3}),
        ("car_profile/get_filtered_profiles", {"FILTER": {}, "PAGE": 1, "LIMIT": 3}),
        ("offers/get_from_filter", {"FILTER": {"BOARD_ID": settings.stocrm_board_id or 1097}, "PAGE": 1, "LIMIT": 2}),
        ("offer/all_statuses", {"BOARD_ID": settings.stocrm_board_id or 1097}),
        ("work/get_filtered", {"FILTER": {}, "PAGE": 1, "LIMIT": 3}),
        ("calendar/post/get_filtered", {"FILTER": {}, "PAGE": 1, "LIMIT": 3}),
        ("shift/get_filtered", {"FILTER": {}, "PAGE": 1, "LIMIT": 3}),
        ("customers/get_filtered", {"FILTER": {}, "PAGE": 1, "LIMIT": 20}),
        ("legal_entities/get_from_filter", {"FILTER": {"IS_OUR": "Y"}, "PAGE": 1, "LIMIT": 10}),
        ("contact/new", None),
    ]
    results = []
    for path, payload in checks:
        if payload is None:
            results.append({"ok": False, "path": path, "skipped": "мутирующий метод, не дергаем в probe"})
            continue
        results.append(stocrm.probe(path, payload))
    return {"base": settings.base_url, "results": results}


@app.post("/v1/auth/otp/request")
def otp_request(body: PhoneIn) -> dict[str, str]:
    phone = digits_phone(body.phone)
    otp_box[phone] = settings.dev_otp_code
    return {"status": "sent", "hint": "прототип: код 1234"}


@app.post("/v1/auth/otp/confirm")
def otp_confirm(body: OtpIn) -> dict[str, Any]:
    phone = digits_phone(body.phone)
    if otp_box.get(phone) != body.code.strip():
        raise HTTPException(400, "Неверный код")
    contacts = []
    crm_error = None
    try:
        variants = [phone, phone[1:], f"+{phone}"]
        seen: set[int] = set()
        for v in variants:
            for c in stocrm.contacts_by_phone(v):
                cid = int(c.get("CONTACT_ID") or c.get("ID") or 0)
                if cid and cid not in seen:
                    seen.add(cid)
                    contacts.append(c)
    except Exception as e:
        crm_error = str(e)
    contact = contacts[0] if contacts else None
    token = secrets.token_urlsafe(24)
    sessions[token] = {
        "phone": phone,
        "contact_id": int(contact.get("CONTACT_ID") or contact.get("ID") or 0) if contact else None,
        "name": (contact or {}).get("TITLE") or (contact or {}).get("FIRSTNAME") or "Клиент",
        "contact": contact,
    }
    return {
        "token": token,
        "phone": phone,
        "contact_id": sessions[token]["contact_id"],
        "name": sessions[token]["name"],
        "found_in_crm": contact is not None,
        "crm_error": crm_error,
    }


@app.get("/v1/me")
def me(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    return {
        "phone": user.get("phone"),
        "contact_id": user.get("contact_id"),
        "name": user.get("name"),
    }


@app.get("/v1/garage")
def garage(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        return {"cars": [], "reason": "контакт не найден в STOCRM по телефону"}
    cars = stocrm.cars_by_contact(int(cid))
    return {"cars": [_car_out(c) for c in cars]}


@app.get("/v1/visits")
def visits(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        return {"offers": []}
    return {"offers": [_offer_out(o) for o in stocrm.offers_by_contact(int(cid))]}


@app.get("/v1/branches")
def branches() -> dict[str, Any]:
    rows = []
    for c in stocrm.customers():
        if str(c.get("ACTIVE") or "Y").upper() in ("N", "0", "FALSE"):
            continue
        rows.append(
            {
                "id": c.get("CUSTOMER_ID"),
                "name": c.get("CUSTOMER_NAME"),
                "address": c.get("ADDRESS") or "",
                "phone": _phone_out(c.get("PHONES")),
                "site": c.get("SITE"),
                "city": c.get("CITY_NAME") or "",
                "work_time": _work_time_out(c.get("WORK_TIME_STRING") or c.get("WORK_TIME")),
            }
        )
    return {"branches": rows}


@app.post("/v1/bookings")
def bookings(body: BookingIn, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        raise HTTPException(409, "Клиент не найден в STOCRM. Сначала заведите контакт с этим телефоном в CRM.")
    comment = body.comment.strip() or "Запись из приложения VAG Market"
    if body.when:
        comment = f"{comment}\nСлот: {body.when}"
    if body.branch_id:
        comment = f"{comment}\nФилиал: {body.branch_id}"
    try:
        created = stocrm.offer_new(
            int(cid),
            comment=comment,
            car_id=body.car_id if body.car_id else None,
            customer_id=int(body.branch_id) if body.branch_id and str(body.branch_id).isdigit() else None,
        )
    except StoCrmError as e:
        raise HTTPException(502, f"STOCRM не принял заявку: {str(e)[:300]}") from e
    offer_id = _offer_id(created)
    return {
        "ok": True,
        "message": "Вы записаны, ожидайте подтверждения звонка или сообщения",
        "offer_id": offer_id,
    }


def _offer_id(data: Any) -> int | None:
    if isinstance(data, int):
        return data
    if isinstance(data, str) and data.isdigit():
        return int(data)
    if isinstance(data, dict):
        resp = data.get("RESPONSE", data)
        if isinstance(resp, int):
            return resp
        if isinstance(resp, str) and resp.isdigit():
            return int(resp)
        if isinstance(resp, dict):
            raw = resp.get("OFFER_ID") or resp.get("ID")
            if raw is not None and str(raw).isdigit():
                return int(raw)
    return None


def _phone_out(raw: Any) -> str:
    if raw is None or raw is False:
        return ""
    if isinstance(raw, str):
        return raw
    if isinstance(raw, dict):
        return _phone_out(list(raw.values()))
    if isinstance(raw, list):
        parts: list[str] = []
        for x in raw:
            if isinstance(x, dict):
                parts.append(str(x.get("VALUE") or x.get("PHONE") or x.get("NUMBER") or x.get("phone") or ""))
            else:
                parts.append(str(x))
        return ", ".join(p for p in parts if p and p not in ("False", "None"))
    return str(raw)


def _work_time_out(raw: Any) -> str:
    if raw is None or raw is False:
        return ""
    if isinstance(raw, str):
        return raw
    if isinstance(raw, dict):
        return str(raw.get("TEXT") or raw.get("TITLE") or "")
    return str(raw)


if settings.serve_site:
    mount_site(app)

