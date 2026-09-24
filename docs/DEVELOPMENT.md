# VAG Market · журнал и документация по коду

Обновлено 20.09.2026. Договор № 10092026, ТЗ v1.1. SID **не** хранить в git и не вшивать в APK.

Смежные документы: [хаб](index.html) · [QA](qa.html) · [менеджеру](manager-guide.html) · [пользователю](user-guide.html) · [план](../plan.html)

---

## Статус

**Неделя 1 (запись в CRM) — критерий закрыт по API.** Сделка `offer_id=116944` создана в воронке 1097 с тестового контакта 1240177.

**Неделя 2 (слоты, история, статусы, push) — в коде.** Слоты из `calendar/card/get` по `CUSTOMER_ID` филиала. История/воронка на `GET /v1/visits`. Poller ~90 сек → inbox «Ваша машина готова!». FCM — когда Заказчик даст `FCM_SERVER_KEY`. Карта филиалов — пины по `ADDRESS_JSON` CRM, маршрут в 2ГИС / Яндекс.

Сделано:

- Прототип Flutter под бренд VAG Market (`#E10613` / `#0B0B0D`).
- BFF FastAPI, SID только в `server/.env`.
- Боевой кабинет `vagnihaomarket.stocrm.ru`, воронка записи `BOARD_ID=1097`.
- OTP на **email** (CRM-свойство `PROP_TYPE_ID=2`). Нет почты у старого контакта — спрашиваем и пишем в CRM + JSON `phone↔email`. Новый клиент: `contact/create`. Гараж: `contact/add_car` / удаление из приложения.
- OTP 1234, пока SMTP не задан → контакт по `MAIN_PHONE`, гараж/филиалы/визиты с BFF.
- `POST /v1/bookings` → `offer/new` (без авто, если гараж пустой).
- Приложение: запись не врёт «успех», если CRM не принял; адреса с `GET /v1/branches`.
- Слоты записи: `GET /v1/slots?branch_id=&date=` (часы 09–21 / сб-вс 10–18 MSK, занятость постов).
- Визиты: `is_history` / `is_ready` / `steps` / работы из `work/get_filtered`.
- Poller статусов + `GET /v1/notifications`, тест `POST /v1/notifications/test`.
- Адреса: ссылка 2ГИС и звонок.

**Неделя 3 (чат, VIN, бонусы, рекомендации) — в коде.** Админка `/admin/`. Чат и VIN в JSON на сервере. Бонусы 5% с ЗН «Успешно реализовано» (пересчёт из CRM). Рекомендации из открытых работ CRM.

**Неделя 4 (рассылки, виджет, сторы) — в коде.** Массовый/сегментный push из `/admin/` в inbox (+ FCM если ключ). Лента акций = те же кампании. Шортсы с `/v1/shorts`. Виджет Android. Поиск по авто/визитам/филиалам. Политика ПДн `/privacy.html`. Подача в сторы ждёт аккаунты.

**Сторы:** листинг `docs/store.html`. Нет Apple/Google/RuStore аккаунтов Исполнителя — заявки не отправлены.

---

## Архитектура

```
Flutter (prototype/)
    │  HTTP, без SID
    ▼
BFF FastAPI (server/)     ← SID, BOARD_ID, нормализация телефона
    │  POST JSON { SID, … }
    ▼
STOCRM Public API v1
https://vagnihaomarket.stocrm.ru/api/external/v1/{method}
```

Клиент не ходит в STOCRM напрямую. Сессии BFF — in-memory (после рестарта сервера токены сгорают). PostgreSQL в неделе 1 не нужен: сделки пишутся сразу в CRM.

---

## Дерево кода

| Путь | Зачем |
| --- | --- |
| `prototype/lib/main.dart` | Оболочка: шортсы → OTP → 6 вкладок |
| `prototype/lib/theme.dart` | Цвета бренда |
| `prototype/lib/data/api.dart` | HTTP-клиент. Android emulator: `http://10.0.2.2:8080` |
| `prototype/lib/data/mock.dart` | Состояние UI + вызовы BFF с fallback на мок |
| `prototype/lib/screens/*.dart` | Экраны прототипа |
| `server/app/config.py` | `.env` → `Settings` |
| `server/app/stocrm.py` | Обёртка Public API, разбор `RESPONSE.DATA` |
| `server/app/main.py` | REST BFF `/v1/*` |
| `server/app/slots.py` | Свободные часы по календарю постов |
| `server/app/store.py` | Чат, VIN, бонусный журнал (JSON) |
| `server/app/admin.html` | Админка менеджера |
| `server/probe.py` | Карта методов на боевом SID |
| `server/.env` | Секреты, в `.gitignore` |
| `server/.env.example` | Шаблон без SID |

Экраны: `shorts` → `auth` → `home` / `garage` / `book`+`booking_flow` / `branches` / `chat` / `profile`. Дополнительно: `visits`, `status`, `vin`, `recommendations` (открываются с главной/профиля).

---

## BFF API

База локально: `http://127.0.0.1:8080`

| Метод | Назначение |
| --- | --- |
| `GET /health` | домен, `sid_set`, `board_id` (без самого SID) |
| `GET /internal/stocrm/probe` | карта методов, **не отдавать клиенту** |
| `POST /v1/auth/lookup` | `{phone}` → есть ли контакт и email в CRM |
| `POST /v1/auth/otp/request` | `{phone, email?}` → код на почту (без SMTP — `1234`) |
| `POST /v1/auth/otp/confirm` | `{phone,code,email?}` → Bearer; новый контакт `contact/create`, email `PROP ACTION CREATE` |
| `GET /v1/me` | телефон, email, имя, contact_id |
| `GET /v1/garage` | авто контакта (без SOLD и скрытых) |
| `POST /v1/garage` | добавить авто `contact/add_car` |
| `DELETE /v1/garage/{id}` | убрать из гаража (скрыть + попытка SOLD в CRM) |
| `GET /v1/visits` | сделки контакта на доске 1097, работы, воронка, `is_ready` / `is_history` |
| `GET /v1/branches` | активные филиалы CRM: адрес из `ADDRESS_JSON`, `lat`/`lng`, 2ГИС и Яндекс |
| `GET /v1/slots` | свободные часы филиала (`branch_id`, `date=YYYY-MM-DD`) |
| `POST /v1/bookings` | `offer/new` (нужен `contact_id`, иначе 409) |
| `GET /v1/notifications` | inbox poller («машина готова», чат, сгорание бонусов) |
| `POST /v1/notifications/test` | QA: имитация пуша без смены статуса |
| `POST /v1/devices` | опциональный `fcm_token` |
| `GET/POST /v1/chat` | переписка клиента с менеджером |
| `POST /v1/vin` | заявка на подбор запчасти (не склад) |
| `GET /v1/bonuses` | 5% с ЗН «Успешно реализовано» во всех воронках |
| `GET /v1/recommendations` | открытые работы / ТО из CRM |
| `GET /v1/promos` | лента акций (те же, что рассылка) |
| `GET /v1/shorts` | слайдер шортсов (публичный) |
| `GET /v1/search?q=` | свои авто, визиты, филиалы, услуги |
| `GET /v1/widget` | состояние виджета: ok / due / service / ready |
| `/admin/` | чат, VIN, **рассылки**, шортсы |

Телефон нормализуется к `7XXXXXXXXXX` (`8…` → `7…`). Ответ CRM «контакты не найдены» считается пустым списком, а не аварией.

Запись: `CONTACT_ID`, `BOARD_ID=1097`, `COMMENT`, опционально `CAR_PROFILE_ID` и `CUSTOMER_ID` (филиал). `SOURCE_ID` не задан, пока Заказчик не заведёт источник «Онлайн-запись».

---

## Карта STOCRM (снята 16.09.2026)

База: `https://vagnihaomarket.stocrm.ru/api/external/v1`

| Метод | Результат |
| --- | --- |
| `contacts/get_from_filter` | ок, `MAIN_PHONE` |
| `contact/get_info` | ок, свойства (телефоны = `PROP_TYPE_ID=1`) |
| `car_profile/get_filtered_profiles` | ок, фильтр `CONTACT_ID` |
| `offers/get_from_filter` | ок. **`offer/get_from_filter` = URI 666** |
| `offer/new` | создание сделки (в probe не дергаем) |
| `offer/all_statuses` | ок при `BOARD_ID=1097` |
| `work/get_filtered` | ок |
| `calendar/post/get_filtered` | ок, посты с `CUSTOMER_ID`, `DATE_FROM`/`DATE_TO` |
| `calendar/card/get` | ок, нужен реальный `CUSTOMER_ID` филиала |
| `shift/get_filtered` | ок |
| `customers/get_filtered` | ок, 9 юнитов (7 активных) |
| `legal_entities/get_from_filter` | ок |

Статусы воронки 1097: Неразобранное (1) → Заказ детали → В работе сервис → Выполнен → Думает → В ожидании → Записан в сервис → Записан в сервис готов раньше → Не приехал → Успешно реализовано / Отказ / Мусор.

Из приложения сделка падает в **Неразобранное**.

Активные филиалы (`CUSTOMER_ID`): 2107 NIN HAO MARKET · 2109 VAG DTL Республика · 2113 VAG MARKET · 2115 Bruno Detailing · 2117 Komfort · 6913 NINHAO Дружбы 66 · 6917 Эрвье.

---

## Запуск

```bash
# BFF
cd server
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # вписать STOCRM_SID
uvicorn app.main:app --host 0.0.0.0 --port 8080
python probe.py
```

Сайт с того же процесса: `/` документы, `/app/` веб-клиент, `/apk/` сборки, `/health` API.

VPS: `dist/vagmarket-deploy.tar.gz` + `deploy/bootstrap.sh`. SID только в `.env` на сервере, не в архиве.

```bash
# Flutter
cd prototype
flutter pub get
flutter run -d chrome
# Android emulator: API_BASE уже 10.0.2.2:8080
```

OTP прототипа: **1234**, пока в `.env` нет `SMTP_HOST`. Код уходит на email из CRM (`PROP_TYPE_ID=2`). Если почты нет — приложение просит её и пишет в карточку контакта.

Если BFF не запущен, вход с кодом 1234 остаётся на мок-данных (auth ловит ошибку сети).

---

## Что ещё не закрыто

- Реальная отправка писем — SMTP в админке «Почта» (`/admin/`) или `SMTP_*` в `.env`. Без него код 1234. На VPS исходящий :25 закрыт, нужен ящик Mail.ru/Яндекс на 465/587.
- Жёсткое удаление авто в CRM: Public API даёт `contact/add_car`, `car/edit` без рабочего DELETE; приложение скрывает карточку и пытается `SOLD`.
- Реальный FCM/APNs без `FCM_SERVER_KEY`.
- Жёсткая бронь поста в календаре CRM.
- PostgreSQL (чат/рассылки/связки phone↔email в `server/data/week3.json`).
- Виджет iOS (WidgetKit) — нет аккаунта Apple и движков iOS на этой машине.
- Подача в App Store / Play / RuStore — нет аккаунтов разработчика.

Тестовый контакт **1240177**: email в CRM как свойство типа E-Mail, гараж через `contact/add_car`.

---

## Безопасность

- SID только `server/.env`, файл в `.gitignore`.
- `/v1/garage` и `/v1/visits` не отдают сырой CRM (телефоны сотрудников, `PASSWORD` пользователей, адреса владельца).
- `users/get_from_filter` в probe не вызываем (в ответе CRM бывает поле пароля).
- `contact/new` и `offer/new` в probe не создаём.

---

## Как проверять CRM без приложения

```bash
curl -s http://127.0.0.1:8080/health
# OTP → token → GET /v1/garage
```

Новая тестовая сделка появится в кабинете: `https://vagnihaomarket.stocrm.ru/leads/[board=1097]` в колонке «Неразобранное».
