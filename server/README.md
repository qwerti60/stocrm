# BFF VAG Market

SID только в `server/.env` (файл в `.gitignore`). В приложении ключа нет.

Кабинет: `vagnihaomarket.stocrm.ru`, воронка записи `BOARD_ID=1097`.

Локально:

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # вписать STOCRM_SID
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

Прод (Ubuntu VPS): архив `dist/vagmarket-deploy.tar.gz`, скрипт `deploy/bootstrap.sh`. Nginx: `deploy/nginx-vagmarket.conf`.

Сайт с того же процесса: `/` документы, `/app/` веб-клиент, `/apk/` сборки, `/health` API.

Карта методов:

```bash
cd server && source .venv/bin/activate
python probe.py
```

Клиент (код на email; без SMTP — 1234):

- `POST /v1/auth/lookup` `{"phone":"9139142994"}` — есть ли контакт и почта в CRM
- `POST /v1/auth/otp/request` `{"phone":"9001234567","email":"user@mail.ru"}` — email обязателен, если в CRM его нет
- `POST /v1/auth/otp/confirm` `{"phone":"9001234567","code":"1234"}` — ищет контакт по `MAIN_PHONE`, при регистрации создаёт контакт с телефоном и почтой
- `GET /v1/garage` — авто контакта
- `POST /v1/garage` — добавить авто в CRM (`contact/add_car`)
- `DELETE /v1/garage/{id}` — убрать из гаража
- `GET /v1/visits` — сделки контакта на доске 1097 (история, воронка, работы)
- `GET /v1/slots?branch_id=2113&date=2026-09-21` — свободные часы филиала
- `GET /v1/branches` — активные филиалы (`customers/get_filtered`)
- `POST /v1/bookings` — `offer/new` в воронку 1097
- `GET /v1/promos` — акции (те же, что рассылка)
- `GET /v1/shorts` — слайдер
- `GET /v1/search?q=` — поиск
- `GET /v1/widget` — состояние виджета
- `POST /admin/api/campaigns` — рассылка (пароль админки)

## Живая карта Public API

База: `https://vagnihaomarket.stocrm.ru/api/external/v1`

| Метод | Статус |
| --- | --- |
| `contacts/get_from_filter` | ок, поле телефона `MAIN_PHONE` (11 цифр, начинается с 7) |
| `contact/get_info` | ок, `CONTACT_ID` → свойства (телефоны, email, …) |
| `contact/create` | ок, `PROPERTIES[1][0]` телефон, `[2][0]` email |
| `contact/update` | ок, `PROP: [{ACTION: CREATE/UPDATE, PROP_TYPE_ID, VALUE}]` |
| `contact/add_car` | ок, `CONTACT_ID` + `TITLE` / `LICENSE_PLATE` / `VIN` |
| `car_profile/get_filtered_profiles` | ок, фильтр `CONTACT_ID` |
| `offers/get_from_filter` | ок, **не** `offer/get_from_filter`. Фильтр `BOARD_ID` / `CONTACT_ID` |
| `offer/new` | создание сделки (не дергаем в probe) |
| `offer/all_statuses` | ок, `BOARD_ID=1097` |
| `work/get_filtered` | ок |
| `calendar/post/get_filtered` | ок, слоты/посты с `CUSTOMER_ID`, `DATE_FROM`/`DATE_TO` |
| `calendar/card/get` | ок, нужен реальный `CUSTOMER_ID` филиала |
| `shift/get_filtered` | ок |
| `customers/get_filtered` | ок, филиалы/юниты |
| `legal_entities/get_from_filter` | ок |

Статусы воронки 1097: Неразобранное → Заказ детали → В работе сервис → Выполнен → Думает → В ожидании → Записан в сервис → Записан в сервис готов раньше → Не приехал → Успешно реализовано / Отказ / Мусор.

Для записи из приложения сделка создаётся в «Неразобранное» (`STATUS_ID=1`).
