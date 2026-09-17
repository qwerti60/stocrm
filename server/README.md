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

Клиент (OTP 1234, пока нет SMS):

- `POST /v1/auth/otp/request` `{"phone":"9001234567"}`
- `POST /v1/auth/otp/confirm` `{"phone":"9001234567","code":"1234"}` — ищет контакт по `MAIN_PHONE` (`7XXXXXXXXXX`)
- `GET /v1/garage` — авто контакта
- `GET /v1/visits` — сделки контакта на доске 1097
- `GET /v1/branches` — активные филиалы (`customers/get_filtered`)
- `POST /v1/bookings` — `offer/new` в воронку 1097

## Живая карта Public API

База: `https://vagnihaomarket.stocrm.ru/api/external/v1`

| Метод | Статус |
| --- | --- |
| `contacts/get_from_filter` | ок, поле телефона `MAIN_PHONE` (11 цифр, начинается с 7) |
| `contact/get_info` | ок, `CONTACT_ID` → свойства (телефоны, email, …) |
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
