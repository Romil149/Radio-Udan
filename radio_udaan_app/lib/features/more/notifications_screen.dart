import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/models/app_notification.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import 'notifications_providers.dart';

enum _NotificationFilter { all, unread }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
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

  String _formatWhen(String? raw) {
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed == null) return '';
    return DateFormat.yMMMd().add_jm().format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsListProvider);

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
                title: AppStrings.notificationsTitle,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: BrandTokens.screenPadding,
              ),
              child: Row(
                children: [
                  _filterChip(AppStrings.notificationsFilterAll,
                      _filter == _NotificationFilter.all, () {
                    setState(() => _filter = _NotificationFilter.all);
                  }),
                  const SizedBox(width: 8),
                  _filterChip(AppStrings.notificationsFilterUnread,
                      _filter == _NotificationFilter.unread, () {
                    setState(() => _filter = _NotificationFilter.unread);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                color: UdaanColors.primary,
                onRefresh: () async {
                  ref.invalidate(notificationsListProvider);
                  await ref.read(notificationsListProvider.future);
                },
                child: notifications.when(
                  data: (result) {
                    final items = _filter == _NotificationFilter.unread
                        ? result.items.where((n) => !n.isRead).toList()
                        : result.items;
                    if (items.isEmpty) {
                      return ListView(
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Semantics(
                              liveRegion: true,
                              child: Text(
                                _filter == _NotificationFilter.unread
                                    ? AppStrings.notificationsUnreadEmpty
                                    : AppStrings.notificationsEmpty,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 16,
                                  color: UdaanColors.onSurfaceVariant,
                                ),
                              ),
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
                        return _NotificationCard(
                          item: item,
                          accent: _accentForType(item.type),
                          when: _formatWhen(item.createdAt),
                          onTap: () async {
                            if (!item.isRead) {
                              await ref
                                  .read(radioudaanApiProvider)
                                  .markNotificationRead(item.id);
                              invalidateNotificationBadges(ref);
                            }
                          },
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: Semantics(
                      label: AppStrings.notificationsLoading,
                      child: const CircularProgressIndicator(
                        color: UdaanColors.primary,
                      ),
                    ),
                  ),
                  error: (e, _) {
                    final message = parseApiError(e).message;
                    return Center(
                      child: Semantics(
                        liveRegion: true,
                        label: message,
                        child: Text(message),
                      ),
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.accent,
    required this.when,
    required this.onTap,
  });

  final AppNotification item;
  final Color accent;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status =
        item.isRead ? AppStrings.notificationRead : AppStrings.notificationUnread;
    final whenPart = when.isNotEmpty ? '$when. ' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '$status. $whenPart${item.title}. ${item.body}',
        child: Material(
          color: UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: UdaanColors.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (when.isNotEmpty)
                            Text(
                              when,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 13,
                                color: UdaanColors.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            item.title,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: UdaanColors.onBackground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.body,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 15,
                              color: UdaanColors.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
