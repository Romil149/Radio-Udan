import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/models/app_notification.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../auth/widgets/udaan_auth_widgets.dart';
import 'notification_time_formatter.dart';
import 'notifications_providers.dart';

/// Full-screen notification: title + message; marks as read on open.
class NotificationDetailScreen extends ConsumerStatefulWidget {
  const NotificationDetailScreen({
    required this.notification,
    super.key,
  });

  final AppNotification notification;

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markReadAndAnnounce());
  }

  Future<void> _markReadAndAnnounce() async {
    final copy = ref.read(appCopyProvider);
    final item = widget.notification;
    if (!item.isRead && item.id > 0) {
      // Prefer list notifier (optimistic + API) when inbox is mounted;
      // otherwise mark via API and refresh unread badge.
      try {
        if (ProviderScope.containerOf(context).exists(notificationsListProvider)) {
          await ref.read(notificationsListProvider.notifier).markRead(item.id);
        } else {
          await ref.read(radioudaanApiProvider).markNotificationRead(item.id);
          ref.invalidate(notificationUnreadCountProvider);
        }
      } catch (_) {
        try {
          await ref.read(radioudaanApiProvider).markNotificationRead(item.id);
        } catch (_) {}
        ref.invalidate(notificationUnreadCountProvider);
      }
    }
    if (!mounted) return;
    announce(
      context,
      '${copy.notificationRead}. ${item.title}. ${item.body}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final palette = context.udaan;
    final item = widget.notification;
    final when = formatNotificationRelativeTime(item.createdAt, copy);

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
                title: copy.notificationDetailTitle,
                onBack: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(BrandTokens.screenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      label: item.title,
                      child: ExcludeSemantics(
                        child: Text(
                          item.title,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: palette.onBackground,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                    if (when.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        when,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: palette.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      item.body,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: palette.onBackground,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
