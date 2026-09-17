# VAG Market · журнал и документация по коду

Обновлено 16.09.2026. Договор № 10092026, ТЗ v1.1. SID **не** хранить в git и не вшивать в APK.

Смежные документы: [хаб](index.html) · [QA](qa.html) · [менеджеру](manager-guide.html) · [пользователю](user-guide.html) · [план](../plan.html)

---

## Статус

**Неделя 1 (запись в CRM) — критерий закрыт по API.** Сделка `offer_id=116944` создана в воронке 1097 с тестового контакта 1240177.

Сделано:

- Прототип Flutter под бренд VAG Market (`#E10613` / `#0B0B0D`).
- BFF FastAPI, SID только в `server/.env`.
- Боевой кабинет `vagnihaomarket.stocrm.ru`, воронка записи `BOARD_ID=1097`.
- OTP 1234 → контакт по `MAIN_PHONE`, гараж/филиалы/визиты с BFF.
- `POST /v1/bookings` → `offer/new` (без авто, если гараж пустой).
- Приложение: запись не врёт «успех», если CRM не принял; адреса с `GET /v1/branches`.

**Следующий этап — неделя 2:** слоты из календаря постов (`CUSTOMER_ID` филиала), история/статус ЗН в UI, push «машина готова».

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
| `POST /v1/auth/otp/request` | `{phone}` → пока всегда код `1234` |
| `POST /v1/auth/otp/confirm` | `{phone,code}` → Bearer + `contact_id` / `found_in_crm` |
| `GET /v1/me` | телефон, имя, contact_id |
| `GET /v1/garage` | авто контакта (урезанные поля) |
| `GET /v1/visits` | сделки контакта на доске 1097 |
| `GET /v1/branches` | активные филиалы |
| `POST /v1/bookings` | `offer/new` (нужен `contact_id`, иначе 409) |

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

OTP прототипа: **1234**. SMS ещё нет.

Если BFF не запущен, вход с кодом 1234 остаётся на мок-данных (auth ловит ошибку сети).

---

## Что ещё не в коде (неделя 1–2)

- Создание контакта `contact/new`, если номера нет в CRM.
- Добавление авто в гараж (update car profile).
- Экран «Адреса» всё ещё на мок-филиалах, не на `GET /v1/branches`.
- Жёсткие слоты календаря в UI (API постов есть — не подключены).
- Админка заявок, PostgreSQL, FCM/APNs, SMS-провайдер.
- Чат, VIN, бонусы 5%, рассылки, виджет — недели 3–4.

Известный зазор: тестовый контакт **без авто** — гараж с BFF пустой, запись без `car_id` всё равно создаёт сделку.

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
