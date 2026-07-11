import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/models/app_notification.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import 'notification_time_formatter.dart';
import 'notifications_providers.dart';
import 'widgets/notification_list_card.dart';

/// Simple inbox: title + full message list only (top 20).
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static const String routeName = '/notifications';

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _lastAnnouncedError;

  @override
  void initState() {
    super.initState();
    ref.listenManual(notificationsListProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          final message = parseApiError(e).message;
          if (_lastAnnouncedError != message) {
            _lastAnnouncedError = message;
            if (mounted) announce(context, message);
          }
        },
        data: (_) => _lastAnnouncedError = null,
      );
    });
  }

  Future<void> _retry() async {
    await ref.read(notificationsListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final notifications = ref.watch(notificationsListProvider);
    final cached = notifications.valueOrNull;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.screenPadding,
              ),
              child: UdaanAuthTopBar(
                copy: copy,
                title: copy.notificationsTitle,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: _buildBody(
                copy: copy,
                notifications: notifications,
                cached: cached,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody({
    required AppCopy copy,
    required AsyncValue<NotificationListResult> notifications,
    required NotificationListResult? cached,
  }) {
    if (cached != null) {
      return _buildList(copy: copy, result: cached);
    }

    return notifications.when(
      data: (result) => _buildList(copy: copy, result: result),
      loading: () => Center(
        child: Semantics(
          label: copy.notificationsLoading,
          child: CircularProgressIndicator(
            color: context.udaan.primary,
          ),
        ),
      ),
      error: (e, _) {
        final message = parseApiError(e).message;
        return ListView(
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.2,
              child: EmptyState(
                message: message,
                icon: Icons.error_outline,
                actionLabel: copy.retry,
                onAction: _retry,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList({
    required AppCopy copy,
    required NotificationListResult result,
  }) {
    final items = result.items;
    if (items.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.25,
            child: EmptyState(
              icon: Icons.notifications_none_outlined,
              message: copy.notificationsEmpty,
            ),
          ),
        ],
      );
    }

    final accent = context.udaan.onSurfaceVariant;
    return ListView(
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      children: [
        for (var i = 0; i < items.length; i++)
          NotificationListCard(
            key: ValueKey('notif-${items[i].id}-$i'),
            item: items[i],
            copy: copy,
            accent: accent,
            when: formatNotificationRelativeTime(
              items[i].createdAt,
              copy,
            ),
          ),
      ],
    );
  }
}
