# Push-уведомления на iPhone (TestFlight)

Android уже регистрирует FCM-токен при входе. Для iOS нужны три шага в Firebase и Apple.

## 1. Firebase — iOS-приложение

1. [Firebase Console](https://console.firebase.google.com) → проект приложения (тот же, что для Android).
2. **Add app** → iOS, Bundle ID: `ru.app72.stocrmMobileApp`.
3. Скачать **GoogleService-Info.plist** → положить в `prototype/ios/Runner/GoogleService-Info.plist`.
4. В Xcode (Runner) убедиться, что plist добавлен в target **Runner** (Copy Bundle Resources).

## 2. Apple — ключ APNs

1. [Apple Developer](https://developer.apple.com/account/resources/authkeys/list) → **Keys** → создать ключ с **Apple Push Notifications service (APNs)**.
2. Скачать `.p8`, запомнить **Key ID** и **Team ID**.

## 3. Firebase — загрузка APNs

1. Firebase → Project settings → **Cloud Messaging** → **Apple app configuration**.
2. Загрузить `.p8`, указать Key ID и Team ID.

## 4. Xcode / Codemagic

- В Xcode: **Signing & Capabilities** → **Push Notifications** (+ **Background Modes** → Remote notifications, если ещё нет).
- Пересобрать TestFlight в Codemagic (`codemagic.yaml`, `--build-name=1.0.3`).

## 5. Проверка

1. Установить сборку из TestFlight, войти в приложение (токен уйдёт на `POST /v1/devices`).
2. В админке BFF отправить тестовую рассылку на свой номер или ответ в чат — push должен прийти как сообщение (inbox + чат), не в «Спецпредложения».

Если push не приходит: в логах BFF проверить регистрацию устройства; в Firebase → Cloud Messaging — ошибки доставки для iOS.
