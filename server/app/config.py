from pathlib import Path
from typing import Any

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
    bff_secret: str = "change-me"
    host: str = "0.0.0.0"
    port: int = 8080
    serve_site: bool = True

    @property
    def is_dev_secret(self) -> bool:
        return self.bff_secret in ("", "change-me")

    @field_validator("stocrm_board_id", "stocrm_source_id", mode="before")
    @classmethod
    def empty_int(cls, v: Any) -> Any:
        if v is None or v == "":
            return None
        return v

    @property
    def base_url(self) -> str:
        domain = self.stocrm_domain.strip().removeprefix("https://").removeprefix("http://").rstrip("/")
        if domain.endswith(".stocrm.ru"):
            return f"https://{domain}/api/external/v1"
        if "." not in domain:
            return f"https://{domain}.stocrm.ru/api/external/v1"
        return f"https://{domain}/api/external/v1"


settings = Settings()
