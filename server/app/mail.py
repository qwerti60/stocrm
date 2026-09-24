from __future__ import annotations

import logging
import re
import smtplib
from email.message import EmailMessage

from app.config import settings

log = logging.getLogger("uvicorn.error")

_EMAIL = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def valid_email(raw: str) -> str:
    email = (raw or "").strip().lower()
    if not _EMAIL.match(email) or len(email) > 120:
        raise ValueError("Нужен корректный email")
    return email


def mask_email(email: str) -> str:
    email = (email or "").strip()
    if "@" not in email:
        return ""
    name, domain = email.split("@", 1)
    if len(name) <= 1:
        shown = "*"
    else:
        shown = name[0] + "***"
    return f"{shown}@{domain}"


def smtp_ready() -> bool:
    host = (settings.smtp_host or "").strip()
    sender = (settings.smtp_from or settings.smtp_user or "").strip()
    user = (settings.smtp_user or "").strip()
    if not host or not sender:
        return False
    if user and not (settings.smtp_password or "").strip():
        return False
    return True


def smtp_public() -> dict[str, object]:
    return {
        "ready": smtp_ready(),
        "host": (settings.smtp_host or "").strip(),
        "port": int(settings.smtp_port or 465),
        "user": (settings.smtp_user or "").strip(),
        "from": (settings.smtp_from or "").strip(),
        "tls": bool(settings.smtp_tls),
        "ssl": settings.smtp_use_ssl,
        "password_set": bool((settings.smtp_password or "").strip()),
    }


def _from_header() -> str:
    raw = (settings.smtp_from or settings.smtp_user or "").strip()
    if not raw:
        return "VAG Market <noreply@localhost>"
    if "<" in raw:
        return raw
    return f"VAG Market <{raw}>"


def send_otp_email(to: str, code: str) -> bool:
    ok, _ = deliver(
        to,
        f"Код VAG Market: {code}",
        f"Ваш код подтверждения VAG Market: {code}\n\n"
        "Никому не сообщайте код. Если вы не запрашивали вход — проигнорируйте письмо.\n",
        "<p>Ваш код подтверждения <strong>VAG Market</strong>:</p>"
        f"<p style='font-size:28px;font-weight:800;letter-spacing:4px'>{code}</p>"
        "<p>Никому не сообщайте код. Если вы не запрашивали вход — проигнорируйте письмо.</p>",
    )
    return ok


def send_test_email(to: str) -> tuple[bool, str]:
    return deliver(
        to,
        "VAG Market: SMTP работает",
        "Тестовое письмо с сервера VAG Market. Коды входа будут приходить с этого ящика.\n",
        "<p>Тестовое письмо с сервера <strong>VAG Market</strong>.</p>"
        "<p>Коды входа будут приходить с этого ящика.</p>",
    )


def deliver(to: str, subject: str, text: str, html: str) -> tuple[bool, str]:
    if not smtp_ready():
        return False, "SMTP не задан: нужен хост, ящик и пароль"
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = _from_header()
    msg["To"] = to
    msg.set_content(text)
    msg.add_alternative(html, subtype="html")
    host = settings.smtp_host.strip()
    port = int(settings.smtp_port or 587)
    use_ssl = settings.smtp_use_ssl
    try:
        if use_ssl:
            with smtplib.SMTP_SSL(host, port, timeout=20) as smtp:
                _auth_and_send(smtp, msg)
        else:
            with smtplib.SMTP(host, port, timeout=20) as smtp:
                smtp.ehlo()
                if settings.smtp_tls:
                    smtp.starttls()
                    smtp.ehlo()
                _auth_and_send(smtp, msg)
        return True, "ok"
    except Exception as e:
        log.exception("SMTP send failed to %s via %s:%s", mask_email(to), host, port)
        return False, str(e)[:300]


def _auth_and_send(smtp: smtplib.SMTP, msg: EmailMessage) -> None:
    user = (settings.smtp_user or "").strip()
    if user:
        smtp.login(user, settings.smtp_password or "")
    smtp.send_message(msg)
