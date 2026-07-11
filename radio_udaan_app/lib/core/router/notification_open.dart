import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../features/more/notification_detail_screen.dart';
import '../../features/more/notifications_providers.dart';
import '../api/radioudaan_api.dart';
import '../models/app_notification.dart';
import '../router/app_router.dart';

/// Opens notification detail after a system / local notification tap.
/// Hydrates via GET when only id is known (same detail as More → Notifications).
///
/// Retries until [rootNavigatorKey] has a mounted context (cold start), then
/// pushes detail. If GET fails, still opens with title/body from the push payload.
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

  final resolvedTitle = (title ?? data['title']?.toString() ?? '').trim();
  final resolvedBody = (body ?? data['body']?.toString() ?? '').trim();

  AppNotification? notification;

  if (id > 0) {
    try {
      notification = await api.getNotification(id);
      if (!notification.isRead) {
        try {
          await api.markNotificationRead(id);
          notification = notification.asRead();
        } catch (_) {}
      }
    } catch (_) {
      // Fall through to synthetic notification from push data.
    }
  }

  final navContext = await waitForRootNavigatorContext();
  if (navContext == null || !navContext.mounted) return;

  if (notification != null) {
    Navigator.of(navContext).push(
      MaterialPageRoute<void>(
        builder: (_) => NotificationDetailScreen(notification: notification!),
      ),
    );
    refreshNotificationInboxFromNav();
    return;
  }

  // Prefer payload copy when API failed or id unknown; keep id when known.
  if (resolvedTitle.isEmpty && resolvedBody.isEmpty) {
    refreshNotificationInboxFromNav();
    return;
  }

  if (!navContext.mounted) return;
  Navigator.of(navContext).push(
    MaterialPageRoute<void>(
      builder: (_) => NotificationDetailScreen(
        notification: AppNotification(
          id: id,
          type: data['type']?.toString() ?? 'general',
          title: resolvedTitle.isNotEmpty ? resolvedTitle : 'Notification',
          body: resolvedBody,
          isRead: true,
          createdAt: DateTime.now().toUtc().toIso8601String(),
          data: data,
        ),
      ),
    ),
  );
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
