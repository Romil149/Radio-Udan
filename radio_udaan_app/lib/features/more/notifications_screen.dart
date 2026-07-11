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

  /// When true, skip summary announce (Refresh already spoke once).
  bool _skipNextSummaryAnnounce = false;

  @override
  void initState() {
    super.initState();
    // listenManual: avoid re-registering every build (VO crash source).
    ref.listenManual(notificationsListProvider, (prev, next) {
      next.whenOrNull(
        data: (result) {
          _lastAnnouncedError = null;
          if (_skipNextSummaryAnnounce) {
            _skipNextSummaryAnnounce = false;
            _lastAnnouncedSignature =
                '${_filter.name}|${result.items.length}|${result.total}';
            return;
          }
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

  Future<void> _refreshInbox({bool announceSuccess = false}) async {
    if (announceSuccess) {
      // One announcement after refresh — suppress competing summary.
      _skipNextSummaryAnnounce = true;
    }
    await ref.read(notificationsListProvider.notifier).refresh();
    if (!mounted) return;
    if (!announceSuccess) return;

    final next = ref.read(notificationsListProvider);
    if (!next.hasValue) {
      _skipNextSummaryAnnounce = false;
      return;
    }

    // Single delayed announcement so VO focus can settle before speaking.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _announce(_copy.notificationsRefreshed);
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
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
                  Row(
                    children: [
                      Semantics(
                        button: true,
                        label: copy.notificationsRefresh,
                        onTap: () => _refreshInbox(announceSuccess: true),
                        child: ExcludeSemantics(
                          child: TextButton(
                            onPressed: () =>
                                _refreshInbox(announceSuccess: true),
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
                      ),
                      if (unreadCount > 0)
                        markingAll
                            ? Semantics(
                                button: true,
                                enabled: false,
                                label: copy.notificationsMarkAllRead,
                                child: ExcludeSemantics(
                                  child: TextButton(
                                    onPressed: null,
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          context.udaan.primaryGlow,
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
                                  ),
                                ),
                              )
                            : Semantics(
                                button: true,
                                label: copy.notificationsMarkAllRead,
                                onTap: _markAllRead,
                                child: ExcludeSemantics(
                                  child: TextButton(
                                    onPressed: _markAllRead,
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          context.udaan.primaryGlow,
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
                onRefresh: () => _refreshInbox(),
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
                onAction: () => _refreshInbox(),
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
    final truncated = result.total > items.length;
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
    return ListView.builder(
      padding: const EdgeInsets.all(BrandTokens.screenPadding),
      itemCount: items.length + (truncated ? 1 : 0),
      itemBuilder: (context, index) {
        if (truncated && index == 0) {
          final banner = copy.notificationsShowingLatest(items.length);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Semantics(
              label: banner,
              child: ExcludeSemantics(
                child: Text(
                  banner,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.udaan.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }
        final item = items[truncated ? index - 1 : index];
        return NotificationListCard(
          key: ValueKey(item.id),
          item: item,
          copy: copy,
          accent: _accentForType(item.type),
          when: formatNotificationRelativeTime(
            item.createdAt,
            copy,
          ),
          onTap: () async {
            ref.read(notificationsListProvider.notifier).markRead(item.id);
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationDetailScreen(
                  notification: item,
                ),
              ),
            );
            if (!mounted) return;
            ref.invalidate(notificationUnreadCountProvider);
          },
        );
      },
    );
  }

  /// Accessible filter toggle — avoids FilterChip + ExcludeSemantics VO crashes.
  Widget _filterToggle(String label, bool selected, VoidCallback onTap) {
    final selectedHint = selected ? ', selected' : ', not selected';
    return Semantics(
      button: true,
      selected: selected,
      label: '$label$selectedHint',
      onTap: onTap,
      child: ExcludeSemantics(
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
      ),
    );
  }
}
