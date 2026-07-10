import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_notification.dart';
import '../../core/providers/app_providers.dart';

final notificationsListProvider = StateNotifierProvider.autoDispose<
    NotificationsListNotifier, AsyncValue<NotificationListResult>>((ref) {
  return NotificationsListNotifier(ref);
});

final notificationsMarkingAllProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Unread notification count for badges on More tab and menu.
final notificationUnreadCountProvider = FutureProvider<int>((ref) async {
  final token = ref.watch(authTokenProvider);
  if (token == null || token.isEmpty) return 0;

  final listState = ref.watch(notificationsListProvider);
  final cached = listState.valueOrNull;
  if (cached != null) return cached.unreadCount;

  try {
    final result = await ref
        .read(radioudaanApiProvider)
        .listNotifications(perPage: 1);
    return result.unreadCount;
  } catch (_) {
    return 0;
  }
});

class NotificationsListNotifier
    extends StateNotifier<AsyncValue<NotificationListResult>> {
  NotificationsListNotifier(this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(
      () => _ref.read(radioudaanApiProvider).listNotifications(),
    );
  }

  Future<void> markRead(int id) async {
    if (id < 1) return;

    final current = state.valueOrNull;
    final index = current?.items.indexWhere((item) => item.id == id) ?? -1;

    if (current == null || index < 0) {
      try {
        await _ref.read(radioudaanApiProvider).markNotificationRead(id);
        _ref.invalidate(notificationUnreadCountProvider);
      } catch (_) {}
      return;
    }

    final item = current.items[index];
    if (item.isRead) return;

    final previous = current;
    final updatedItems = List<AppNotification>.from(current.items);
    updatedItems[index] = item.asRead();
    state = AsyncValue.data(
      current.copyWith(
        items: updatedItems,
        unreadCount: current.unreadCount > 0 ? current.unreadCount - 1 : 0,
      ),
    );
    _ref.invalidate(notificationUnreadCountProvider);

    try {
      await _ref.read(radioudaanApiProvider).markNotificationRead(id);
    } catch (_) {
      state = AsyncValue.data(previous);
      _ref.invalidate(notificationUnreadCountProvider);
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null || current.unreadCount <= 0) return;

    _ref.read(notificationsMarkingAllProvider.notifier).state = true;
    final previous = current;
    final updatedItems =
        current.items.map((item) => item.asRead()).toList(growable: false);
    state = AsyncValue.data(
      current.copyWith(items: updatedItems, unreadCount: 0),
    );
    _ref.invalidate(notificationUnreadCountProvider);

    try {
      await _ref.read(radioudaanApiProvider).markAllNotificationsRead();
    } catch (_) {
      state = AsyncValue.data(previous);
      _ref.invalidate(notificationUnreadCountProvider);
    } finally {
      _ref.read(notificationsMarkingAllProvider.notifier).state = false;
    }
  }
}

void invalidateNotificationBadges(WidgetRef ref) {
  ref.invalidate(notificationUnreadCountProvider);
  ref.read(notificationsListProvider.notifier).refresh();
}
