#!/usr/bin/env python3
"""Сборка dogovor.docx с таблицами (реквизиты, календарь, кураторы)."""

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn, nsmap
from docx.shared import Cm, Pt, RGBColor, Emu, Inches
from docx.enum.section import WD_ORIENT

OUT = "/Users/ivanov/Downloads/1305/stocrm-mobile-app/dogovor.docx"
SHOTS = "/Users/ivanov/Downloads/1305/stocrm-mobile-app/screenshots"

TZ_SHOTS = [
    ("00-shorts.png", "Шортсы"),
    ("01-auth.png", "Вход"),
    ("01-auth-otp.png", "Код OTP"),
    ("02-home.png", "Главная"),
    ("03-garage.png", "Гараж"),
    ("04-book.png", "Запись"),
    ("08-branches.png", "Адреса"),
    ("07-chat.png", "Чат · Егор"),
    ("06-profile.png", "Профиль · бонусы 5%"),
]


def set_run(run, size=11, bold=False, name="Times New Roman"):
    run.font.name = name
    run.font.size = Pt(size)
    run.bold = bold
    r = run._element
    rPr = r.get_or_add_rPr()
    rFonts = rPr.get_or_add_rFonts()
    rFonts.set(qn("w:ascii"), name)
    rFonts.set(qn("w:hAnsi"), name)
    rFonts.set(qn("w:cs"), name)
    rFonts.set(qn("w:eastAsia"), name)


def p(doc, text="", size=11, bold=False, center=False, space_after=6, space_before=0):
    para = doc.add_paragraph()
    para.paragraph_format.space_after = Pt(space_after)
    para.paragraph_format.space_before = Pt(space_before)
    para.paragraph_format.line_spacing = 1.15
    if center:
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    if text:
        run = para.add_run(text)
        set_run(run, size=size, bold=bold)
    return para


def heading(doc, text, size=13):
    return p(doc, text, size=size, bold=True, space_before=10, space_after=8)


def bullet(doc, text, size=10):
    para = doc.add_paragraph()
    para.paragraph_format.left_indent = Cm(0.6)
    para.paragraph_format.space_after = Pt(2)
    para.paragraph_format.line_spacing = 1.1
    run = para.add_run("• " + text)
    set_run(run, size=size)
    return para


def numbered(doc, n, text, size=10):
    para = doc.add_paragraph()
    para.paragraph_format.left_indent = Cm(0.6)
    para.paragraph_format.space_after = Pt(2)
    para.paragraph_format.line_spacing = 1.1
    run = para.add_run(f"{n}. {text}")
    set_run(run, size=size)
    return para


def simple_table(doc, headers, rows):
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    style_table(t)
    for i, h in enumerate(headers):
        cell_text(t.rows[0].cells[i], h, bold=True, size=9)
        shade(t.rows[0].cells[i])
    for r, row in enumerate(rows, 1):
        for c, val in enumerate(row):
            cell_text(t.rows[r].cells[c], val, size=9)
    return t


def subh(doc, text):
    return p(doc, text, size=11, bold=True, space_before=8, space_after=4)


def add_shot_grid(doc, cols=3, width=Inches(1.72)):
    rows_n = (len(TZ_SHOTS) + cols - 1) // cols
    table = doc.add_table(rows=rows_n, cols=cols)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl = table._tbl
    tblPr = tbl.tblPr if tbl.tblPr is not None else OxmlElement("w:tblPr")
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "nil")
        el.set(qn("w:sz"), "0")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), "FFFFFF")
        borders.append(el)
    tblPr.append(borders)
    for i, (fn, cap) in enumerate(TZ_SHOTS):
        cell = table.rows[i // cols].cells[i % cols]
        cell.text = ""
        para = cell.paragraphs[0]
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
        para.paragraph_format.space_after = Pt(2)
        para.add_run().add_picture(f"{SHOTS}/{fn}", width=width)
        cap_p = cell.add_paragraph(cap)
        cap_p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        cap_p.paragraph_format.space_after = Pt(8)
        set_run(cap_p.runs[0], size=8)
        v_align_top(cell)


def add_full_tz(doc):
    p(doc, "Приложение № 1 к договору № 10092026", size=13, bold=True, center=True, space_after=0)
    p(doc, "от «10» сентября 2026 г.", size=12, bold=True, center=True, space_after=6)
    heading(doc, "Техническое задание (полное) v1.1")
    p(
        doc,
        "Клиентское мобильное приложение автосервиса с интеграцией STOCRM",
        bold=True,
        space_after=6,
    )
    p(
        doc,
        "Согласовано на встрече 11.09.2026. Настоящее Приложение содержит полное ТЗ и является "
        "неотъемлемой частью договора. Стороны подписывают каждый лист.",
        size=10,
        space_after=6,
    )
    p(
        doc,
        "VAG Market · Flutter iOS / Android · акцент на push · источник данных — STOCRM Заказчика. "
        "Фирменные цвета: красный #E10613, чёрный #0B0B0D, белый.",
        size=10,
    )
    simple_table(
        doc,
        ["", ""],
        [
            ["Заказчик", "ИП Гоман Павел Игоревич · vagmarket72.ru · 3 филиала"],
            ["Продукт", "Брендированное клиентское приложение + веб-админка для менеджеров"],
            [
                "Приоритет",
                "Push: статус авто, «машина готова», акции, сервисные напоминания, сгорание бонусов, массовые рассылки",
            ],
            [
                "Интеграция",
                "STOCRM External API v1 · https://{домен}.stocrm.ru/api/external/v1/ · клиент по телефону",
            ],
            ["Дизайн", "Тёмная тема VAG Market. При открытии — слайдер видео-шортсов. Скрины прототипа — в п. 13"],
            ["Исполнитель", "ИП Иванов А.В. · t.me/app154 · +7 913 914-29-94"],
        ],
    )

    heading(doc, "1. Цель")
    p(
        doc,
        "Дать клиентам VAG Market своё приложение: запись на сервис, история работ, статусы автомобиля и "
        "push-уведомления о готовности, акциях и напоминаниях. Учёт ведётся в STOCRM. Приложение и веб-админка — "
        "клиентский канал и рабочее место менеджера по заявкам, чату и рассылкам, не замена STOCRM.",
        size=10,
    )
    p(
        doc,
        "Не путать со штатным приложением STOCRM (для сотрудников) и GoodGarage. Здесь — бренд VAG Market "
        "в сторах, три филиала, бонусы 5% из CRM.",
        size=10,
    )

    heading(doc, "2. Пользователи")
    simple_table(
        doc,
        ["Роль", "Где", "Что делает"],
        [
            [
                "Клиент",
                "Мобильное приложение",
                "Вход по телефону, гараж, запись, история, статусы, рекомендации, чат, бонусы, VIN-заявка, пуши",
            ],
            [
                "Менеджер",
                "Веб-админка",
                "Подтверждает запись, отвечает в чате (видно имя), массовые push, заявки по VIN",
            ],
            [
                "Приёмка / мастер",
                "STOCRM (как сейчас)",
                "Ведёт заказ-наряд, меняет статус, рекомендации, закрывает работы",
            ],
        ],
    )

    heading(doc, "3. Основные требования")
    subh(doc, "3.1. Редактирование данных")
    bullet(
        doc,
        "Клиент корректирует гараж (пробег, марка, госномер, VIN) и параметры неподтверждённой заявки "
        "(авто, филиал, дата/время, услуга).",
    )
    bullet(
        doc,
        "Менеджер в веб-админке корректирует заявки и состав услуг до подтверждения; после подтверждения "
        "изменения учёта — в STOCRM, в приложение подтягиваются автоматически.",
    )
    bullet(doc, "Закрытые заказ-наряды клиент не редактирует (только просмотр).")
    subh(doc, "3.2. Поиск (по возможности)")
    p(
        doc,
        "Поиск по истории работ, услугам и филиалам — если API STOCRM позволяет. Иначе — локальный список "
        "(свои авто, свои визиты).",
        size=10,
    )
    subh(doc, "3.3. Push — ключевой функционал")
    p(
        doc,
        "Акцент продукта — уведомления. Каналы: FCM + APNs. Отправка FCM бесплатна; SMS OTP — по тарифу оператора.",
        size=10,
    )
    simple_table(
        doc,
        ["Событие", "Текст (ориентир)", "Откуда"],
        [
            ["Смена статуса ЗН, машина готова", "«Ваша машина готова!»", "Статус в STOCRM"],
            ["Статус «в работе» и другие согласованные", "Краткий статус + филиал", "STOCRM"],
            ["Напоминание о ТО / обслуживании", "Пора в сервис", "Рекомендации / пробег / дата"],
            ["Сгорание бонусов", "За несколько дней до окончания срока", "Модуль лояльности CRM / правило 5%"],
            ["Акции и личные предложения", "Текст менеджера", "Рассылка из админки"],
            ["Запись", "Заявка принята / подтверждена / нужна связь", "Админка + CRM"],
        ],
    )
    p(
        doc,
        "Клиент включает согласие на пуши и рассылки при OTP (152-ФЗ). В профиле — выключатель уведомлений.",
        size=10,
        space_before=6,
    )
    subh(doc, "3.4. Старт приложения: видео-шортсы")
    bullet(
        doc,
        "При открытии (до главной) — полноэкранный вертикальный слайдер видео-шортсов (Stories / Reels): "
        "ролики сервиса, акции, «машина готова», VIN.",
    )
    bullet(doc, "Листание вверх/вниз, автопрокрутка, кнопка «В приложение». Повторно — с главной / акций.")
    bullet(doc, "Контент роликов готовит Заказчик (видео 9:16). В админке — загрузка и порядок в ленте.")

    heading(doc, "4. Интеграция со STOCRM")
    p(
        doc,
        "SID не кладём в приложение. Клиент ходит только на BFF. BFF хранит SID, домен и ходит во внешний API. "
        "Клиент привязывается по номеру телефона (+7, без дублей контакта).",
        size=10,
    )
    bullet(doc, "Синхронизация через API STOCRM (poller / webhook — что откроет вендор по SID).")
    bullet(doc, "В историю — только успешно реализованные (закрытые) заказы.")
    bullet(doc, "Карточка заказа: дата, филиал, пробег, работы, запчасти, сумма — в объёме полей API.")
    bullet(doc, "Запись создаёт сделку offer/new/with_contact, источник «Онлайн-запись» (SOURCE_ID согласуем).")
    p(
        doc,
        "На старте Заказчик выдаёт SID и тестовый контакт. Исполнитель за 1–2 дня снимает карту методов. "
        "Если календарь постов API не отдаёт — слоты по графику филиала; менеджер подтверждает запись в админке, "
        "пост в CRM бронирует приёмка. Жёсткая блокировка поста — когда вендор откроет методы.",
        size=10,
        space_before=6,
    )

    heading(doc, "5. Статусы автомобиля")
    bullet(
        doc,
        "Клиент видит статус текущего ЗН: как минимум «в работе», «выполнено», «машина готова»; "
        "расширенный набор — по воронке STOCRM Заказчика.",
    )
    bullet(doc, "При смене статуса — push. Для готовности — «Ваша машина готова!».")

    heading(doc, "6. Рекомендации после осмотра")
    bullet(doc, "Отдельный раздел «Рекомендации»: то, что мастер указал в CRM.")
    bullet(doc, "С главной — вход в раздел и мотивация записаться. Источник — только CRM.")

    heading(doc, "7. Карты и филиалы")
    bullet(doc, "Выбор одного из трёх филиалов (адреса, телефоны, график, координаты — от Заказчика).")
    bullet(doc, "Карта: 2ГИС или Яндекс.Карты (один провайдер); маршрут — в приложении карт на телефоне.")

    heading(doc, "8. Чат-поддержка")
    bullet(doc, "У клиента в приложении — чат с сервисом.")
    bullet(doc, "Менеджеры отвечают через веб-админку (не через личный Telegram как единственный канал).")
    bullet(doc, "Клиенту показывается имя менеджера, с которым идёт переписка.")
    bullet(doc, "Push о новом ответе менеджера.")

    heading(doc, "9. Запись на сервис")
    numbered(doc, 1, "Быстрая запись: автомобиль, дата, время (филиал из трёх; услуга/комментарий — по желанию).")
    numbered(doc, 2, "Слоты из системы: разное количество для разных дней и филиалов.")
    numbered(doc, 3, "После отправки: «Вы записаны, ожидайте подтверждения звонка или сообщения».")
    numbered(doc, 4, "Заявка в веб-админку: уточнить, подтвердить или перенести. Подтверждение — в приложение и push.")
    numbered(doc, 5, "Параллельно создаётся сделка в STOCRM.")

    heading(doc, "10. Подбор запчастей по VIN")
    bullet(doc, "Кнопка «Подбор запчастей по VIN».")
    bullet(doc, "Клиент вводит VIN (или из карточки авто) и наименование запчасти / комментарий.")
    bullet(doc, "Заявка менеджеру в админку (не витрина склада). Ответ — в чате или звонком.")

    heading(doc, "11. Бонусная программа и кэшбек")
    p(
        doc,
        "Перенос бонусной программы из CRM / правил VAG Market (на сайте: 5% накопления, списание до 50% суммы).",
        size=10,
    )
    bullet(doc, "Начисление 5% от суммы закрытого заказ-наряда.")
    bullet(doc, "История начисления и списания бонусов в приложении.")
    bullet(doc, "Push о сгорании бонусов за несколько дней до окончания срока (ориентир 3–7 дней, задаёт Заказчик).")
    p(
        doc,
        "Если API лояльности не отдаёт баланс — BFF считает 5% по закрытым ЗН и ведёт журнал; списание на кассе "
        "остаётся в STOCRM и подтягивается, когда метод доступен.",
        size=10,
        space_before=4,
    )

    heading(doc, "12. Рассылки и спецпредложения")
    bullet(doc, "Массовые и сегментные push с акциями, скидками, личными предложениями.")
    bullet(doc, "Менеджер создаёт рассылку в веб-админке: заголовок, текст, аудитория, время.")
    bullet(doc, "Лента акций на главной — те же материалы, плюс закреплённые карточки.")

    heading(doc, "13. Дизайн и фирменный стиль")
    bullet(
        doc,
        "Логотип и цвета: красный #E10613, чёрный #0B0B0D, белый. Ориентир — прототип VAG Market (тёмная тема).",
    )
    bullet(
        doc,
        "Главная: слоган «Ваш VAG в надёжных руках», марки VW / Audi / SEAT / Škoda, VIN и запись, квикс, "
        "спецпредложения, бонусы, сервисбук, чат, баннер диагностики.",
    )
    bullet(doc, "Нижнее меню: Главная · Гараж · Запись · Адреса · Чаты · Профиль.")
    p(doc, "Скрины прототипа (сентябрь 2026):", size=10, space_before=4, space_after=6)
    add_shot_grid(doc)

    heading(doc, "14. Виджет на главном экране телефона")
    bullet(doc, "Виджет iOS WidgetKit / Android App Widget (идея как у Duolingo).")
    bullet(doc, "Состояния: всё в порядке; пора на ТО; авто в сервисе; машина готова.")
    bullet(doc, "Визуал: в т.ч. «сломанная машинка» — макеты согласуем с Заказчиком.")
    bullet(doc, "Тап открывает запись / статус / рекомендации.")

    heading(doc, "15. Экраны")
    simple_table(
        doc,
        ["Где", "Экран", "Содержание"],
        [
            ["Приложение", "Шортсы", "Вертикальный слайдер видео при открытии"],
            ["Приложение", "Вход", "Телефон + OTP"],
            ["Приложение", "Главная", "По макету: VIN, запись, квикс, акции, бонусы, чат"],
            ["Приложение", "Гараж", "Авто, пробег, VIN, редактирование"],
            ["Приложение", "Запись", "Авто → филиал → дата/слот → ожидание подтверждения"],
            ["Приложение", "Филиалы", "3 точки, карта 2ГИС или Яндекс"],
            ["Приложение", "История", "Только закрытые ЗН: пробег, работы, запчасти"],
            ["Приложение", "Статус", "Текущий ремонт, пуш при смене"],
            ["Приложение", "Рекомендации", "Из CRM после осмотра"],
            ["Приложение", "Чат", "Поддержка, имя менеджера"],
            ["Приложение", "VIN", "Заявка на подбор запчасти"],
            ["Приложение", "Бонусы", "Баланс 5%, история, срок сгорания"],
            ["Админка", "Заявки", "Запись, подтверждение, VIN-заявки"],
            ["Админка", "Чат", "Ответы клиентам, имя менеджера"],
            ["Админка", "Рассылки", "Массовые push / акции"],
        ],
    )

    heading(doc, "16. Архитектура")
    p(doc, "Клиент: Flutter 3.x, iOS + Android. Публикация в App Store, Google Play и RuStore на аккаунтах Исполнителя.", size=10)
    p(doc, "BFF + админка: FastAPI или Nest, PostgreSQL: сессии, журнал заявок, чат, рассылки, кэш, бонусный журнал.", size=10)
    p(doc, "Интеграции: STOCRM API; SMS OTP; FCM / APNs; карты 2ГИС или Яндекс.", size=10)
    p(doc, "Хостинг: VPS РФ. Хостинг и SMS в стоимость разработки не входят.", size=10)

    heading(doc, "17. Не входит")
    bullet(doc, "Замена STOCRM, склад кладовщика, зарплата, приложение для механиков.")
    bullet(doc, "Онлайн-витрина запчастей и остатки склада клиенту (VIN — только заявка менеджеру).")
    bullet(doc, "ОСАГО, маркетплейс АЗС, онлайн-оплата / чеки 54-ФЗ.")
    bullet(doc, "Доработки ядра STOCRM со стороны вендора.")
    bullet(doc, "Хостинг VPS и SMS OTP — отдельно. Отправка push через FCM — без платы за штуку.")

    heading(doc, "18. Нужно от Заказчика")
    bullet(doc, "SID и домен STOCRM, тестовый контакт, соответствие статусов воронки.")
    bullet(doc, "Три филиала: адреса, график, телефоны, координаты, лимиты слотов по дням.")
    bullet(doc, "Ролики для слайдера шортсов (вертикальное видео) или доступ к роликам на сайте.")
    bullet(doc, "Правило бонусов (5%, срок сгорания) и сколько часов до визита можно менять заявку.")
    bullet(doc, "Политика ПДн и согласие на рассылку.")

    heading(doc, "19. Приёмка")
    bullet(doc, "Сборки iOS (TestFlight) и Android; публикация в сторах на аккаунтах Исполнителя.")
    bullet(doc, "При открытии — слайдер шортсов, переход на главную по макету VAG Market.")
    bullet(doc, "OTP на реальном номере; клиент находится по телефону в STOCRM.")
    bullet(doc, "Запись: слоты по филиалам, текст «ожидайте подтверждения», заявка в админке и сделка в CRM.")
    bullet(doc, "История: закрытый ЗН с пробегом, работами и запчастями (если поля есть в API).")
    bullet(doc, "Смена статуса в CRM → статус в приложении и push «Ваша машина готова!».")
    bullet(doc, "Рекомендации из CRM в отдельном разделе.")
    bullet(doc, "Чат: ответ из админки, клиент видит имя менеджера.")
    bullet(doc, "VIN-заявка приходит менеджеру.")
    bullet(doc, "Бонусы 5% по закрытому ЗН, история, push о сгорании (на тестовых данных).")
    bullet(doc, "Массовая push-рассылка из админки на тестовую аудиторию.")
    bullet(doc, "Виджет на Android и iOS меняет состояние «пора в сервис» / «в работе» / «готово».")

    heading(doc, "20. Организация")
    bullet(doc, "Настоящее полное ТЗ v1.1 включено в Приложение № 1 договора № 10092026 и подписывается сторонами (в том числе по ЭДО).")
    bullet(doc, "Оплата частями согласно договору: 40% / 30% / 30%, пакет 260 000 ₽.")
    bullet(doc, "Изменение состава после подписания — доп. соглашение, 2500 ₽/час.")
    p(
        doc,
        "Карта методов STOCRM уточняется после выдачи SID. Онлайн-оплата и витрина склада в эту редакцию не входят.",
        size=9,
        space_before=6,
    )
    signs(doc)


def item(doc, n, text, size=11):
    para = doc.add_paragraph()
    para.paragraph_format.left_indent = Cm(0.75)
    para.paragraph_format.first_line_indent = Cm(-0.75)
    para.paragraph_format.space_after = Pt(4)
    para.paragraph_format.line_spacing = 1.15
    run = para.add_run(f"{n}. {text}")
    set_run(run, size=size)
    return para


def shade(cell, hex_color="F3F4F6"):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), hex_color)
    shd.set(qn("w:val"), "clear")
    tcPr.append(shd)


def set_cell_border(cell):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    tcBorders = OxmlElement("w:tcBorders")
    for edge in ("top", "left", "bottom", "right"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "8")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), "333333")
        tcBorders.append(el)
    tcPr.append(tcBorders)


def v_align_top(cell):
    tc = cell._tc
    tcPr = tc.get_or_add_tcPr()
    vAlign = OxmlElement("w:vAlign")
    vAlign.set(qn("w:val"), "top")
    tcPr.append(vAlign)


def cell_text(cell, text, bold=False, size=10, center=False):
    cell.text = ""
    para = cell.paragraphs[0]
    para.paragraph_format.space_after = Pt(0)
    para.paragraph_format.space_before = Pt(0)
    if center:
        para.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = para.add_run(text)
    set_run(run, size=size, bold=bold)
    v_align_top(cell)
    set_cell_border(cell)


def cell_lines(cell, lines, size=10):
    cell.text = ""
    first = True
    for line in lines:
        if first:
            para = cell.paragraphs[0]
            first = False
        else:
            para = cell.add_paragraph()
        para.paragraph_format.space_after = Pt(1)
        para.paragraph_format.space_before = Pt(0)
        run = para.add_run(line)
        set_run(run, size=size)
    v_align_top(cell)
    set_cell_border(cell)


def style_table(table):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    tbl = table._tbl
    tblPr = tbl.tblPr if tbl.tblPr is not None else OxmlElement("w:tblPr")
    borders = OxmlElement("w:tblBorders")
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "8")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), "333333")
        borders.append(el)
    tblPr.append(borders)


def signs(doc):
    table = doc.add_table(rows=1, cols=2)
    style_table(table)
    # no borders for signatures
    for cell in table.rows[0].cells:
        cell._tc.get_or_add_tcPr()
        tcPr = cell._tc.tcPr
        tcBorders = OxmlElement("w:tcBorders")
        for edge in ("top", "left", "bottom", "right"):
            el = OxmlElement(f"w:{edge}")
            el.set(qn("w:val"), "nil")
            tcBorders.append(el)
        tcPr.append(tcBorders)
    cell_lines(table.rows[0].cells[0], ["Заказчик:", "____________  Гоман П.И."], size=11)
    cell_lines(table.rows[0].cells[1], ["Исполнитель:", "____________  Иванов А.В."], size=11)
    # remove borders visually by empty border already set
    for cell in table.rows[0].cells:
        for p_ in cell.paragraphs:
            for r in p_.runs:
                set_run(r, size=11)


def build():
    doc = Document()
    section = doc.sections[0]
    section.page_width = Cm(21.0)
    section.page_height = Cm(29.7)
    section.left_margin = Cm(2.0)
    section.right_margin = Cm(1.8)
    section.top_margin = Cm(1.6)
    section.bottom_margin = Cm(1.6)

    p(doc, "Договор № 10092026", size=14, bold=True, center=True, space_after=0)
    p(doc, "на разработку мобильного приложения", size=14, bold=True, center=True, space_after=10)

    head = doc.add_table(rows=1, cols=2)
    style_table(head)
    for cell in head.rows[0].cells:
        tcPr = cell._tc.get_or_add_tcPr()
        tcBorders = OxmlElement("w:tcBorders")
        for edge in ("top", "left", "bottom", "right"):
            el = OxmlElement(f"w:{edge}")
            el.set(qn("w:val"), "nil")
            tcBorders.append(el)
        tcPr.append(tcBorders)
    cell_text(head.rows[0].cells[0], "г. Тюмень", size=11)
    cell_text(head.rows[0].cells[1], "«10» сентября 2026 г.", size=11)
    head.rows[0].cells[1].paragraphs[0].alignment = WD_ALIGN_PARAGRAPH.RIGHT

    p(
        doc,
        "Индивидуальный предприниматель Иванов Александр Викторович, действующий на основании Свидетельства "
        "(именуемый в дальнейшем Исполнитель), с одной стороны, и Индивидуальный предприниматель Гоман Павел Игоревич, "
        "действующий на основании Свидетельства серия 72 № 002297797 от 21.04.2014, выданного Межрайонной ИФНС № 14 "
        "по Тюменской области (именуемый в дальнейшем Заказчик), вместе именуемые Стороны, заключили настоящий договор "
        "о нижеследующем.",
        space_after=8,
    )

    heading(doc, "1. Предмет договора")
    item(
        doc,
        "1.1",
        "Заказчик поручает, а Исполнитель принимает на себя обязательства разработать мобильное приложение Заказчика "
        "(iOS и Android, Flutter) с интеграцией в CRM STOCRM согласно полному Техническому заданию, "
        "изложенному в Приложении № 1 к настоящему договору, "
        "и разместить его в магазинах приложений на аккаунтах Исполнителя.",
    )
    item(
        doc,
        "1.2",
        "Заказчик обязуется принять и оплатить выполненные работы в соответствии с условиями настоящего Договора.",
    )

    heading(doc, "2. Порядок выполнения договора")
    item(
        doc,
        "2.1",
        "Заказчик обязуется предоставить всю необходимую для работы информацию, включая SID и домен STOCRM, "
        "справочник услуг, филиалы, логотип и тексты.",
    )
    item(doc, "2.2", "Сроки и стоимость выполнения работ представлены в календарном плане (Приложение № 2).")
    item(doc, "2.3", "Исполнитель имеет право выполнить работы досрочно.")
    item(doc, "2.4", "Исполнитель обязуется не разглашать сведения, полученные от Заказчика.")
    item(
        doc,
        "2.5",
        "Исполнитель обязуется разместить приложение в магазинах приложений "
        "(Apple App Store, Google Play, RuStore) на своих аккаунтах.",
    )
    item(doc, "2.6", "Если задачи не выполнены в полном объёме, предоплата (п. 4.2) возвращается Заказчику.")
    item(doc, "2.7", "Любые изменения в ТЗ могут быть приняты дополнительным соглашением, подписанным обеими сторонами.")
    item(
        doc,
        "2.8",
        "До полного расчёта по договору приложение остаётся размещённым на аккаунтах Исполнителя.",
    )
    item(
        doc,
        "2.9",
        "Любое изменение технического задания может повлечь изменение стоимости проекта из расчёта 2500 рублей в час "
        "и оговаривается дополнительным соглашением, которое будет являться неотъемлемой частью настоящего договора.",
    )

    heading(doc, "3. Общие условия. Права на результаты работ")
    item(
        doc,
        "3.1",
        "Куратором является работник Стороны (или сама Сторона) или иное уполномоченное лицо. "
        "Список кураторов утверждается в Приложении № 3.",
    )
    item(
        doc,
        "3.2",
        "Стороны признают, что Информационная система (мобильное приложение, серверная часть, исходный код, дизайн) "
        "охраняется законодательством об интеллектуальной собственности. Исключительное право на Информационную систему, "
        "созданную по настоящему Договору, принадлежит Заказчику (п. 1 ст. 1296 ГК РФ) с момента подписания Акта сдачи-приёмки работ.",
    )
    item(
        doc,
        "3.3",
        "Исполнитель отчуждает Заказчику имущественные права на все результаты интеллектуальной деятельности, "
        "созданные при выполнении задания, в полном объёме с момента создания при условии подписания Акта.",
    )
    item(
        doc,
        "3.4",
        "Исполнитель гарантирует, что результаты работ не являются предметом залога, ареста или иного обременения "
        "и не нарушают права третьих лиц.",
    )
    item(
        doc,
        "3.5",
        "Заказчик гарантирует, что является обладателем прав на предоставляемые материалы (логотип, тексты, товарные знаки).",
    )
    item(
        doc,
        "3.6",
        "Исполнитель обязуется не использовать созданную систему либо её модули в прямом либо адаптированном виде "
        "без согласования с Заказчиком.",
    )
    item(
        doc,
        "3.7",
        "В случае претензий третьих лиц, связанных с нарушением Исполнителем п. 3, Исполнитель урегулирует их "
        "своими силами и за свой счёт.",
    )

    heading(doc, "4. Стоимость работ и порядок оплаты")
    item(
        doc,
        "4.1",
        "Стоимость работ указана в Приложении № 2 и составляет 260 000 (двести шестьдесят тысяч) рублей 00 копеек. "
        "НДС не облагается в связи с применением Исполнителем специального налогового режима.",
    )
    item(
        doc,
        "4.2",
        "Порядок оплаты: 40% (104 000 ₽) — предоплата в течение 3 банковских дней с даты подписания договора; "
        "30% (78 000 ₽) — после демонстрации записи из приложения в боевую STOCRM Заказчика; "
        "30% (78 000 ₽) — до подписания Акта приёмки работ и передачи сборок / исходного кода.",
    )
    item(
        doc,
        "4.3",
        "Оплата производится безналичным перечислением на счёт Исполнителя. Плательщиками могут выступать третьи лица.",
    )
    item(
        doc,
        "4.4",
        "Окончательный расчёт по договору производится до передачи кодов, доступов и сборок приложения.",
    )

    heading(doc, "5. Ответственность сторон")
    item(
        doc,
        "5.1",
        "Стороны содержат коммерческую тайну и иную информацию, полученную в рамках договора, в условиях конфиденциальности.",
    )
    item(
        doc,
        "5.2",
        "При просрочке оплаты Заказчик уплачивает неустойку 0,1% от суммы соответствующих работ за каждый день просрочки, но не более 2%.",
    )
    item(
        doc,
        "5.3",
        "При нарушении Исполнителем срока работ он уплачивает Заказчику неустойку 0,1% от суммы соответствующих работ за каждый день просрочки, но не более 2%.",
    )
    item(
        doc,
        "5.4",
        "При неоплате в указанные сроки Исполнитель вправе приостановить работы до погашения задолженности. "
        "Срок работ увеличивается на время задержки оплаты.",
    )
    item(
        doc,
        "5.5",
        "Если работы выполнены с нарушением условий договора, Заказчик вправе требовать безвозмездного устранения недостатков "
        "в разумный срок. Гарантия на баги модулей Исполнителя — 30 календарных дней с даты Акта.",
    )
    item(doc, "5.6", "По вопросам, не урегулированным договором, стороны руководствуются ГК РФ.")

    heading(doc, "6. Срок действия договора")
    item(
        doc,
        "6.1",
        "Сроки выполнения работ указаны в Приложении № 2: ориентир — 4 недели со дня поступления предоплаты.",
    )
    item(
        doc,
        "6.2",
        "Договор вступает в силу со дня подписания обеими Сторонами и действует до выполнения обязательств.",
    )
    item(doc, "6.3", "Стороны подписывают каждый лист договора и приложений.")
    item(
        doc,
        "6.4",
        "Договор составлен в двух экземплярах на русском языке, по одному для каждой стороны.",
    )

    heading(doc, "7. Реквизиты сторон")
    req = doc.add_table(rows=2, cols=2)
    style_table(req)
    cell_text(req.rows[0].cells[0], "Исполнитель", bold=True, size=11, center=True)
    cell_text(req.rows[0].cells[1], "Заказчик", bold=True, size=11, center=True)
    shade(req.rows[0].cells[0])
    shade(req.rows[0].cells[1])
    cell_lines(
        req.rows[1].cells[0],
        [
            "ИП Иванов Александр Викторович",
            "Телефон: +7 913 914-29-94",
            "Почта: admin@qwerti.ru",
            "Сайт: https://www.app72.ru",
            "Фактический адрес: 625007, Тюменская обл., г. Тюмень, ул. Широтная, д. 21а",
            "ИНН: 540216807580",
            "ОГРНИП: 317547600107660",
            "",
            "Р/с: 40802810938390001584",
            "БИК: 046577964",
            "ФИЛИАЛ «ЕКАТЕРИНБУРГСКИЙ» АО «АЛЬФА-БАНК», г. Екатеринбург",
            "к/с: 30101810100000000964",
            "",
            "Подпись ____________    Иванов А.В.",
        ],
        size=10,
    )
    cell_lines(
        req.rows[1].cells[1],
        [
            "ИП Гоман Павел Игоревич",
            "Сокращённо: ИП Гоман П.И.",
            "Действует на основании: Свидетельство серия 72 № 002297797 от 21.04.2014,",
            "Межрайонная ИФНС № 14 по Тюменской области",
            "Юридический адрес: 625043, Тюменская область, г. Тюмень, д. Казарово, ул. Новая, д. 75",
            "Фактический адрес: 625049, г. Тюмень, ул. Московский тракт, д. 118/11",
            "ИНН: 720210960834",
            "ОГРНИП: 314723211100145",
            "ОКПО: 0192936115",
            "Р/с: 40802810167100045531",
            "Банк: Западно-Сибирский банк ПАО Сбербанка РФ",
            "к/с: 30101810800000000651",
            "БИК: 047102651",
            "Тел.: (3452) 95-09-80 / 96-50-80",
            "E-mail: vwsk72@mail.ru",
            "Сайт: https://vagmarket72.ru",
            "",
            "Подпись ____________    Гоман П.И.    м.п.",
        ],
        size=10,
    )

    doc.add_page_break()
    add_full_tz(doc)

    doc.add_page_break()
    p(doc, "Приложение № 2 к договору № 10092026", size=13, bold=True, center=True, space_after=0)
    p(doc, "от «10» сентября 2026 г.", size=12, bold=True, center=True, space_after=8)
    heading(doc, "Календарный план и стоимость")

    cal = doc.add_table(rows=6, cols=3)
    style_table(cal)
    headers = ["Неделя", "Работы", "Сумма"]
    for i, h in enumerate(headers):
        cell_text(cal.rows[0].cells[i], h, bold=True, size=10, center=True)
        shade(cal.rows[0].cells[i])

    cell_text(cal.rows[1].cells[0], "1", center=True, size=10)
    cell_text(cal.rows[1].cells[1], "Карта API STOCRM, бренд UI, BFF, OTP, гараж, запись → админка + сделка", size=10)
    cell_text(cal.rows[1].cells[2], "175 000 ₽", center=True, size=10)

    cell_text(cal.rows[2].cells[0], "2", center=True, size=10)
    cell_text(cal.rows[2].cells[1], "3 филиала и карта, история ЗН, статусы, push «машина готова»", size=10)

    cell_text(cal.rows[3].cells[0], "3", center=True, size=10)
    cell_text(cal.rows[3].cells[1], "Чат + имя менеджера, VIN, бонусы 5%, рекомендации, TestFlight / APK", size=10)

    cal.rows[1].cells[2].merge(cal.rows[3].cells[2])
    # re-apply text after merge
    cell_text(cal.rows[1].cells[2], "175 000 ₽", center=True, size=10)

    cell_text(cal.rows[4].cells[0], "4", center=True, size=10)
    cell_text(cal.rows[4].cells[1], "Массовые рассылки, виджет, поиск, полировка, публикация в сторах", size=10)
    cell_text(cal.rows[4].cells[2], "85 000 ₽", center=True, size=10)

    cal.rows[5].cells[0].merge(cal.rows[5].cells[1])
    cell_text(cal.rows[5].cells[0], "Итого", bold=True, size=10)
    cell_text(cal.rows[5].cells[2], "260 000 ₽", bold=True, center=True, size=10)
    shade(cal.rows[5].cells[0])
    shade(cal.rows[5].cells[2])

    p(
        doc,
        "Срок разработки: ориентир 4 недели со дня поступления предоплаты. Исполнитель вправе выполнить работы досрочно.",
        space_before=8,
    )
    p(
        doc,
        "Оплата: 40% (104 000 ₽) — старт; 30% (78 000 ₽) — демо записи в STOCRM; 30% (78 000 ₽) — до Акта и передачи сборок.",
    )
    p(doc, "Изменение ТЗ: 2500 ₽/час по дополнительному соглашению.")
    p(doc, "При задержке оплаты Заказчиком срок работ увеличивается на время задержки.")
    p(
        doc,
        "Исполнитель размещает приложение в App Store, Google Play и RuStore на своих аккаунтах "
        "(п. 2.5 договора). Хостинг, SMS и push в сумму Приложения № 2 не входят "
        "и оплачиваются Заказчиком отдельно.",
    )
    signs(doc)

    doc.add_page_break()
    p(doc, "Приложение № 3 к договору № 10092026", size=13, bold=True, center=True, space_after=0)
    p(doc, "от «10» сентября 2026 г.", size=12, bold=True, center=True, space_after=8)
    heading(doc, "Список кураторов сторон")
    p(doc, "г. Тюмень                    «10» сентября 2026 г.")

    p(doc, "Куратор со стороны Заказчика", bold=True, space_before=8)
    t1 = doc.add_table(rows=3, cols=3)
    style_table(t1)
    for i, h in enumerate(["№", "Ф.И.О.", "Отметки о прекращении полномочий"]):
        cell_text(t1.rows[0].cells[i], h, bold=True, size=10, center=True)
        shade(t1.rows[0].cells[i])
    cell_text(t1.rows[1].cells[0], "1", center=True, size=10)
    cell_text(t1.rows[1].cells[1], "Гоман Павел Игоревич", size=10)
    cell_text(t1.rows[1].cells[2], "", size=10)
    cell_text(t1.rows[2].cells[0], "2", center=True, size=10)
    cell_text(t1.rows[2].cells[1], "", size=10)
    cell_text(t1.rows[2].cells[2], "", size=10)

    p(doc, "Куратор со стороны Исполнителя", bold=True, space_before=12)
    t2 = doc.add_table(rows=3, cols=3)
    style_table(t2)
    for i, h in enumerate(["№", "Ф.И.О.", "Отметки о прекращении полномочий"]):
        cell_text(t2.rows[0].cells[i], h, bold=True, size=10, center=True)
        shade(t2.rows[0].cells[i])
    cell_text(t2.rows[1].cells[0], "1", center=True, size=10)
    cell_text(t2.rows[1].cells[1], "Иванов Александр Викторович", size=10)
    cell_text(t2.rows[1].cells[2], "", size=10)
    cell_text(t2.rows[2].cells[0], "2", center=True, size=10)
    cell_text(t2.rows[2].cells[1], "", size=10)
    cell_text(t2.rows[2].cells[2], "", size=10)

    p(doc, "", space_before=16)
    signs(doc)

    doc.save(OUT)
    print("saved", OUT)


if __name__ == "__main__":
    build()
