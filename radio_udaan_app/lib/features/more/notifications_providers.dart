import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_notification.dart';
import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';

/// Top-20 in-app notification inbox (single page, no load-more).
final notificationsListProvider = StateNotifierProvider.autoDispose<
    NotificationsListNotifier, AsyncValue<NotificationListResult>>((ref) {
  return NotificationsListNotifier(ref);
});

/// Unread count for More tile; works even if inbox never opened.
final notificationUnreadCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
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

class NotificationsListNotifier
    extends StateNotifier<AsyncValue<NotificationListResult>> {
  NotificationsListNotifier(this._ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  final Ref _ref;

  static const int _perPage = 20;

  Future<void> refresh() async {
    // Soft refresh: keep existing items visible — never flash loading.
    final previous = state.valueOrNull;

    try {
      final next = await _ref.read(radioudaanApiProvider).listNotifications(
            perPage: _perPage,
          );
      if (!mounted) return;

      // Never update total/unread while keeping a shorter items list —
      // "Showing N" must match visible rows.
      if (previous == null ||
          previous.items.length != next.items.length ||
          !_sameIdsInOrder(previous.items, next.items)) {
        state = AsyncValue.data(next);
      } else if (previous.unreadCount != next.unreadCount ||
          previous.total != next.total ||
          previous.page != next.page ||
          previous.totalPages != next.totalPages) {
        // Same items in order: reuse list instance (VO-stable) but sync counts.
        state = AsyncValue.data(
          previous.copyWith(
            unreadCount: next.unreadCount,
            total: next.total,
            page: next.page,
            totalPages: next.totalPages,
          ),
        );
      }
      // else: identical — leave state untouched
      _ref.invalidate(notificationUnreadCountProvider);
    } catch (e, st) {
      if (!mounted) return;
      if (previous != null) {
        // Keep showing previous list on soft-refresh failure.
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  static bool _sameIdsInOrder(
    List<AppNotification> a,
    List<AppNotification> b,
  ) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
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
}

/// Refresh inbox + unread badge from push handlers without a [WidgetRef].
void refreshNotificationInboxFromNav() {
  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  final container = ProviderScope.containerOf(context);
  container.invalidate(notificationUnreadCountProvider);
  if (container.exists(notificationsListProvider)) {
    try {
      container.read(notificationsListProvider.notifier).refresh();
    } catch (_) {
      // Provider disposed between exists and read — ignore.
    }
  }
}
