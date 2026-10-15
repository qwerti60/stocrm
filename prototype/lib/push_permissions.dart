import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Запрос уведомлений на iOS (появляется пункт в «Настройки → приложение»).
/// Не зависит от Firebase — plist нужен отдельно для FCM-токена.
Future<void> ensureIosNotificationRegistration() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
  try {
    await Permission.notification.request();
  } catch (_) {}
}

Future<void> openSystemAppSettings() async {
  try {
    await openAppSettings();
  } catch (_) {}
}
