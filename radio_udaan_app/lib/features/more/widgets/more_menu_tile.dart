import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';

/// Stitch-style row in the More tab (icon, title, subtitle, chevron).
class MoreMenuTile extends StatelessWidget {
  const MoreMenuTile({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.iconBackground,
    required this.onTap,
    this.iconColor = UdaanColors.onPrimary,
    this.titleColor,
    this.borderColor,
    this.trailing,
    this.semanticsLabel,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? semanticsLabel;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final Color? titleColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        enabled: onTap != null,
        label: semanticsLabel ??
            (subtitle != null && subtitle!.isNotEmpty
                ? '$title. $subtitle'
                : title),
        child: Material(
          color: UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            child: Container(
              constraints: const BoxConstraints(minHeight: 72),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                border: Border.all(
                  color: borderColor ?? UdaanColors.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: titleColor ?? UdaanColors.onBackground,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 14,
                              color: UdaanColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  trailing ??
                      Icon(
                        Icons.chevron_right,
                        color: titleColor ?? UdaanColors.onBackground,
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
