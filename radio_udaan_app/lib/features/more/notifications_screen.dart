import 'dart:async';

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
import 'notification_detail_screen.dart';
import 'notification_time_formatter.dart';
import 'notifications_providers.dart';
import 'settings_screen.dart';
import 'widgets/notification_list_card.dart';

enum _NotificationFilter { all, unread }

/// In-app notification inbox: top 20 from `GET /notifications`.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  _NotificationFilter _filter = _NotificationFilter.all;
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
    required bool unreadOnly,
  }) {
    if (shown == 0) {
      return unreadOnly
          ? copy.notificationsUnreadEmpty
          : copy.notificationsEmpty;
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
    final unreadOnly = _filter == _NotificationFilter.unread;
    // Signature omits unread so mark-read optimistic updates do not re-announce.
    final signature = '${_filter.name}|$shown|$total';
    if (_lastAnnouncedSignature == signature) return;
    _lastAnnouncedSignature = signature;
    _announce(
      _summaryMessage(
        copy: copy,
        shown: shown,
        unread: unread,
        total: total,
        unreadOnly: unreadOnly,
      ),
    );
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationsListProvider.notifier).markAllRead();
    if (!mounted) return;
    _announce(_copy.notificationsMarkedAll);
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
    final markingAll = ref.watch(notificationsMarkingAllProvider);
    final unreadCount = notifications.valueOrNull?.unreadCount ?? 0;
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _filterToggle(
                        copy.notificationsFilterAll,
                        _filter == _NotificationFilter.all,
                        () {
                          setState(() {
                            _filter = _NotificationFilter.all;
                            _lastAnnouncedSignature = null;
                          });
                          ref
                              .read(notificationsListProvider.notifier)
                              .setUnreadFilter(false);
                        },
                      ),
                      _filterToggle(
                        unreadCount > 0
                            ? copy.notificationsFilterUnreadCount(unreadCount)
                            : copy.notificationsFilterUnread,
                        _filter == _NotificationFilter.unread,
                        () {
                          setState(() {
                            _filter = _NotificationFilter.unread;
                            _lastAnnouncedSignature = null;
                          });
                          ref
                              .read(notificationsListProvider.notifier)
                              .setUnreadFilter(true);
                        },
                      ),
                    ],
                  ),
                  if (cached != null && cached.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
                  ],
                  Row(
                    children: [
                      TextButton(
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
                      if (unreadCount > 0)
                        markingAll
                            ? TextButton(
                                onPressed: null,
                                style: TextButton.styleFrom(
                                  foregroundColor: context.udaan.primaryGlow,
                                  minimumSize: const Size(
                                    BrandTokens.a11yMinTapTarget,
                                    BrandTokens.a11yMinTapTarget,
                                  ),
                                ),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.udaan.primary,
                                  ),
                                ),
                              )
                            : TextButton(
                                onPressed: _markAllRead,
                                style: TextButton.styleFrom(
                                  foregroundColor: context.udaan.primaryGlow,
                                  minimumSize: const Size(
                                    BrandTokens.a11yMinTapTarget,
                                    BrandTokens.a11yMinTapTarget,
                                  ),
                                ),
                                child: Text(
                                  copy.notificationsMarkAllRead,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                    ],
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
              message: _filter == _NotificationFilter.unread
                  ? copy.notificationsUnreadEmpty
                  : copy.notificationsEmpty,
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
            onTap: () {
              final item = items[i];
              // Push first so mark-read hang never blocks navigation.
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => NotificationDetailScreen(
                    notification: item,
                  ),
                ),
              );
              unawaited(
                ref.read(notificationsListProvider.notifier).markRead(item.id),
              );
            },
          ),
      ],
    );
  }

  /// Accessible filter toggle — avoids FilterChip + ExcludeSemantics VO crashes.
  Widget _filterToggle(String label, bool selected, VoidCallback onTap) {
    final selectedHint = selected ? ', selected' : ', not selected';
    return Semantics(
      button: true,
      selected: selected,
      label: '$label$selectedHint',
      excludeSemantics: true,
      onTap: onTap,
      container: true,
      child: Material(
        color: selected
            ? context.udaan.primary
            : context.udaan.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: BrandTokens.a11yMinTapTarget,
              minWidth: BrandTokens.a11yMinTapTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? context.udaan.primaryGlow
                    : context.udaan.outlineVariant,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.atkinsonHyperlegible(
                fontWeight: FontWeight.w700,
                color: selected
                    ? context.udaan.onPrimary
                    : context.udaan.onBackground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
