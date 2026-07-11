import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';

/// Inbox row: title + short preview. Full body is on the detail screen.
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

  static const int _previewMaxChars = 110;

  String get _preview {
    final body = item.body.trim();
    if (body.length <= _previewMaxChars) return body;
    return '${body.substring(0, _previewMaxChars).trimRight()}…';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !item.isRead;
    final statusLabel =
        isUnread ? copy.notificationUnread : copy.notificationRead;
    final typeLabel = copy.notificationTypeLabel(item.type);
    final whenPart = when.isNotEmpty ? '$when. ' : '';
    final preview = _preview;
    final semanticsLabel =
        '$statusLabel. $typeLabel. $whenPart${item.title}. $preview. ${copy.notificationOpenHint}';

    // excludeSemantics as Semantics property (not ExcludeSemantics widget) so
    // pointer hits reach InkWell while VO still gets one clean button node.
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: semanticsLabel,
        excludeSemantics: true,
        onTap: onTap,
        container: true,
        child: Material(
          color: isUnread
              ? context.udaan.surfaceContainerHigh
              : context.udaan.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          child: InkWell(
            onTap: onTap,
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
                      color:
                          isUnread ? accent : accent.withValues(alpha: 0.35),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(BrandTokens.cardRadius),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isUnread) ...[
                                Container(
                                  width: 10,
                                  height: 10,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: context.udaan.primary,
                                    shape: BoxShape.circle,
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
                              Text(
                                typeLabel,
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                              if (isUnread) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.udaan.primary
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    copy.notificationUnread,
                                    style: GoogleFonts.atkinsonHyperlegible(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: context.udaan.primaryGlow,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 17,
                              fontWeight: isUnread
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                              color: context.udaan.onBackground,
                            ),
                          ),
                          if (preview.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              preview,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.chevron_right,
                      color: context.udaan.onSurfaceVariant,
                      size: 28,
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
