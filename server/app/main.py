from __future__ import annotations

import asyncio
import re
import secrets
from datetime import date, datetime
from pathlib import Path
from typing import Any
from urllib.parse import quote

from contextlib import asynccontextmanager

from fastapi import FastAPI, File, Form, Header, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, Response
from pydantic import BaseModel, Field

from app.config import persist_smtp, settings
from app.mail import mask_email, send_otp_email, send_test_email, smtp_public, smtp_ready, valid_email
from app.notify import add_note, known_contact_ids, list_notes, mark_read, poll_once, register_device
from app.site import mount_site
from app.slots import MSK, build_slots, day_bounds, unix
from app.pdf_zn import work_order_pdf
from app.store import (
    add_booking_ticket,
    add_campaign,
    add_message,
    add_short,
    add_vin,
    all_sessions,
    audience_by_phone,
    delete_short,
    bonus_statement,
    drop_session,
    get_identity,
    get_session,
    hidden_car_ids,
    hide_car,
    drop_garage_car,
    identity_by_email,
    is_bonus_offer,
    list_audience,
    list_campaigns,
    list_garage_local,
    list_messages,
    list_promos,
    list_shorts,
    list_shorts_admin,
    list_threads,
    list_tickets,
    list_vin,
    mark_campaign_sent,
    parse_phones,
    phones_from_table,
    promo_image_path,
    put_session,
    save_garage_car,
    save_promo_image,
    sync_bonuses,
    take_expiry_warnings,
    thread_key,
    touch_audience,
    update_short,
    upsert_identity,
)
from app.stocrm import StoCrmError, stocrm


def _week_poll(cids: list[int]) -> None:
    poll_once(stocrm, cids)
    for cid in cids:
        try:
            offers = stocrm.offers_by_contact(cid, all_boards=True, pages=20)
            sync_bonuses(cid, offers)
            for ev in take_expiry_warnings(cid):
                add_note(
                    cid,
                    "Бонусы скоро сгорят",
                    f"{ev.get('delta')} ₽ сгорят в течение {settings.bonus_warn_days} дн.",
                    ev.get("offer_id"),
                    kind="bonus",
                )
        except Exception:
            continue


async def _poll_loop() -> None:
    await asyncio.sleep(20)
    interval = max(int(settings.poll_interval_sec or 90), 30)
    while True:
        try:
            live = {**all_sessions(), **sessions}
            cids = [int(u["contact_id"]) for u in live.values() if u.get("contact_id")]
            await asyncio.to_thread(_week_poll, cids)
        except asyncio.CancelledError:
            raise
        except Exception:
            pass
        await asyncio.sleep(interval)


@asynccontextmanager
async def lifespan(_: FastAPI):
    task = asyncio.create_task(_poll_loop())
    try:
        yield
    finally:
        task.cancel()
        try:
            await task
        except asyncio.CancelledError:
            pass
        stocrm.close()


app = FastAPI(
    title="VAG Market BFF",
    version="0.4.0",
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

otp_box: dict[str, dict[str, Any]] = {}
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
    user = sessions.get(token) or get_session(token)
    if not user:
        raise HTTPException(401, "Сессия истекла")
    sessions[token] = user
    return user


def require_admin(x_bff_secret: str | None) -> None:
    key = settings.admin_key
    if settings.is_dev_secret and not (x_bff_secret or "").strip():
        return
    if not key or x_bff_secret != key:
        raise HTTPException(401, "Нет доступа в админку")


def _user_key(user: dict[str, Any]) -> str:
    return thread_key(user.get("contact_id"), user.get("phone"))


def _car_out(c: dict[str, Any]) -> dict[str, Any]:
    title = c.get("TITLE") or " ".join(x for x in (c.get("BRAND_NAME"), c.get("MODEL_NAME")) if x).strip()
    brand = c.get("BRAND_NAME")
    model = c.get("MODEL_NAME")
    if not brand and title:
        parts = str(title).split(" ", 1)
        brand = parts[0]
        model = parts[1] if len(parts) > 1 else model
    return {
        "id": int(c.get("CAR_PROFILE_ID") or 0),
        "title": title or "Авто",
        "brand": brand or None,
        "model": model or title or "авто",
        "generation": c.get("GENERATION_NAME"),
        "year": c.get("YEAR"),
        "vin": c.get("VIN") or None,
        "plate": c.get("LICENSE_PLATE") or "",
        "mileage": c.get("MILEAGE"),
        "sold": c.get("SOLD"),
        "color": c.get("COLOR"),
    }


def _car_visible(c: dict[str, Any], hidden: set[int]) -> bool:
    cid = int(c.get("CAR_PROFILE_ID") or 0)
    if not cid or cid in hidden:
        return False
    if str(c.get("SOLD") or "N").upper() in ("Y", "1", "TRUE"):
        return False
    plate = str(c.get("LICENSE_PLATE") or "").strip()
    vin = str(c.get("VIN") or "").strip()
    if not plate and not vin:
        return False
    return True


def _offer_out(o: dict[str, Any], works: list[str] | None = None) -> dict[str, Any]:
    status_id = int(o.get("OFFER_STATUS_ID") or 0)
    title = str(o.get("STATUS_NAME") or "")
    stage = _stage(status_id, title)
    is_final = _is_final(status_id, title)
    is_ready = stage == "ready" or status_id in (6, 17953, 6845)
    is_history = stage in ("closed", "done") or (stage == "ready" and status_id != 17953)
    successful = is_bonus_offer(status_id, title)
    return {
        "id": o.get("OFFER_ID"),
        "status": title,
        "status_id": status_id or None,
        "stage": stage,
        "is_final": is_final,
        "is_ready": is_ready,
        "is_history": is_history,
        "successful": successful,
        "board": o.get("BOARD_NAME"),
        "sum": o.get("OFFER_SUM"),
        "works_sum": o.get("WORKS_SUM"),
        "car": o.get("CAR_TITLE"),
        "branch": o.get("OFFER_CUSTOMER_NAME"),
        "branch_id": o.get("CUSTOMER_ID"),
        "created": o.get("OFFER_DATE_CREATE_FRONTEND_TIMESTAMP"),
        "calendar_from": o.get("CALENDAR_RECORD_DATE_FROM"),
        "calendar_to": o.get("CALENDAR_RECORD_DATE_TO"),
        "works": works or [],
        "steps": _funnel_steps(status_id, title),
    }


def _stage(status_id: int, title: str) -> str:
    t = (title or "").lower()
    if status_id in (4, 5, 5648) or any(x in t for x in ("отказ", "мусор", "не приехал")):
        return "closed"
    if status_id == 6 or "успешн" in t or status_id == 17953 or "готов" in t:
        return "ready"
    if status_id == 6845 or "выполнен" in t:
        return "done"
    if status_id in (2, 6844) or "работ" in t:
        return "work"
    if status_id in (5628,) or "записан" in t:
        return "booked"
    return "inbox"


def _is_final(status_id: int, title: str) -> bool:
    t = (title or "").lower()
    if status_id in (4, 5, 6, 5648):
        return True
    try:
        for row in stocrm.offer_statuses():
            sid = int(row.get("OFFER_STATUS_ID") or row.get("STATUS_ID") or row.get("ID") or 0)
            if sid == status_id:
                return str(row.get("IS_FINAL") or "").upper() == "Y"
    except Exception:
        pass
    return any(x in t for x in ("успешн", "отказ", "мусор"))


def _funnel_steps(status_id: int, title: str) -> list[dict[str, Any]]:
    t = (title or "").lower()
    ready = status_id in (6, 17953) or "готов" in t or "успешн" in t
    done = ready or status_id == 6845 or "выполнен" in t
    work = done or status_id in (2, 6844) or "работ" in t or "ожидан" in t
    booked = work or status_id in (5628, 17953) or "записан" in t
    if status_id in (4, 5, 5648) or any(x in t for x in ("отказ", "мусор", "не приехал")):
        return [
            {"title": "Заявка принята", "done": True},
            {"title": title or "Закрыто", "done": True, "detail": "сделка закрыта"},
        ]
    return [
        {"title": "Заявка принята", "done": True},
        {"title": "Записан в сервис", "done": booked},
        {"title": "В работе", "done": work},
        {"title": "Выполнен", "done": done},
        {
            "title": "Машина готова",
            "done": ready,
            "detail": "«Ваша машина готова!»" if ready else "Push при смене статуса в CRM",
        },
    ]


class PhoneIn(BaseModel):
    phone: str
    email: str | None = None


class OtpIn(BaseModel):
    phone: str
    code: str
    email: str | None = None


class GarageIn(BaseModel):
    plate: str
    make: str = ""
    model: str = ""
    year: int | None = None
    vin: str | None = None
    mileage: int | None = None


class BookingIn(BaseModel):
    car_id: int | None = None
    branch_id: str | None = None
    when: str | None = None
    comment: str = Field(default="Запись из приложения VAG Market")


class DeviceIn(BaseModel):
    fcm_token: str = ""


class ChatIn(BaseModel):
    text: str


class VinIn(BaseModel):
    vin: str
    part: str


class StaffReplyIn(BaseModel):
    text: str
    staff_name: str = "Егор"


class CampaignIn(BaseModel):
    title: str
    body: str
    badge: str = "Акция"
    segment: str = "all"
    branch_id: str = ""
    pin: bool = False
    kind: str = "push"
    phones: list[str] = []


class ShortIn(BaseModel):
    title: str
    subtitle: str = ""
    url: str = ""
    poster: str = ""


class SmtpIn(BaseModel):
    host: str = ""
    port: int = 465
    user: str = ""
    password: str = ""
    from_addr: str = ""
    tls: bool = True
    ssl: bool | None = None


class SmtpTestIn(BaseModel):
    to: str = ""


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "ok": True,
        "stocrm_domain": settings.stocrm_domain,
        "sid_set": bool(settings.stocrm_sid),
        "board_id": settings.stocrm_board_id,
        "week": 4,
        "email_otp": True,
        "smtp": smtp_ready(),
        "fcm": settings.fcm_enabled,
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
        ("calendar/card/get", {"CUSTOMER_ID": 2113, "DATE": unix(datetime.now(MSK).replace(hour=0, minute=0, second=0, microsecond=0))}),
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


def _lookup_contact(phone: str) -> tuple[dict[str, Any] | None, str | None, str | None]:
    """Контакт CRM, email из свойства PROP_TYPE_ID=2, иначе связка phone↔email в JSON."""
    contact = None
    crm_error = None
    try:
        contact = stocrm.find_contact(phone)
    except Exception as e:
        crm_error = str(e)[:300]
    email = None
    cid = int((contact or {}).get("CONTACT_ID") or (contact or {}).get("ID") or 0) if contact else 0
    if cid:
        try:
            email = stocrm.contact_email(cid)
        except Exception as e:
            crm_error = crm_error or str(e)[:300]
    ident = get_identity(phone)
    if not email and ident:
        email = str(ident.get("email") or "").strip().lower() or None
        if not cid:
            try:
                cid = int(ident.get("contact_id") or 0)
            except (TypeError, ValueError):
                cid = 0
            if cid and not contact:
                contact = {"CONTACT_ID": cid, "TITLE": ident.get("name") or phone}
    return contact, email, crm_error


def _issue_otp(phone: str, email: str, contact: dict[str, Any] | None, *, is_new: bool) -> dict[str, Any]:
    code = settings.dev_otp_code
    mailed = False
    if smtp_ready():
        code = f"{secrets.randbelow(10000):04d}"
        mailed = send_otp_email(email, code)
        if not mailed:
            raise HTTPException(503, "Не удалось отправить письмо. Попробуйте позже.")
    otp_box[phone] = {
        "code": code,
        "email": email,
        "contact_id": int((contact or {}).get("CONTACT_ID") or (contact or {}).get("ID") or 0) or None,
        "is_new": is_new,
        "created": int(datetime.now().timestamp()),
    }
    hint = None if mailed else "SMTP не задан — код 1234. Письмо уйдёт, когда пропишете SMTP_* в .env"
    return {
        "status": "sent",
        "channel": "email",
        "email_masked": mask_email(email),
        "found_in_crm": contact is not None,
        "is_new": is_new,
        **({"hint": hint} if hint else {}),
    }


@app.post("/v1/auth/lookup")
def auth_lookup(body: PhoneIn) -> dict[str, Any]:
    phone = digits_phone(body.phone)
    contact, email, crm_error = _lookup_contact(phone)
    return {
        "phone": phone,
        "found_in_crm": contact is not None,
        "has_email": bool(email),
        "need_email": not bool(email),
        "email_masked": mask_email(email or ""),
        "is_new": contact is None,
        "crm_error": crm_error,
    }


@app.post("/v1/auth/otp/request")
def otp_request(body: PhoneIn) -> dict[str, Any]:
    phone = digits_phone(body.phone)
    contact, crm_email, crm_error = _lookup_contact(phone)
    supplied = (body.email or "").strip()
    email = crm_email
    if not email:
        if not supplied:
            raise HTTPException(
                409,
                "В карточке STOCRM нет email. Укажите почту — код придёт туда, телефон останется ключом входа.",
            )
        try:
            email = valid_email(supplied)
        except ValueError as e:
            raise HTTPException(400, str(e)) from e
        other = identity_by_email(email)
        if other and other.get("phone") and other.get("phone") != phone:
            raise HTTPException(409, "Этот email уже привязан к другому номеру")
        upsert_identity(phone, email=email, contact_id=(contact or {}).get("CONTACT_ID"))
    try:
        return _issue_otp(phone, email, contact, is_new=contact is None)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(502, crm_error or str(e)[:200]) from e


@app.post("/v1/auth/otp/confirm")
def otp_confirm(body: OtpIn) -> dict[str, Any]:
    phone = digits_phone(body.phone)
    pending = otp_box.get(phone)
    got = (pending or {}).get("code") if isinstance(pending, dict) else pending
    if got != body.code.strip():
        raise HTTPException(400, "Неверный код")
    contact, crm_email, crm_error = _lookup_contact(phone)
    email = (pending or {}).get("email") if isinstance(pending, dict) else None
    if body.email:
        try:
            email = valid_email(body.email)
        except ValueError:
            email = email or crm_email
    email = (email or crm_email or "").strip().lower() or None
    cid = int((contact or {}).get("CONTACT_ID") or (contact or {}).get("ID") or 0) if contact else 0
    created = False
    if not cid and email:
        try:
            cid = stocrm.contact_create(phone, email, firstname="")
            created = True
            contact = {"CONTACT_ID": cid, "TITLE": phone}
        except Exception as e:
            crm_error = str(e)[:300]
    if cid and email and email != (crm_email or ""):
        try:
            stocrm.contact_set_email(cid, email)
            crm_email = email
        except Exception as e:
            crm_error = crm_error or str(e)[:300]
    if cid and email:
        upsert_identity(phone, email=email, contact_id=cid)
    elif email:
        upsert_identity(phone, email=email, contact_id=cid)
    token = secrets.token_urlsafe(24)
    name = (contact or {}).get("TITLE") or (contact or {}).get("FIRSTNAME") or "Клиент"
    sessions[token] = {
        "phone": phone,
        "email": email or crm_email,
        "contact_id": cid or None,
        "name": name,
        "contact": contact,
    }
    put_session(token, sessions[token])
    if cid:
        touch_audience(cid, phone=phone, name=str(name or ""))
    otp_box.pop(phone, None)
    return {
        "token": token,
        "phone": phone,
        "email": email or crm_email,
        "contact_id": cid or None,
        "name": name,
        "found_in_crm": bool(cid),
        "created_in_crm": created,
        "crm_error": crm_error,
    }


@app.get("/v1/me")
def me(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    return {
        "phone": user.get("phone"),
        "email": user.get("email"),
        "contact_id": user.get("contact_id"),
        "name": user.get("name"),
    }


def _garage_merged(cid: int) -> list[dict[str, Any]]:
    hidden = hidden_car_ids(cid)
    try:
        crm_cars = [_car_out(c) for c in stocrm.cars_by_contact(int(cid)) if _car_visible(c, hidden)]
    except StoCrmError:
        crm_cars = []
    local = list_garage_local(cid)
    by_id = {int(c["id"]): c for c in crm_cars if c.get("id")}
    for row in local:
        try:
            kid = int(row.get("id") or 0)
        except (TypeError, ValueError):
            continue
        if not kid or kid in hidden:
            continue
        if kid in by_id:
            cur = by_id[kid]
            if not cur.get("plate") and row.get("plate"):
                cur["plate"] = row["plate"]
            if not cur.get("vin") and row.get("vin"):
                cur["vin"] = row["vin"]
            if row.get("brand"):
                cur["brand"] = row.get("brand") or cur.get("brand")
            if row.get("model"):
                cur["model"] = row.get("model") or cur.get("model")
            if row.get("title"):
                cur["title"] = row.get("title") or cur.get("title")
        else:
            by_id[kid] = {
                "id": kid,
                "title": row.get("title") or row.get("plate") or "Авто",
                "brand": row.get("brand") or row.get("make"),
                "model": row.get("model") or "авто",
                "year": row.get("year"),
                "vin": row.get("vin"),
                "plate": row.get("plate") or "",
                "mileage": row.get("mileage"),
                "sold": "N",
                "source": "app",
            }
    return list(by_id.values())


@app.get("/v1/garage")
def garage(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        return {"cars": [], "reason": "контакт не найден в STOCRM по телефону"}
    return {"cars": _garage_merged(int(cid))}


@app.post("/v1/garage")
def garage_add(body: GarageIn, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        raise HTTPException(409, "Сначала войдите — без контакта в STOCRM машину некуда привязать")
    plate = (body.plate or "").strip().upper()
    if not plate:
        raise HTTPException(400, "Нужен госномер")
    title = " ".join(x for x in (body.make.strip(), body.model.strip()) if x) or plate
    try:
        car_id = stocrm.car_add(
            int(cid),
            title=title,
            plate=plate,
            vin=(body.vin or "").strip(),
            year=body.year,
            mileage=body.mileage,
        )
    except StoCrmError as e:
        msg = str(e.body) if getattr(e, "body", None) else str(e)
        if isinstance(e.body, dict):
            msg = str(e.body.get("MESSAGE") or e.body)[:300]
        raise HTTPException(502, f"STOCRM не принял авто: {msg}") from e
    save_garage_car(
        cid,
        {
            "id": car_id,
            "title": title,
            "brand": body.make.strip() or None,
            "make": body.make.strip(),
            "model": body.model.strip() or "авто",
            "plate": plate,
            "vin": (body.vin or "").strip().upper() or None,
            "year": body.year,
            "mileage": body.mileage,
        },
    )
    return {"ok": True, "id": car_id, "cars": _garage_merged(int(cid))}


@app.delete("/v1/garage/{car_id}")
def garage_delete(car_id: int, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        raise HTTPException(409, "Нет контакта в STOCRM")
    sold = False
    try:
        sold = stocrm.car_mark_sold(int(car_id))
    except Exception:
        sold = False
    hide_car(cid, car_id)
    drop_garage_car(cid, car_id)
    return {"ok": True, "sold_in_crm": sold, "cars": _garage_merged(int(cid))}


@app.get("/v1/visits")
def visits(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        return {"offers": []}
    offers = stocrm.offers_by_contact(int(cid), all_boards=True, pages=20)
    works = stocrm.works_index([int(o.get("OFFER_ID") or 0) for o in offers if o.get("OFFER_ID")])
    return {"offers": [_offer_out(o, works.get(int(o.get("OFFER_ID") or 0), [])) for o in offers]}


@app.get("/v1/slots")
def slots(
    branch_id: str = Query(..., description="CUSTOMER_ID филиала"),
    day: str = Query(..., alias="date", description="YYYY-MM-DD, Europe/Moscow"),
) -> dict[str, Any]:
    if not branch_id.isdigit():
        raise HTTPException(400, "branch_id — числовой CUSTOMER_ID филиала")
    try:
        parsed = date.fromisoformat(day)
    except ValueError:
        raise HTTPException(400, "date в формате YYYY-MM-DD")
    customer_id = int(branch_id)
    midnight = datetime.combine(parsed, datetime.min.time(), tzinfo=MSK)
    try:
        cards = stocrm.calendar_cards(customer_id, unix(midnight))
        posts = stocrm.calendar_posts(customer_id)
        posts = [p for p in posts if str(p.get("CUSTOMER_ID") or customer_id) == str(customer_id)]
    except StoCrmError as e:
        raise HTTPException(502, f"Календарь STOCRM: {str(e)[:300]}") from e
    post_ids = [p.get("POST_ID") or p.get("ID") for p in posts]
    built = build_slots(day=parsed, cards=cards, post_ids=post_ids)
    start, end = day_bounds(parsed)
    return {
        "branch_id": customer_id,
        "date": parsed.isoformat(),
        "hours": f"{start.strftime('%H:%M')}–{end.strftime('%H:%M')}",
        "posts": len({p for p in post_ids if p not in (None, "", 0, "0")}),
        "busy_cards": len(cards),
        "slots": built,
        "note": "Свободно, если занятых постов меньше ёмкости. Заявка не бронирует пост до подтверждения приёмкой.",
    }


@app.get("/v1/branches")
def branches() -> dict[str, Any]:
    customers = stocrm.customers()
    rows = []
    for c in customers:
        if str(c.get("ACTIVE") or "Y").upper() in ("N", "0", "FALSE"):
            continue
        rows.append(_branch_out(c, customers))
    return {"branches": _public_branches(rows)}


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
    add_booking_ticket(
        _user_key(user),
        branch=str(body.branch_id or ""),
        branch_id=str(body.branch_id or ""),
        when=str(body.when or ""),
        comment=comment,
        car=str(body.car_id or ""),
        phone=str(user.get("phone") or ""),
        name=str(user.get("name") or ""),
        offer_id=offer_id,
    )
    return {
        "ok": True,
        "message": "Заявка на ремонт принята. В течении 15 минут мы Вам позвоним для подтверждения",
        "offer_id": offer_id,
    }


@app.post("/v1/devices")
def devices(body: DeviceIn, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        raise HTTPException(409, "Нет контакта в CRM")
    if body.fcm_token.strip():
        register_device(int(cid), body.fcm_token.strip())
    return {"ok": True, "fcm": settings.fcm_enabled}


@app.get("/v1/notifications")
def notifications(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        return {"items": []}
    return {"items": list_notes(int(cid)), "fcm": settings.fcm_enabled}


@app.post("/v1/notifications/{note_id}/read")
def notification_read(note_id: str, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if cid:
        mark_read(int(cid), note_id)
    return {"ok": True}


@app.post("/v1/notifications/test")
def notification_test(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    """QA: имитация push «машина готова» без смены статуса в CRM."""
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        raise HTTPException(409, "Нет контакта в CRM")
    note = add_note(int(cid), "Ваша машина готова!", "Тест: заберите авто в сервисе.")
    return {"ok": True, "item": note}


@app.get("/v1/chat")
def chat_get(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    msgs = list_messages(_user_key(user))
    staff = next((m.get("staff_name") for m in reversed(msgs) if m.get("from_staff") and m.get("staff_name")), "Менеджер")
    return {"messages": msgs, "staff_name": staff or "Менеджер"}


@app.post("/v1/chat")
def chat_post(body: ChatIn, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    text = body.text.strip()
    if not text:
        raise HTTPException(400, "Пустое сообщение")
    msg = add_message(
        _user_key(user),
        text=text,
        from_staff=False,
        phone=str(user.get("phone") or ""),
        name=str(user.get("name") or ""),
    )
    return {"ok": True, "item": msg}


@app.post("/v1/vin")
def vin_post(body: VinIn, authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    vin = body.vin.strip()
    part = body.part.strip()
    if len(vin) < 11 or not part:
        raise HTTPException(400, "Нужны VIN и наименование запчасти")
    row = add_vin(
        _user_key(user),
        vin=vin,
        part=part,
        phone=str(user.get("phone") or ""),
        name=str(user.get("name") or ""),
    )
    return {"ok": True, "item": row, "message": "Заявка ушла менеджеру. Это не витрина склада."}


@app.get("/v1/tickets")
def tickets_get(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    items = list_tickets(_user_key(user))
    return {"items": items, "vin": sum(1 for x in items if x.get("kind") == "vin"), "book": sum(1 for x in items if x.get("kind") == "book")}


@app.get("/v1/bonuses")
def bonuses_get(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        return {"balance": 0, "events": [], "reason": "контакт не найден в CRM"}
    try:
        sync_bonuses(int(cid), stocrm.offers_by_contact(int(cid), all_boards=True, pages=20))
    except Exception:
        pass
    return bonus_statement(int(cid))


@app.get("/v1/recommendations")
def recommendations_get(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    user = require_user(authorization)
    cid = user.get("contact_id")
    items: list[dict[str, Any]] = []
    if cid:
        try:
            offers = stocrm.offers_by_contact(int(cid))
            works = stocrm.works_index([int(o.get("OFFER_ID") or 0) for o in offers if o.get("OFFER_ID")])
            for o in offers:
                mapped = _offer_out(o, works.get(int(o.get("OFFER_ID") or 0), []))
                if mapped.get("is_history"):
                    continue
                for w in mapped.get("works") or []:
                    items.append({
                        "title": w,
                        "subtitle": mapped.get("status") or "открытая заявка",
                        "offer_id": mapped.get("id"),
                        "car": mapped.get("car") or "",
                        "car_id": "",
                    })
            cars = stocrm.cars_by_contact(int(cid))
            for c in cars:
                km = c.get("MILEAGE")
                nxt = c.get("NEXT_SERVICE_KM") or c.get("TO_MILEAGE")
                mapped_car = _car_out(c)
                title = mapped_car.get("title") or "Авто"
                plate = mapped_car.get("plate") or ""
                if nxt and km:
                    left = int(nxt) - int(km)
                    items.append({
                        "title": f"ТО: {'пора записываться' if left <= 0 else f'через {left} км'}",
                        "subtitle": "пробег из карточки авто",
                        "car": title,
                        "plate": plate,
                        "car_id": str(mapped_car.get("id") or ""),
                    })
        except Exception:
            pass
    return {"items": items, "empty": not items}


@app.get("/v1/promos")
def promos_get() -> dict[str, Any]:
    items = []
    for c in list_promos():
        row = dict(c)
        pid = str(row.get("id") or "")
        if pid and promo_image_path(pid):
            row["image_url"] = f"/v1/promos/{pid}/image"
        items.append(row)
    return {"items": items}


@app.get("/v1/promos/{pid}/image")
def promo_image(pid: str):
    path = promo_image_path(pid)
    if not path:
        raise HTTPException(404, "Нет картинки")
    return FileResponse(path)


@app.get("/v1/visits/{oid}/pdf")
def visit_pdf(oid: int, authorization: str | None = Header(default=None)):
    user = require_user(authorization)
    cid = user.get("contact_id")
    if not cid:
        raise HTTPException(409, "Нет контакта")
    offers = stocrm.offers_by_contact(int(cid), all_boards=True, pages=20)
    found = next((o for o in offers if int(o.get("OFFER_ID") or 0) == int(oid)), None)
    if not found:
        raise HTTPException(404, "Заказ-наряд не найден")
    mapped = _offer_out(found)
    if not mapped.get("successful"):
        raise HTTPException(400, "PDF доступен только по успешно реализованным сделкам")
    works = stocrm.works_index([oid]).get(oid, [])
    when = mapped.get("calendar_from") or mapped.get("created") or ""
    pdf = work_order_pdf(
        {
            "id": oid,
            "when": when,
            "car": mapped.get("car") or "",
            "branch": mapped.get("branch") or "",
            "status": mapped.get("status") or "",
            "sum": mapped.get("sum") or mapped.get("works_sum") or "",
            "works": works,
            "parts": mapped.get("parts") or [],
        }
    )
    return Response(
        pdf,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="ZN-{oid}.pdf"'},
    )


@app.post("/v1/auth/logout")
def auth_logout(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    if authorization and authorization.lower().startswith("bearer "):
        token = authorization.split(" ", 1)[1].strip()
        sessions.pop(token, None)
        drop_session(token)
    return {"ok": True}


@app.get("/v1/shorts")
def shorts_get() -> dict[str, Any]:
    return {"items": list_shorts()}


@app.get("/v1/search")
def search_get(q: str = Query(""), authorization: str | None = Header(default=None)) -> dict[str, Any]:
    needle = (q or "").strip().lower()
    hits: list[dict[str, Any]] = []
    user = None
    if authorization:
        try:
            user = require_user(authorization)
        except HTTPException:
            user = None
    if not needle:
        return {"q": q, "items": []}
    cid = int(user["contact_id"]) if user and user.get("contact_id") else 0
    if cid:
        try:
            for c in stocrm.cars_by_contact(cid):
                mapped = _car_out(c)
                blob = " ".join(str(mapped.get(k) or "") for k in ("title", "brand", "model", "plate", "vin")).lower()
                if needle in blob:
                    hits.append({"kind": "car", "title": mapped.get("title") or "Авто", "subtitle": mapped.get("plate") or "", "screen": "garage"})
        except Exception:
            pass
        try:
            offers = stocrm.offers_by_contact(cid)
            works = stocrm.works_index([int(o.get("OFFER_ID") or 0) for o in offers if o.get("OFFER_ID")])
            for o in offers:
                mapped = _offer_out(o, works.get(int(o.get("OFFER_ID") or 0), []))
                blob = " ".join(
                    str(x)
                    for x in (
                        mapped.get("status"),
                        mapped.get("branch"),
                        mapped.get("car"),
                        " ".join(mapped.get("works") or []),
                    )
                    if x
                ).lower()
                if needle in blob:
                    hits.append(
                        {
                            "kind": "visit",
                            "title": mapped.get("status") or "Заявка",
                            "subtitle": mapped.get("branch") or "",
                            "screen": "visits",
                        }
                    )
        except Exception:
            pass
    try:
        for b in branches().get("branches") or []:
            blob = f"{b.get('name') or ''} {b.get('address') or ''} {b.get('city') or ''}".lower()
            if needle in blob:
                hits.append({"kind": "branch", "title": b.get("name") or "", "subtitle": b.get("address") or "", "screen": "branches"})
    except Exception:
        pass
    catalog = (
        ("Техническое обслуживание", "ТО-1 / ТО-2", "book"),
        ("Диагностика", "Компьютер + осмотр", "book"),
        ("Замена масла", "Моторное масло + фильтр", "book"),
        ("Шиномонтаж", "Сезонная смена комплекта", "book"),
        ("Тормозная система", "Колодки, диски", "book"),
        ("Подбор запчасти по VIN", "Заявка менеджеру", "vin"),
    )
    for title, sub, screen in catalog:
        if needle in title.lower() or needle in sub.lower():
            hits.append({"kind": "service", "title": title, "subtitle": sub, "screen": screen})
    return {"q": q, "items": hits[:20]}


@app.get("/v1/widget")
def widget_get(authorization: str | None = Header(default=None)) -> dict[str, Any]:
    """Состояние виджета: ok / due / service / ready."""
    state = "ok"
    title = "Всё в порядке"
    subtitle = "Запишитесь, когда понадобится"
    screen = "book"
    user = None
    if authorization:
        try:
            user = require_user(authorization)
        except HTTPException:
            user = None
    cid = int(user["contact_id"]) if user and user.get("contact_id") else 0
    if cid:
        try:
            offers = stocrm.offers_by_contact(cid)
            works = stocrm.works_index([int(o.get("OFFER_ID") or 0) for o in offers if o.get("OFFER_ID")])
            open_ones = []
            for o in offers:
                mapped = _offer_out(o, works.get(int(o.get("OFFER_ID") or 0), []))
                if mapped.get("is_history"):
                    continue
                open_ones.append(mapped)
            ready = [x for x in open_ones if x.get("is_ready")]
            if ready:
                state, title, subtitle, screen = "ready", "Машина готова", str(ready[0].get("status") or "заберите авто"), "status"
            elif open_ones:
                cur = open_ones[0]
                state, title, subtitle, screen = "service", "Авто в сервисе", str(cur.get("status") or "в работе"), "status"
            else:
                cars = stocrm.cars_by_contact(cid)
                for c in cars:
                    km = c.get("MILEAGE")
                    nxt = c.get("NEXT_SERVICE_KM") or c.get("TO_MILEAGE")
                    if nxt and km and int(nxt) - int(km) <= 0:
                        state, title, subtitle, screen = "recs", "Есть рекомендации", "Откройте рекомендации по ремонту", "recommendations"
                        break
        except Exception:
            pass
        if state == "ok" and cid:
            try:
                recs = recommendations_get(authorization)
                if recs.get("items"):
                    state, title, subtitle, screen = "recs", "Есть рекомендации", f"{len(recs['items'])} активных", "recommendations"
            except Exception:
                pass
    return {"state": state, "title": title, "subtitle": subtitle, "screen": screen}


def _audience_ids() -> list[int]:
    ids: set[int] = set(known_contact_ids())
    for row in list_audience():
        try:
            ids.add(int(row.get("contact_id") or 0))
        except (TypeError, ValueError):
            continue
    for u in {**all_sessions(), **sessions}.values():
        if u.get("contact_id"):
            ids.add(int(u["contact_id"]))
    return sorted(i for i in ids if i)


def _campaign_targets(segment: str, branch_id: str, phones: list[str]) -> list[int]:
    targets: list[int] = []
    if phones:
        for p in phones:
            row = audience_by_phone(p)
            cid = 0
            if row:
                try:
                    cid = int(row.get("contact_id") or 0)
                except (TypeError, ValueError):
                    cid = 0
            if not cid:
                try:
                    contact, _, _ = _lookup_contact(p)
                    cid = int((contact or {}).get("CONTACT_ID") or (contact or {}).get("ID") or 0)
                except Exception:
                    cid = 0
            if cid:
                touch_audience(cid, phone=p)
                targets.append(cid)
        seen: set[int] = set()
        uniq: list[int] = []
        for cid in targets:
            if cid not in seen:
                seen.add(cid)
                uniq.append(cid)
        return uniq
    for cid in _audience_ids():
        if _match_segment(cid, segment, branch_id):
            targets.append(cid)
    return targets


def _match_segment(cid: int, segment: str, branch_id: str) -> bool:
    seg = (segment or "all").strip().lower()
    if seg in ("", "all"):
        return True
    try:
        offers = stocrm.offers_by_contact(cid)
    except Exception:
        offers = []
    now = int(datetime.now().timestamp())
    last_ts = 0
    last_branch = ""
    for o in offers:
        raw = o.get("DATE_CREATE") or o.get("CREATED") or o.get("DATE") or o.get("OFFER_DATE_CREATE_FRONTEND_TIMESTAMP") or 0
        try:
            ts = int(raw)
        except (TypeError, ValueError):
            ts = 0
        if ts > 10_000_000_000:
            ts //= 1000
        if ts >= last_ts:
            last_ts = ts
            last_branch = str(o.get("CUSTOMER_ID") or o.get("customer_id") or "")
    if seg == "inactive":
        return last_ts == 0 or now - last_ts >= 90 * 86400
    if seg in ("branch", f"branch:{branch_id}") or seg.startswith("branch"):
        want = branch_id or (seg.split(":", 1)[1] if ":" in seg else "")
        if not want:
            return False
        return last_branch == str(want) or any(str(o.get("CUSTOMER_ID") or "") == str(want) for o in offers)
    return True


@app.get("/admin/")
def admin_page() -> FileResponse:
    path = Path(__file__).resolve().parent / "admin.html"
    if not path.is_file():
        raise HTTPException(404)
    return FileResponse(path)


@app.get("/admin/api/threads")
def admin_threads(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    return {"threads": list_threads()}


@app.get("/admin/api/threads/{key}")
def admin_thread(key: str, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    msgs = list_messages(key)
    last = msgs[-1] if msgs else {}
    return {
        "key": key,
        "messages": msgs,
        "phone": last.get("phone") or "",
        "name": last.get("name") or "",
    }


@app.post("/admin/api/threads/{key}")
def admin_reply(key: str, body: StaffReplyIn, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    text = body.text.strip()
    if not text:
        raise HTTPException(400, "Пустой ответ")
    staff = body.staff_name.strip() or "Егор"
    msg = add_message(key, text=text, from_staff=True, staff_name=staff, kind="chat")
    try:
        cid = int(key)
        add_note(cid, "Новое сообщение", f"{staff}: {text[:120]}", kind="chat")
    except ValueError:
        pass
    return {"ok": True, "item": msg}


@app.get("/admin/api/vin")
def admin_vin(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    return {"items": list_vin()}


@app.get("/admin/api/audience")
def admin_audience(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    return {"items": list_audience(), "contact_ids": _audience_ids()}


@app.get("/admin/api/campaigns")
def admin_campaigns_get(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    return {"items": list_campaigns(), "promos": list_promos()}


@app.post("/admin/api/campaigns")
def admin_campaigns_post(body: CampaignIn, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    title = body.title.strip()
    text = body.body.strip()
    if not title or not text:
        raise HTTPException(400, "Нужны заголовок и текст")
    phones = parse_phones(*[str(p) for p in (body.phones or [])])
    kind = "promo" if body.pin else (body.kind or "push")
    row = add_campaign(
        title=title,
        body=text,
        badge=body.badge,
        segment="phones" if phones else body.segment,
        branch_id=body.branch_id,
        pin=body.pin,
        kind=kind,
    )
    targets = _campaign_targets(body.segment, body.branch_id, phones)
    sent = 0
    for cid in targets:
        add_note(cid, title, text, kind="push" if kind != "promo" else "promo")
        add_message(str(cid), text=f"{title}\n{text}", from_staff=True, staff_name="VAG Market", kind="push")
        sent += 1
    mark_campaign_sent(row["id"], sent)
    row["sent"] = sent
    return {"ok": True, "item": row, "sent": sent, "targets": targets, "phones": len(phones), "fcm": settings.fcm_enabled}


@app.post("/admin/api/campaigns/upload")
async def admin_campaigns_upload(
    x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret"),
    title: str = Form(...),
    body: str = Form(...),
    badge: str = Form("Акция"),
    file: UploadFile = File(...),
) -> dict[str, Any]:
    require_admin(x_bff_secret)
    raw = await file.read()
    phones = phones_from_table(raw, file.filename or "")
    if not phones:
        raise HTTPException(400, "В файле не нашлось номеров")
    return admin_campaigns_post(
        CampaignIn(title=title, body=body, badge=badge, phones=phones, pin=False, kind="push"),
        x_bff_secret,
    )


@app.post("/admin/api/promos")
async def admin_promos_post(
    x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret"),
    title: str = Form(...),
    body: str = Form(""),
    badge: str = Form("Акция"),
    image: UploadFile | None = File(default=None),
) -> dict[str, Any]:
    require_admin(x_bff_secret)
    if not title.strip():
        raise HTTPException(400, "Нужен заголовок")
    row = add_campaign(title=title, body=body or title, badge=badge, pin=True, kind="promo")
    if image and image.filename:
        data = await image.read()
        if data:
            save_promo_image(row["id"], data, Path(image.filename).suffix)
            row["image"] = True
    return {"ok": True, "item": row}


@app.get("/admin/api/tickets")
def admin_tickets(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    items = list_tickets()
    return {
        "items": items,
        "vin": sum(1 for x in items if x.get("kind") == "vin"),
        "book": sum(1 for x in items if x.get("kind") == "book"),
    }


@app.get("/admin/api/shorts")
def admin_shorts_get(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    return {"items": list_shorts_admin()}


@app.post("/admin/api/shorts")
def admin_shorts_post(body: ShortIn, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    title = body.title.strip()
    if not title:
        raise HTTPException(400, "Нужен заголовок ролика")
    row = add_short(title=title, subtitle=body.subtitle, url=body.url, poster=body.poster)
    return {"ok": True, "item": row}


@app.put("/admin/api/shorts/{sid}")
def admin_shorts_put(sid: str, body: ShortIn, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    title = body.title.strip()
    if not title:
        raise HTTPException(400, "Нужен заголовок ролика")
    try:
        row = update_short(sid, title=title, subtitle=body.subtitle, url=body.url, poster=body.poster)
    except KeyError:
        raise HTTPException(404, "Ролик не найден") from None
    except ValueError as e:
        raise HTTPException(400, str(e)) from e
    return {"ok": True, "item": row}


@app.delete("/admin/api/shorts/{sid}")
def admin_shorts_delete(sid: str, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    if not delete_short(sid):
        raise HTTPException(404, "Ролик не найден")
    return {"ok": True, "id": sid}


@app.get("/admin/api/smtp")
def admin_smtp_get(x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    return smtp_public()


@app.post("/admin/api/smtp")
def admin_smtp_post(body: SmtpIn, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    host = body.host.strip()
    user = body.user.strip()
    sender = (body.from_addr or user).strip()
    if host and not sender:
        raise HTTPException(400, "Укажите ящик отправителя (логин или From)")
    persist_smtp(
        host=host,
        port=int(body.port or 465),
        user=user,
        password=body.password if body.password else None,
        smtp_from=sender,
        tls=body.tls,
        ssl=body.ssl,
    )
    return {"ok": True, **smtp_public()}


@app.post("/admin/api/smtp/test")
def admin_smtp_test(body: SmtpTestIn, x_bff_secret: str | None = Header(default=None, alias="X-BFF-Secret")) -> dict[str, Any]:
    require_admin(x_bff_secret)
    if not smtp_ready():
        raise HTTPException(400, "Сначала сохраните хост, ящик и пароль")
    to = (body.to or settings.smtp_from or settings.smtp_user or "").strip()
    try:
        to = valid_email(to)
    except ValueError as e:
        raise HTTPException(400, str(e)) from e
    ok, err = send_test_email(to)
    if not ok:
        raise HTTPException(502, err or "SMTP отклонил письмо")
    return {"ok": True, "to": mask_email(to)}


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


def _as_coord(raw: Any) -> float | None:
    if raw in (None, False, ""):
        return None
    try:
        return float(str(raw).replace(",", "."))
    except (TypeError, ValueError):
        return None


def _strip_index(text: str) -> str:
    return re.sub(r"\b\d{6}\b,?\s*", "", text or "").strip(" ,")


def _has_house(text: str) -> bool:
    return bool(re.search(r"\d", _strip_index(text)))


def _looks_like_street(text: str) -> bool:
    t = _strip_index(text).lower()
    if re.search(r"\d", t):
        return True
    return bool(re.search(r"\b(ул|улица|пр|проспект|пер|переулок|ш|шоссе|тракт|наб)\b", t))


def _city_only(address: str, city: str) -> bool:
    a = re.sub(r"[.\s]+", " ", (address or "").lower()).strip()
    c = re.sub(r"[.\s]+", " ", (city or "").lower()).strip()
    if not a:
        return True
    if _has_house(a):
        return False
    a = a.replace("город ", "").replace("г ", "")
    c = c.replace("город ", "").replace("г ", "")
    return a in {c, f"г {c}"} or a.replace("ё", "е") == c.replace("ё", "е")


def _addr_json(raw: Any) -> dict[str, Any]:
    return raw if isinstance(raw, dict) else {}


def _family_address(rows: list[dict[str, Any]], c: dict[str, Any]) -> tuple[dict[str, Any], str]:
    """Если у активной точки нет улицы — взять ADDRESS_JSON/ADDRESS одноимённой карточки CRM."""
    aj = dict(_addr_json(c.get("ADDRESS_JSON")))
    addr = str(c.get("ADDRESS") or "").strip()
    name = str(c.get("CUSTOMER_NAME") or "").strip().lower()
    if not name:
        return aj, addr
    for other in rows:
        if str(other.get("CUSTOMER_NAME") or "").strip().lower() != name:
            continue
        oj = _addr_json(other.get("ADDRESS_JSON"))
        if oj.get("STREET") and not aj.get("STREET"):
            aj = dict(oj)
        oa = str(other.get("ADDRESS") or "").strip()
        if _has_house(oa) and not _has_house(addr):
            addr = oa
    return aj, addr


def _pretty_address(c: dict[str, Any], aj: dict[str, Any], fallback: str) -> str:
    city = str(aj.get("CITY") or c.get("CITY_NAME") or "").strip()
    street = str(aj.get("STREET") or "").strip()
    house = str(aj.get("HOUSE") or "").strip()
    if street:
        titled = street if re.match(r"^(ул|пр|пер|ш|наб)\b", street.lower()) else f"ул. {street}"
        parts = [p for p in (city, titled, house) if p]
        return ", ".join(parts)
    for cand in (aj.get("ADDRESS"), fallback, c.get("ADDRESS"), aj.get("ADDRESS_FULL")):
        text = str(cand or "").strip()
        if text and _looks_like_street(text):
            return _strip_index(text)
    return city or _strip_index(str(c.get("ADDRESS") or ""))


def _is_city_center(lat: float | None, lng: float | None, aj: dict[str, Any]) -> bool:
    if lat is None or lng is None:
        return True
    if aj.get("STREET") or aj.get("HOUSE"):
        return False
    return abs(lat - 57.1531178) < 0.0002 and abs(lng - 65.5343535) < 0.0002


def _maps_url(address: str, name: str, city: str, lat: float | None = None, lng: float | None = None) -> str:
    if lat is not None and lng is not None:
        return f"https://2gis.ru/geo/{lng},{lat}"
    q = " ".join(x for x in (city or "Тюмень", address or name) if x).strip()
    return f"https://2gis.ru/tyumen/search/{quote(q)}"


def _public_branches(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    rules = [
        ("Московский", ("московск", "vag market"), 2113, "Тюмень, Московский тракт, 118/11"),
        ("Эрвье", ("эрвье", "ervie", "ervye"), 0, "Тюмень, ул. Эрвье"),
        ("Республика", ("республик", "nin hao", "ninhao", "nin-hao"), 0, "Тюмень, ул. Республики"),
    ]
    picked: list[dict[str, Any]] = []
    used: set[str] = set()
    for label, needles, hint, fallback_addr in rules:
        match = None
        if hint:
            match = next((r for r in rows if str(r.get("id")) == str(hint)), None)
        if match is None:
            for r in rows:
                blob = f"{r.get('name') or ''} {r.get('address') or ''} {r.get('street') or ''}".lower()
                if any(n in blob for n in needles):
                    match = r
                    break
        if match is None:
            picked.append({
                "id": str(hint or label),
                "name": label,
                "address": fallback_addr,
                "phone": "+7 345 257-98-88",
                "city": "Тюмень",
                "work_time": "09:00–20:00",
                "maps_url": f"https://2gis.ru/tyumen/search/{quote(fallback_addr)}",
                "yandex_url": f"https://yandex.ru/maps/?text={quote(fallback_addr)}",
            })
            continue
        kid = str(match.get("id") or "")
        if kid in used:
            continue
        used.add(kid)
        item = dict(match)
        item["name"] = label
        addr = str(item.get("address") or "").strip()
        if not addr or addr.lower() in {"тюмень", "tyumen"}:
            item["address"] = fallback_addr
        picked.append(item)
    return picked[:3]


def _yandex_url(address: str, name: str, city: str, lat: float | None = None, lng: float | None = None) -> str:
    if lat is not None and lng is not None:
        return f"https://yandex.ru/maps/?pt={lng},{lat}&z=16&l=map"
    q = " ".join(x for x in (city or "Тюмень", address or name) if x).strip()
    return f"https://yandex.ru/maps/?text={quote(q)}"


def _branch_out(c: dict[str, Any], family: list[dict[str, Any]]) -> dict[str, Any]:
    aj, fallback = _family_address(family, c)
    address = _pretty_address(c, aj, fallback)
    city = str(aj.get("CITY") or c.get("CITY_NAME") or "").strip()
    lat = _as_coord(aj.get("LATITUDE"))
    lng = _as_coord(aj.get("LONGITUDE"))
    precise = not _is_city_center(lat, lng, aj)
    if not precise:
        lat, lng = None, None
    name = str(c.get("CUSTOMER_NAME") or "")
    return {
        "id": c.get("CUSTOMER_ID"),
        "name": name,
        "address": address,
        "phone": _phone_out(c.get("PHONES")),
        "site": c.get("SITE") or "",
        "city": city,
        "street": str(aj.get("STREET") or ""),
        "house": str(aj.get("HOUSE") or ""),
        "work_time": _work_time_out(c.get("WORK_TIME_STRING") or c.get("WORK_TIME")),
        "lat": lat,
        "lng": lng,
        "precise": precise,
        "maps_url": _maps_url(address, name, city, lat, lng),
        "yandex_url": _yandex_url(address, name, city, lat, lng),
    }


if settings.serve_site:
    mount_site(app)

