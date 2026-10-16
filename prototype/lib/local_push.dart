import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin localPush = FlutterLocalNotificationsPlugin();

Future<void> initLocalPush() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android) return;
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  await localPush.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
  if (defaultTargetPlatform == TargetPlatform.android) {
    await localPush
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'vagmarket',
            'VAG Market',
            description: 'Статус авто, чат, акции',
            importance: Importance.high,
          ),
        );
  }
}

Future<void> showBannerPush({required int id, required String title, required String body}) async {
  if (kIsWeb) return;
  if (title.trim().isEmpty) return;
  try {
    await localPush.show(
      id & 0x7fffffff,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'vagmarket',
          'VAG Market',
          channelDescription: 'Статус авто, чат, акции',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
    );
  } catch (_) {}
}
