import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_notification.dart';
import '../../core/providers/app_providers.dart';

final notificationsListProvider =
    FutureProvider.autoDispose<NotificationListResult>((ref) async {
  return ref.read(radioudaanApiProvider).listNotifications();
});

/// Unread notification count for badges on More tab and menu.
final notificationUnreadCountProvider = FutureProvider<int>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null || token.isEmpty) return 0;
  try {
    final result = await ref
        .read(radioudaanApiProvider)
        .listNotifications(perPage: 1);
    return result.unreadCount;
  } catch (_) {
    return 0;
  }
});

void invalidateNotificationBadges(WidgetRef ref) {
  ref.invalidate(notificationUnreadCountProvider);
  ref.invalidate(notificationsListProvider);
}
