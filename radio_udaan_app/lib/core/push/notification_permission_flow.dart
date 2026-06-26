import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../storage/settings_storage.dart';
import '../../features/radio/android_media_notification_permission.dart';
import '../../features/radio/radio_audio_service.dart';
import 'notification_permission_prompt_sheet.dart';
import 'push_notification_service.dart';

/// One-time notification permission prompt on first app open (push + Android media).
abstract final class NotificationPermissionFlow {
  static bool _promptVisible = false;

  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    if (kIsWeb || _promptVisible) return;

    final storage = await SettingsStorage.create();
    if (storage.notificationPermissionPromptSeen) return;

    _promptVisible = true;
    try {
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => NotificationPermissionPromptSheet(
        onContinue: () async {
          await storage.setNotificationPermissionPromptSeen();
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
          await _requestPermissions(ref);
        },
        onNotNow: () async {
          await storage.setNotificationPermissionPromptSeen();
          if (sheetContext.mounted) {
            Navigator.of(sheetContext).pop();
          }
        },
      ),
    );
    } finally {
      _promptVisible = false;
    }
  }

  static Future<void> _requestPermissions(WidgetRef ref) async {
    await requestAndroidMediaNotificationPermissionIfNeeded();

    final push = ref.read(pushNotificationServiceProvider);
    await push.initialize();
    await push.requestSystemPermission();

    final token = ref.read(authTokenProvider);
    if (token != null && token.isNotEmpty) {
      await push.registerDeviceToken();
    }

    await ensureRadioAudioService();
  }
}
