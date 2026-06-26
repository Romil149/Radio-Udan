import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';

/// Single notification row with clear read vs unread styling.
class NotificationListCard extends StatelessWidget {
  const NotificationListCard({
    required this.item,
    required this.copy,
    required this.accent,
    required this.when,
    required this.onTap,
    super.key,
  });

  final AppNotification item;
  final AppCopy copy;
  final Color accent;
  final String when;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final statusLabel = isUnread ? copy.notificationUnread : copy.notificationRead;
    final whenPart = when.isNotEmpty ? '$when. ' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '$statusLabel. $whenPart${item.title}. ${item.body}',
        child: Material(
          color: isUnread
              ? UdaanColors.surfaceContainerHigh
              : UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                border: Border.all(
                  color: isUnread
                      ? UdaanColors.primaryGlow.withValues(alpha: 0.75)
                      : UdaanColors.outlineVariant,
                  width: isUnread ? 1.5 : 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: isUnread ? accent : accent.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(BrandTokens.cardRadius),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isUnread) ...[
                                Semantics(
                                  label: copy.notificationUnread,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: const BoxDecoration(
                                      color: UdaanColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                              Expanded(
                                child: Text(
                                  when,
                                  style: GoogleFonts.atkinsonHyperlegible(
                                    fontSize: 13,
                                    fontWeight: isUnread
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isUnread
                                        ? UdaanColors.primaryGlow
                                        : UdaanColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: UdaanColors.primary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    copy.notificationUnread,
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: UdaanColors.primaryGlow,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 17,
                              fontWeight:
                                  isUnread ? FontWeight.w900 : FontWeight.w700,
                              color: UdaanColors.onBackground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.body,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 15,
                              fontWeight: isUnread
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isUnread
                                  ? UdaanColors.onBackground
                                      .withValues(alpha: 0.92)
                                  : UdaanColors.onSurfaceVariant,
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
