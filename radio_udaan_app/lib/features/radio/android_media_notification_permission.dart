import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Android 13+ (`POST_NOTIFICATIONS`) so [audio_service] can show the foreground
/// **media playback** notification while live radio plays in the background.
/// Not used for marketing, OTP, or other notification types.
Future<void> requestAndroidMediaNotificationPermissionIfNeeded() async {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }

  final status = await Permission.notification.status;
  if (status.isGranted || status.isLimited) {
    return;
  }

  await Permission.notification.request();
}
