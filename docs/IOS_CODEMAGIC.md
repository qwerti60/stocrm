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

## Upload OK, publish failed: `APP STORE CONNECT API: status code 500`

Сообщение `No errors uploading archive` + затем **500 internal server error** — IPA уже **залит в Apple**, упал следующий вызов API (TestFlight / привязка билда).

**Что делать:**

1. **Перезапустить сборку** — в `codemagic.yaml` шаг **Publish to TestFlight (retries)** делает до 8 попыток; со 2-й использует `--skip-package-upload` (не грузит IPA заново).
2. Проверить [App Store Connect → TestFlight](https://appstoreconnect.apple.com/) — билд может уже **Processing** / **Ready to test** несмотря на красный Codemagic.
3. Если билд есть в ASC — в Codemagic достаточно **Re-run** только failed step или полной сборки (skip-upload сработает на retry).

## Team ID

Distribution-сертификат в Codemagic: **Denis Sumarokov (`C7D47SWZAU`)**.  
В Xcode (`DEVELOPMENT_TEAM`) должен быть тот же **`C7D47SWZAU`**.

При загрузке APNs-ключа в Firebase **Team ID** тоже **`C7D47SWZAU`**, иначе FCM ответит `Invalid APNs credential`.

## `MISSING_EXPORT_COMPLIANCE` и «Failed to publish … beta review»

IPA **уже загружен** (в логе `Processing state: VALID`, `Version: 25`). Codemagic падает на шаге **отправки в TestFlight / beta review**, потому что в App Store Connect не заполнены обязательные поля.

### 1. Export compliance (для уже загруженного билда 25)

1. [App Store Connect → TestFlight](https://appstoreconnect.apple.com/apps/6817341079/testflight/ios) → билд **25** (или тот, что в статусе *Missing Compliance*).
2. Нажать **Manage** / **Provide Export Compliance Information**.
3. Ответ: **No** — приложение использует только стандартное HTTPS-шифрование (или эквивалент «не использует шифрование, не подпадающее под исключения»).

В репозитории в `ios/Runner/Info.plist` добавлен **`ITSAppUsesNonExemptEncryption` = false** — для **следующих** загрузок Apple часто проставляет compliance автоматически.

### 2. Beta App Information (обязательно)

Открыть: [TestFlight → Test Information](https://appstoreconnect.apple.com/apps/6817341079/testflight/test-info)

| Поле | Пример |
|------|--------|
| **Beta App Feedback Email** | `support@vagmarket.ru` или ваш рабочий email |
| **Beta App Review Information** → First Name, Last Name, Phone, Email | контакт того, кто ответит Apple при проверке внешней беты |

Сохранить.

### 3. Не обязательно ждать новую сборку

После пунктов 1–2:

- **Internal Testing:** TestFlight → Internal Testing → **+** → выбрать билд **25** → тестировщики из команды ASC получат сборку без повторной загрузки IPA.
- **Codemagic:** перезапустить упавшую сборку — шаг **Publish to TestFlight** со 2-й попытки пойдёт с **`--skip-package-upload`** (только доведение TestFlight до конца).

### 4. Внешние тестировщики (External Testing)

Нужны заполненные поля из п. 2 + **Submit for Review** для группы External. До этого external state будет `MISSING_*`.

Codemagic **красный** при этом не значит, что IPA пропал — проверяйте ASC, а не только лог CI.
