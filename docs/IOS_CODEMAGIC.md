# iOS сборка Codemagic / TestFlight

## Ошибка `GET …/bundleIds/…/profiles returned 500`

Это **сбой на стороне Apple** (App Store Connect API), не ошибка проекта.

**Что делать:**

1. **Перезапустить сборку** через 30–60 минут — чаще всего проходит со 2–3 попытки.
2. В `codemagic.yaml` уже есть **6 попыток** `fetch-signing-files` с паузой 45 с и `--api-server-error-retries 8`.
3. Если 500 держится сутки:
   - [Developer → Profiles](https://developer.apple.com/account/resources/profiles/list) → создать **App Store** профиль для `ru.app72.stocrmMobileApp` (Push Notifications включены).
   - Загрузить `.mobileprovision` и сертификат в группу **`ios_signing`** в Codemagic (ручная подпись).
4. Статус Apple: [developer.apple.com/system-status](https://developer.apple.com/system-status/).

## Team ID

Distribution-сертификат в Codemagic: **Denis Sumarokov (`C7D47SWZAU`)**.  
В Xcode (`DEVELOPMENT_TEAM`) должен быть тот же **`C7D47SWZAU`**.

При загрузке APNs-ключа в Firebase **Team ID** тоже **`C7D47SWZAU`**, иначе FCM ответит `Invalid APNs credential`.
