import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';

class MoreHeroCard extends StatelessWidget {
  const MoreHeroCard({
    required this.title,
    required this.intro,
    super.key,
  });

  final String title;
  final String intro;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: '$title. $intro',
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          border: Border.all(color: UdaanColors.outlineVariant),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                Icons.settings_outlined,
                size: 88,
                color: UdaanColors.primaryGlow.withValues(alpha: 0.12),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: UdaanColors.primaryGlow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  intro,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 16,
                    height: 1.4,
                    color: UdaanColors.onSurfaceVariant,
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
