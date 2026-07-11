import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
import 'settings_screen.dart';
import 'widgets/notification_list_card.dart';

/// In-app notification inbox: scrollable top-20 list from `GET /notifications`.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  static const String routeName = '/notifications';

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String? _lastAnnouncedSignature;
  String? _lastAnnouncedError;

  @override
  void initState() {
    super.initState();
    // listenManual: avoid re-registering every build (VO crash source).
    ref.listenManual(notificationsListProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          _lastAnnouncedError = null;
          _maybeAnnounceSummary(
            copy: ref.read(appCopyProvider),
            shown: result.items.length,
            unread: result.unreadCount,
            total: result.total,
          );
        },
        error: (e, _) {
          final message = parseApiError(e).message;
          if (_lastAnnouncedError != message) {
            _lastAnnouncedError = message;
            _announce(message);
          }
        },
      );
    });
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'events':
      case 'event':
        return context.udaan.secondary;
      case 'live_broadcast':
      case 'live':
      case 'radio':
        return context.udaan.primary;
      case 'promotions':
        return context.udaan.primaryGlow;
      case 'general':
      default:
        return context.udaan.onSurfaceVariant;
    }
  }

  void _announce(String message) {
    if (!mounted) return;
    announce(context, message);
  }

  String _summaryMessage({
    required AppCopy copy,
    required int shown,
    required int unread,
    required int total,
  }) {
    if (shown == 0) {
      return copy.notificationsEmpty;
    }
    final base = shown == 1
        ? copy.notificationsSummaryOne(unread)
        : copy.notificationsSummary(shown, unread);
    if (total > shown) {
      return '$base. ${copy.notificationsShowingLatest(shown)}';
    }
    return base;
  }

  void _maybeAnnounceSummary({
    required AppCopy copy,
    required int shown,
    required int unread,
    required int total,
  }) {
    // Signature omits unread so mark-read optimistic updates do not re-announce.
    final signature = '$shown|$total';
    if (_lastAnnouncedSignature == signature) return;
    _lastAnnouncedSignature = signature;
    _announce(
      _summaryMessage(
        copy: copy,
        shown: shown,
        unread: unread,
        total: total,
      ),
    );
  }

  /// Soft refresh only — no VoiceOver announcement (avoids crash under focus).
  Future<void> _refreshInbox() async {
    await ref.read(notificationsListProvider.notifier).refresh();
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  String _showingStatusLine(AppCopy copy, NotificationListResult result) {
    final shown = result.items.length;
    if (result.total > shown) {
      return copy.notificationsShowingLatest(shown);
    }
    return copy.notificationsShowingCount(shown);
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (cached != null && cached.items.isNotEmpty) ...[
                    Semantics(
                      label: _showingStatusLine(copy, cached),
                      child: Text(
                        _showingStatusLine(copy, cached),
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: context.udaan.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _refreshInbox,
                      style: TextButton.styleFrom(
                        foregroundColor: context.udaan.primaryGlow,
                        minimumSize: const Size(
                          BrandTokens.a11yMinTapTarget,
                          BrandTokens.a11yMinTapTarget,
                        ),
                      ),
                      child: Text(
                        copy.notificationsRefresh,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: RefreshIndicator(
                color: context.udaan.primary,
                onRefresh: _refreshInbox,
                child: _buildInboxBody(
                  copy: copy,
                  notifications: notifications,
                  cached: cached,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxBody({
    required AppCopy copy,
    required AsyncValue<NotificationListResult> notifications,
    required NotificationListResult? cached,
  }) {
    // Keep existing items while soft-refreshing — never flash a bare spinner.
    if (cached != null) {
      return _buildList(copy: copy, result: cached);
    }

    return notifications.when(
      data: (result) => _buildList(copy: copy, result: result),
      loading: () => Center(
        child: Semantics(
          label: copy.notificationsLoading,
          liveRegion: true,
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
                onAction: _refreshInbox,
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
              actionLabel: copy.notificationsManageSettings,
              onAction: _openSettings,
            ),
          ),
        ],
      );
    }
    // Explicit children (≤20): unique keys even if API ids collide → no
    // ListView duplicate-ValueKey collapse / VoiceOver crash.
    return ListView(
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      children: [
        for (var i = 0; i < items.length; i++)
          NotificationListCard(
            key: ValueKey('notif-${items[i].id}-$i'),
            item: items[i],
            copy: copy,
            accent: _accentForType(items[i].type),
            when: formatNotificationRelativeTime(
              items[i].createdAt,
              copy,
            ),
          ),
      ],
    );
  }
}
