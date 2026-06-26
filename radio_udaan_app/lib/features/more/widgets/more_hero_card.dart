import 'package:flutter/material.dart';

import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_google_fonts.dart';

class MoreHeroCard extends StatelessWidget {
  const MoreHeroCard({
    required this.title,
    required this.intro,
    this.backgroundIcon = Icons.settings_outlined,
    super.key,
  });

  final String title;
  final String intro;
  final IconData backgroundIcon;

  @override
  Widget build(BuildContext context) {
    final palette = context.udaan;

    return Semantics(
      header: true,
      label: '$title. $intro',
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: palette.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          border: Border.all(color: palette.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                backgroundIcon,
                size: 88,
                color: palette.primaryGlow.withValues(alpha: 0.12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: palette.primaryGlow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  intro,
                  style: udaanGoogleFont(
                    context,
                    fontSize: 16,
                    height: 1.4,
                    color: palette.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
