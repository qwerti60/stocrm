from pathlib import Path
from typing import Any
import re

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_ROOT = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=_ROOT / ".env", env_file_encoding="utf-8", extra="ignore")

    stocrm_domain: str = ""
    stocrm_sid: str = ""
    stocrm_board_id: int | None = None
    stocrm_source_id: int | None = None
    dev_otp_code: str = "1234"
    smtp_host: str = ""
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""
    smtp_from: str = ""
    smtp_tls: bool = True
    smtp_ssl: bool | None = None
    bff_secret: str = "change-me"
    host: str = "0.0.0.0"
    port: int = 8080
    serve_site: bool = True
    fcm_server_key: str = ""
    fcm_credentials: str = "secrets/firebase-adminsdk.json"
    poll_interval_sec: int = 90
    admin_password: str = ""
    bonus_percent: int = 5
    bonus_expire_days: int = 365
    bonus_warn_days: int = 5
    bonus_min_sum: int = 500

    @property
    def is_dev_secret(self) -> bool:
        return self.bff_secret in ("", "change-me")

    @property
    def admin_key(self) -> str:
        return (self.admin_password or self.bff_secret or "").strip()

    @field_validator("stocrm_board_id", "stocrm_source_id", mode="before")
    @classmethod
    def empty_int(cls, v: Any) -> Any:
        if v is None or v == "":
            return None
        return v

    @field_validator("smtp_port", mode="before")
    @classmethod
    def smtp_port_int(cls, v: Any) -> Any:
        if v is None or v == "":
            return 587
        return v

    @field_validator("smtp_ssl", mode="before")
    @classmethod
    def empty_ssl(cls, v: Any) -> Any:
        if v is None or v == "":
            return None
        return v

    @property
    def fcm_credentials_path(self) -> Path:
        raw = (self.fcm_credentials or "secrets/firebase-adminsdk.json").strip()
        path = Path(raw)
        if not path.is_absolute():
            path = _ROOT / path
        return path

    @property
    def fcm_enabled(self) -> bool:
        return self.fcm_credentials_path.is_file() or bool((self.fcm_server_key or "").strip())

    @property
    def smtp_use_ssl(self) -> bool:
        if self.smtp_ssl is not None:
            return bool(self.smtp_ssl)
        return int(self.smtp_port or 0) == 465

    @property
    def base_url(self) -> str:
        domain = self.stocrm_domain.strip().removeprefix("https://").removeprefix("http://").rstrip("/")
        if domain.endswith(".stocrm.ru"):
            return f"https://{domain}/api/external/v1"
        if "." not in domain:
            return f"https://{domain}.stocrm.ru/api/external/v1"
        return f"https://{domain}/api/external/v1"


def _env_quote(value: str) -> str:
    if value == "" or re.search(r'[\s#"\'\\]', value):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return value


def persist_smtp(
    *,
    host: str,
    port: int,
    user: str,
    password: str | None,
    smtp_from: str,
    tls: bool,
    ssl: bool | None,
) -> None:
    settings.smtp_host = (host or "").strip()
    settings.smtp_port = int(port or 465)
    settings.smtp_user = (user or "").strip()
    if password is not None:
        settings.smtp_password = password
    settings.smtp_from = (smtp_from or settings.smtp_user or "").strip()
    settings.smtp_tls = bool(tls)
    settings.smtp_ssl = ssl
    values = {
        "SMTP_HOST": settings.smtp_host,
        "SMTP_PORT": str(settings.smtp_port),
        "SMTP_USER": settings.smtp_user,
        "SMTP_PASSWORD": settings.smtp_password or "",
        "SMTP_FROM": settings.smtp_from,
        "SMTP_TLS": "true" if settings.smtp_tls else "false",
        "SMTP_SSL": "" if settings.smtp_ssl is None else ("true" if settings.smtp_ssl else "false"),
    }
    path = _ROOT / ".env"
    lines = path.read_text(encoding="utf-8").splitlines() if path.exists() else []
    seen: set[str] = set()
    out: list[str] = []
    for line in lines:
        m = re.match(r"^([A-Z_]+)=", line)
        if m and m.group(1) in values:
            key = m.group(1)
            out.append(f"{key}={_env_quote(values[key])}")
            seen.add(key)
        else:
            out.append(line)
    for key, val in values.items():
        if key not in seen:
            out.append(f"{key}={_env_quote(val)}")
    path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
    try:
        path.chmod(0o640)
    except OSError:
        pass


settings = Settings()
