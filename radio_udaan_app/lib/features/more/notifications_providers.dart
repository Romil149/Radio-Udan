import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_notification.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';

final notificationsListProvider = StateNotifierProvider.autoDispose<
    NotificationsListNotifier, AsyncValue<NotificationListResult>>((ref) {
  return NotificationsListNotifier(ref);
});

final notificationsMarkingAllProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

final notificationsLoadingMoreProvider = StateProvider.autoDispose<bool>(
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
  bool _unreadOnly = false;

  bool get unreadOnly => _unreadOnly;

  Future<void> refresh({bool? unreadOnly}) async {
    if (unreadOnly != null) {
      _unreadOnly = unreadOnly;
    }
    if (!state.hasValue) {
      state = const AsyncValue.loading();
    }
    state = await AsyncValue.guard(
      () => _ref.read(radioudaanApiProvider).listNotifications(
            unreadOnly: _unreadOnly,
          ),
    );
    _ref.invalidate(notificationUnreadCountProvider);
  }

  Future<void> setUnreadFilter(bool unreadOnly) async {
    if (_unreadOnly == unreadOnly) return;
    _unreadOnly = unreadOnly;
    await refresh();
  }

  /// Fetches the next page and appends when `page < totalPages`.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMorePages) return;
    if (_ref.read(notificationsLoadingMoreProvider)) return;

    _ref.read(notificationsLoadingMoreProvider.notifier).state = true;
    try {
      final next = await _ref.read(radioudaanApiProvider).listNotifications(
            page: current.page + 1,
            unreadOnly: _unreadOnly,
          );
      final seen = <int>{};
      final merged = <AppNotification>[];
      for (final item in [...current.items, ...next.items]) {
        if (item.id > 0 && !seen.add(item.id)) continue;
        merged.add(item);
      }
      if (!mounted) return;
      state = AsyncValue.data(
        current.copyWith(
          items: merged,
          page: next.page,
          total: next.total,
          totalPages: next.totalPages,
          unreadCount: next.unreadCount,
        ),
      );
    } catch (_) {
      // Keep current page; user can retry Load more.
    } finally {
      if (mounted) {
        _ref.read(notificationsLoadingMoreProvider.notifier).state = false;
      }
    }
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
      if (_unreadOnly) {
        await refresh();
      }
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

/// Refresh inbox + badge from push handlers without a [WidgetRef].
void refreshNotificationInboxFromNav() {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  container.invalidate(notificationUnreadCountProvider);
  container.read(notificationsListProvider.notifier).refresh();
}
