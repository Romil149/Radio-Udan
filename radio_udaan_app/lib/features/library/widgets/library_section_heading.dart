import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';

/// Copper section title (Stitch Library screen).
class LibrarySectionHeading extends StatelessWidget {
  const LibrarySectionHeading({
    required this.title,
    super.key,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BrandTokens.screenPadding,
        4,
        BrandTokens.screenPadding,
        12,
      ),
      child: Semantics(
        header: true,
        label: title,
        child: ExcludeSemantics(
          child: Text(
            title,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: UdaanColors.primaryGlow,
            ),
          ),
        ),
      ),
    );
  }
}
