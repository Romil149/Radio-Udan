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
import 'notification_detail_screen.dart';
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
        return context.udaan.primary;
      case 'event':
        return context.udaan.secondary;
      default:
        return context.udaan.onSurfaceVariant;
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

  Future<void> _loadMore() async {
    await ref.read(notificationsListProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final notifications = ref.watch(notificationsListProvider);
    final markingAll = ref.watch(notificationsMarkingAllProvider);
    final loadingMore = ref.watch(notificationsLoadingMoreProvider);
    final unreadCount = notifications.valueOrNull?.unreadCount ?? 0;

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
                    () {
                      setState(() => _filter = _NotificationFilter.all);
                      ref
                          .read(notificationsListProvider.notifier)
                          .setUnreadFilter(false);
                    },
                  ),
                  const SizedBox(width: 8),
                  _filterChip(
                    unreadCount > 0
                        ? _copy.notificationsFilterUnreadCount(unreadCount)
                        : _copy.notificationsFilterUnread,
                    _filter == _NotificationFilter.unread,
                    () {
                      setState(() => _filter = _NotificationFilter.unread);
                      ref
                          .read(notificationsListProvider.notifier)
                          .setUnreadFilter(true);
                    },
                  ),
                  const Spacer(),
                  if (unreadCount > 0)
                    Semantics(
                      button: true,
                      label: _copy.notificationsMarkAllRead,
                      onTap: markingAll ? null : _markAllRead,
                      child: ExcludeSemantics(
                        child: TextButton(
                          onPressed: markingAll ? null : _markAllRead,
                          style: TextButton.styleFrom(
                            foregroundColor: context.udaan.primaryGlow,
                            minimumSize: const Size(
                              BrandTokens.minTapTarget,
                              BrandTokens.minTapTarget,
                            ),
                          ),
                          child: markingAll
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: context.udaan.primary,
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
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: context.udaan.primary,
                onRefresh: () =>
                    ref.read(notificationsListProvider.notifier).refresh(),
                child: notifications.when(
                  data: (result) {
                    final items = result.items;
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
                    final showLoadMore = result.hasMorePages;
                    final itemCount =
                        items.length + (showLoadMore ? 1 : 0);
                    return ListView.builder(
                      padding: const EdgeInsets.all(BrandTokens.screenPadding),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        if (showLoadMore && index == items.length) {
                          return _loadMoreFooter(
                            copy: copy,
                            loading: loadingMore,
                            onLoadMore: _loadMore,
                          );
                        }
                        final item = items[index];
                        return NotificationListCard(
                          item: item,
                          copy: copy,
                          accent: _accentForType(item.type),
                          when: formatNotificationRelativeTime(
                            item.createdAt,
                            copy,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => NotificationDetailScreen(
                                  notification: item,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: Semantics(
                      label: _copy.notificationsLoading,
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

  Widget _loadMoreFooter({
    required AppCopy copy,
    required bool loading,
    required VoidCallback onLoadMore,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Semantics(
        button: true,
        enabled: !loading,
        label: loading
            ? copy.notificationsLoadingMore
            : copy.notificationsLoadMore,
        onTap: loading ? null : onLoadMore,
        liveRegion: loading,
        child: ExcludeSemantics(
          child: Center(
            child: loading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: context.udaan.primary,
                    ),
                  )
                : TextButton(
                    onPressed: onLoadMore,
                    style: TextButton.styleFrom(
                      foregroundColor: context.udaan.primaryGlow,
                      minimumSize: const Size(
                        BrandTokens.minTapTarget,
                        BrandTokens.minTapTarget,
                      ),
                    ),
                    child: Text(
                      copy.notificationsLoadMore,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: FilterChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: context.udaan.primary,
          labelStyle: GoogleFonts.atkinsonHyperlegible(
            fontWeight: FontWeight.w700,
            color: selected ? context.udaan.onPrimary : context.udaan.onBackground,
          ),
        ),
      ),
    );
  }
}
