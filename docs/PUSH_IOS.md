# Push-уведомления на iPhone (TestFlight)

Android уже регистрирует FCM-токен при входе. Для iOS нужны три шага в Firebase и Apple.

## 1. Firebase — iOS-приложение

1. [Firebase Console](https://console.firebase.google.com) → проект приложения (тот же, что для Android).
2. **Add app** → iOS, Bundle ID: `ru.app72.stocrmMobileApp`.
3. Скачать **GoogleService-Info.plist** → положить в `prototype/ios/Runner/GoogleService-Info.plist`.
4. В Xcode (Runner) убедиться, что plist добавлен в target **Runner** (Copy Bundle Resources).

## 2. Apple — ключ APNs

Ключ уже создан: **`AuthKey_Z53M239SM5.p8`**

| Поле | Значение |
|------|----------|
| **Key ID** | `Z53M239SM5` |
| **Team ID** | `C7D47SWZAU` (Apple Distribution: Denis Sumarokov — как в Codemagic) |

Локальная копия (не в git): `server/secrets/AuthKey_Z53M239SM5.p8`. Исходник храните только у себя; в репозиторий **не коммитить**.

## 3. Firebase — загрузка APNs (обязательно для push в шторку)

1. [Firebase Console](https://console.firebase.google.com/project/stocrm-edf31/settings/cloudmessaging) → **Project settings** → вкладка **Cloud Messaging**.
2. Блок **Apple app configuration** → приложение **ru.app72.stocrmMobileApp**.
3. **Upload** → файл `AuthKey_Z53M239SM5.p8`.
4. **Key ID:** `Z53M239SM5` · **Team ID:** `C7D47SWZAU` → **Upload** (не путать с другим Team ID в Xcode).

Без этого шага FCM принимает запросы с BFF, но **Apple не доставит** push на iPhone.

## 4. Xcode / Codemagic

- В Xcode: **Signing & Capabilities** → **Push Notifications** (+ **Background Modes** → Remote notifications, если ещё нет).
- Пересобрать TestFlight в Codemagic (`codemagic.yaml`, `--build-name=1.0.3`).

## 5. Apple Developer — capability Push

В [Identifiers](https://developer.apple.com/account/resources/identifiers/list) для `ru.app72.stocrmMobileApp` должна быть включена **Push Notifications**. После этого пересоздать provisioning profile (Codemagic: `fetch-signing-files --create`).

В Xcode-проекте уже есть entitlements (`aps-environment`) и `UIBackgroundModes` → `remote-notification`.

## 6. Codemagic — GoogleService-Info.plist

Файл лежит в репозитории: `prototype/ios/Runner/GoogleService-Info.plist` (проект `stocrm-edf31`, bundle `ru.app72.stocrmMobileApp`). Шаг в `codemagic.yaml` по-прежнему может перезаписать plist из `GOOGLE_SERVICE_INFO_PLIST`, если задан.

Без plist Firebase на iOS не инициализируется — системные push и FCM-токен не работают.

## 7. Проверка

1. Установить **новую** сборку из TestFlight (старые без entitlements не покажут переключатель в iOS).
2. При первом запуске разрешить уведомления в системном диалоге.
3. **Настройки → VAG Market → Уведомления** — должен появиться системный вкл/выкл.
4. Войти в приложение (токен уйдёт на `POST /v1/devices`).
5. В админке BFF — рассылка на свой номер или ответ в чат; push в шторке, не только в inbox.

Если пункта «Уведомления» в настройках iOS нет: приложение ещё не запрашивало разрешение (нет plist / не пересобрали) или пользователь не прошёл диалог.

Если push не приходит: BFF `devices` в `week3.json`, Firebase → Cloud Messaging — ошибки доставки для iOS.

## 8. Бейдж есть, баннеров в шторке нет

На iPhone это **три разных переключателя**:

1. **Настройки → VAG Market → Уведомления** — «Допуск уведомлений» **Вкл.**
2. Там же включите **Экран блокировки**, **Центр уведомлений** и **Баннеры** (стиль «Временные» или «Постоянные»).
3. **Фокусирование / «Не беспокоить»** — разрешите уведомления от VAG Market.

В приложении (сборка **18+**): при открытом приложении баннер дублируется через локальное уведомление; в фоне — через APNs. Если в Firebase Cloud Messaging для iOS была ошибка **`Invalid APNs credential`**, загрузите ключ `.p8` с **Team ID `C7D47SWZAU`**.

Проверка с сервера: админка → рассылка на **89829209223** или `POST /v1/notifications/test` из приложения (после входа).
