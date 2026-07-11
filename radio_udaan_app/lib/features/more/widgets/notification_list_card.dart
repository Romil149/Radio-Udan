import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';

/// Inbox row: relative time + title + full message (static text for VO swipe).
class NotificationListCard extends StatelessWidget {
  const NotificationListCard({
    required this.item,
    required this.copy,
    required this.accent,
    required this.when,
    super.key,
  });

  final AppNotification item;
  final AppCopy copy;
  final Color accent;
  final String when;

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final body = item.body.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isUnread
            ? context.udaan.surfaceContainerHigh
            : context.udaan.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: BrandTokens.a11yMinTapTarget,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            border: Border.all(
              color: isUnread
                  ? context.udaan.primaryGlow.withValues(alpha: 0.75)
                  : context.udaan.outlineVariant,
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
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
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
                                decoration: BoxDecoration(
                                  color: context.udaan.primary,
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
                                    ? context.udaan.primaryGlow
                                    : context.udaan.onSurfaceVariant,
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
                          color: context.udaan.onBackground,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: context.udaan.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
