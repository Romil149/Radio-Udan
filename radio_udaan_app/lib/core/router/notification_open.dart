import 'package:flutter/material.dart';

import '../../features/more/notification_detail_screen.dart';
import '../../features/more/notifications_screen.dart';
import '../api/radioudaan_api.dart';
import '../models/app_notification.dart';
import '../router/app_router.dart';
import '../router/whats_new_deep_link.dart';

/// Opens inbox or detail after a system / local notification tap.
/// Marks the inbox row read when [notificationId] is known.
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
    } catch (_) {}
  }

  if (isWhatsNewDetailPayload(data)) {
    openWhatsNewDetailFromData(data);
    return;
  }

  final navContext = rootNavigatorKey.currentContext;
  if (navContext == null || !navContext.mounted) return;

  final resolvedTitle = (title ?? data['title']?.toString() ?? '').trim();
  final resolvedBody = (body ?? data['body']?.toString() ?? '').trim();

  if (id > 0 && (resolvedTitle.isNotEmpty || resolvedBody.isNotEmpty)) {
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
    return;
  }

  Navigator.of(navContext).push(
    MaterialPageRoute<void>(
      builder: (_) => const NotificationsScreen(),
    ),
  );
}
