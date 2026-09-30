from __future__ import annotations

from io import BytesIO
from pathlib import Path
from typing import Any

from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

_FONT_CANDIDATES = [
    Path("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"),
    Path("/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf"),
    Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf"),
    Path("/Library/Fonts/Arial Unicode.ttf"),
    Path("/System/Library/Fonts/Supplemental/Arial.ttf"),
]


def _font() -> str:
    for p in _FONT_CANDIDATES:
        if p.is_file():
            name = "VagPdf"
            try:
                pdfmetrics.registerFont(TTFont(name, str(p)))
                return name
            except Exception:
                continue
    return "Helvetica"


def work_order_pdf(offer: dict[str, Any]) -> bytes:
    buf = BytesIO()
    c = canvas.Canvas(buf, pagesize=A4)
    w, h = A4
    font = _font()
    y = h - 18 * mm
    c.setFillColorRGB(0.88, 0.02, 0.07)
    c.rect(0, h - 16 * mm, w, 16 * mm, fill=1, stroke=0)
    c.setFillColorRGB(1, 1, 1)
    c.setFont(font, 16)
    c.drawString(16 * mm, h - 11 * mm, "VAG MARKET")
    c.setFont(font, 9)
    c.drawRightString(w - 16 * mm, h - 11 * mm, "заказ-наряд")
    c.setFillColorRGB(0.05, 0.05, 0.05)
    c.setFont(font, 14)
    oid = offer.get("id") or "—"
    c.drawString(16 * mm, y - 8 * mm, f"Заказ-наряд № {oid}")
    c.setFont(font, 10)
    lines = [
        f"Дата: {offer.get('when') or '—'}",
        f"Автомобиль: {offer.get('car') or '—'}",
        f"Филиал: {offer.get('branch') or '—'}",
        f"Статус: {offer.get('status') or 'успешно реализовано'}",
        f"Сумма: {offer.get('sum') or '—'} ₽",
    ]
    yy = y - 18 * mm
    for line in lines:
        c.drawString(16 * mm, yy, line)
        yy -= 6 * mm
    yy -= 4 * mm
    c.setFont(font, 12)
    c.drawString(16 * mm, yy, "Работы")
    yy -= 7 * mm
    c.setFont(font, 10)
    works = offer.get("works") or []
    if not works:
        c.drawString(16 * mm, yy, "—")
        yy -= 6 * mm
    for i, item in enumerate(works, 1):
        if yy < 20 * mm:
            c.showPage()
            yy = h - 20 * mm
            c.setFont(font, 10)
        c.drawString(16 * mm, yy, f"{i}. {item}")
        yy -= 6 * mm
    parts = offer.get("parts") or []
    if parts:
        yy -= 4 * mm
        c.setFont(font, 12)
        c.drawString(16 * mm, yy, "Запчасти и материалы")
        yy -= 7 * mm
        c.setFont(font, 10)
        for i, item in enumerate(parts, 1):
            if yy < 20 * mm:
                c.showPage()
                yy = h - 20 * mm
                c.setFont(font, 10)
            c.drawString(16 * mm, yy, f"{i}. {item}")
            yy -= 6 * mm
    c.setFont(font, 8)
    c.setFillColorRGB(0.4, 0.4, 0.4)
    c.drawString(16 * mm, 12 * mm, "Документ сформирован в приложении VAG Market. Редактирование PDF недоступно.")
    c.save()
    return buf.getvalue()
