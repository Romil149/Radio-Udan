import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../features/more/notifications_providers.dart';
import '../../features/more/notifications_screen.dart';
import '../api/radioudaan_api.dart';
import '../router/app_router.dart';

/// Opens the notifications list after a system / local notification tap.
///
/// Marks the item read when an id is known, waits for [rootNavigatorKey]
/// (cold start), then presents [NotificationsScreen] if it is not already
/// the top route, and refreshes the inbox.
Future<void> openNotificationFromPush({
  required RadioUdaanApi api,
  required Map<String, dynamic> data,
  String? title,
  String? body,
  int? notificationId,
}) async {
  final id = notificationId ??
      int.tryParse(data['notification_id']?.toString() ?? '') ??
      0;

  if (id > 0) {
    try {
      await api.markNotificationRead(id);
    } catch (_) {
      // Best-effort; list refresh still runs below.
    }
  }

  final navContext = await waitForRootNavigatorContext();
  if (navContext == null || !navContext.mounted) return;

  final navigator = Navigator.of(navContext);
  var alreadyOnList = false;
  navigator.popUntil((route) {
    alreadyOnList = route.settings.name == NotificationsScreen.routeName;
    return true; // inspect top only — do not pop
  });

  if (!alreadyOnList && navContext.mounted) {
    navigator.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: NotificationsScreen.routeName),
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  refreshNotificationInboxFromNav();
}

/// Waits for the shell navigator (cold start / before first frame).
Future<BuildContext?> waitForRootNavigatorContext({
  int maxAttempts = 20,
  Duration interval = const Duration(milliseconds: 150),
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) return ctx;

    // Yield to the next frame, then pause briefly before retrying.
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.idle) {
      await binding.endOfFrame;
    } else {
      await Future<void>.delayed(Duration.zero);
      await binding.endOfFrame;
    }
    await Future<void>.delayed(interval);
  }

  final last = rootNavigatorKey.currentContext;
  if (last != null && last.mounted) return last;
  return null;
}
