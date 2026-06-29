import 'package:flutter/material.dart';

import '../../../core/config/app_branding.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_text_styles.dart';
import '../event_formatters.dart';
import '../models/form_schema.dart';

/// Event summary block at the top of registration (full text for screen readers).
class EventContextBanner extends StatelessWidget {
  const EventContextBanner({
    required this.copy,
    required this.event,
    super.key,
  });

  final AppCopy copy;
  final EventFormInfo event;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;
    final schedule = event.startAt != null
        ? formatEventScheduleLine(event.startAt!)
        : '';
    final summary = event.summary?.trim() ?? '';
    final typeLabel = event.eventTypeLabel?.trim() ?? '';

    final parts = <String>[
      if (typeLabel.isNotEmpty) typeLabel,
      if (schedule.isNotEmpty) schedule,
      if (summary.isNotEmpty) summary,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final semanticsLabel = parts.join('. ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        container: true,
        label: semanticsLabel,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            border: Border.all(color: palette.outlineVariant),
          ),
          child: ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (typeLabel.isNotEmpty)
                  Text(
                    typeLabel,
                    style: udaanTextStyle(
                      context,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: palette.primary,
                    ),
                  ),
                if (schedule.isNotEmpty) ...[
                  if (typeLabel.isNotEmpty) const SizedBox(height: 8),
                  Text(
                    schedule,
                    style: udaanTextStyle(
                      context,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: palette.primaryGlow,
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    summary,
                    style: udaanTextStyle(
                      context,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: palette.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
