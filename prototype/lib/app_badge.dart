import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter/foundation.dart';

Future<void> syncAppIconBadge(int count) async {
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.iOS && defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  try {
    final n = count < 0 ? 0 : count;
    if (n == 0) {
      await AppBadgePlus.updateBadge(0);
    } else {
      await AppBadgePlus.updateBadge(n);
    }
  } catch (_) {}
}
