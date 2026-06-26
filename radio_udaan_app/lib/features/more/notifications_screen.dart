import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import 'notification_time_formatter.dart';
import 'notifications_providers.dart';
import 'widgets/notification_list_card.dart';

enum _NotificationFilter { all, unread }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  _NotificationFilter _filter = _NotificationFilter.all;

  Color _accentForType(String type) {
    switch (type) {
      case 'live':
      case 'radio':
        return UdaanColors.primary;
      case 'event':
        return UdaanColors.secondary;
      default:
        return UdaanColors.onSurfaceVariant;
    }
  }

  void _announce(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  Future<void> _markAllRead() async {
    await ref.read(notificationsListProvider.notifier).markAllRead();
    if (!mounted) return;
    _announce(_copy.notificationsMarkedAll);
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final notifications = ref.watch(notificationsListProvider);
    final markingAll = ref.watch(notificationsMarkingAllProvider);
    final unreadCount = notifications.valueOrNull?.unreadCount ?? 0;

    return Scaffold(
      backgroundColor: UdaanColors.background,
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
                title: _copy.notificationsTitle,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.screenPadding,
              ),
              child: Row(
                children: [
                  _filterChip(
                    _copy.notificationsFilterAll,
                    _filter == _NotificationFilter.all,
                    () => setState(() => _filter = _NotificationFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    unreadCount > 0
                        ? _copy.notificationsFilterUnreadCount(unreadCount)
                        : _copy.notificationsFilterUnread,
                    _filter == _NotificationFilter.unread,
                    () => setState(() => _filter = _NotificationFilter.unread),
                  ),
                  const Spacer(),
                  if (unreadCount > 0)
                    Semantics(
                      button: true,
                      label: _copy.notificationsMarkAllRead,
                      child: TextButton(
                        onPressed: markingAll ? null : _markAllRead,
                        style: TextButton.styleFrom(
                          foregroundColor: UdaanColors.primaryGlow,
                          minimumSize: const Size(
                            BrandTokens.minTapTarget,
                            BrandTokens.minTapTarget,
                          ),
                        ),
                        child: markingAll
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: UdaanColors.primary,
                                ),
                              )
                            : Text(
                                _copy.notificationsMarkAllRead,
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
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: UdaanColors.primary,
                onRefresh: () =>
                    ref.read(notificationsListProvider.notifier).refresh(),
                child: notifications.when(
                  data: (result) {
                    final items = _filter == _NotificationFilter.unread
                        ? result.items.where((n) => !n.isRead).toList()
                        : result.items;
                    if (items.isEmpty) {
                      return ListView(
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.25,
                            child: EmptyState(
                              icon: Icons.notifications_none_outlined,
                              message: _filter == _NotificationFilter.unread
                                  ? _copy.notificationsUnreadEmpty
                                  : _copy.notificationsEmpty,
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(BrandTokens.screenPadding),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return NotificationListCard(
                          item: item,
                          copy: copy,
                          accent: _accentForType(item.type),
                          when: formatNotificationRelativeTime(
                            item.createdAt,
                            copy,
                          ),
                          onTap: () => ref
                              .read(notificationsListProvider.notifier)
                              .markRead(item.id),
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: Semantics(
                      label: _copy.notificationsLoading,
                      liveRegion: true,
                      child: const CircularProgressIndicator(
                        color: UdaanColors.primary,
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
                            actionLabel: _copy.retry,
                            onAction: () => ref
                                .read(notificationsListProvider.notifier)
                                .refresh(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: UdaanColors.primary,
          labelStyle: GoogleFonts.atkinsonHyperlegible(
            fontWeight: FontWeight.w700,
            color: selected ? UdaanColors.onPrimary : UdaanColors.onBackground,
          ),
        ),
      ),
    );
  }
}
