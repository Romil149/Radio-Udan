import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/config/info_hub_config.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_google_fonts.dart';

/// Social link row for the About tab footer.
class AboutSocialFooter extends StatelessWidget {
  const AboutSocialFooter({
    super.key,
    required this.copy,
    required this.links,
    this.onLaunchFailed,
  });

  final AppCopy copy;
  final List<SocialLinkConfig> links;
  final VoidCallback? onLaunchFailed;

  IconData _iconFor(String id) {
    switch (id) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt_outlined;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'website':
        return Icons.language;
      default:
        return Icons.link;
    }
  }

  Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      onLaunchFailed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (links.isEmpty) return const SizedBox.shrink();

    final palette = context.udaan;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      child: Column(
        children: [
          Semantics(
            header: true,
            child: Text(
              copy.followUs,
              style: udaanGoogleFont(
                context,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final link in links)
                Semantics(
                  button: true,
                  label: '${link.label}. ${copy.linkOpensInBrowser}',
                  child: Material(
                    color: palette.surfaceContainer,
                    borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(BrandTokens.cardRadius),
                      onTap: () => _open(Uri.parse(link.url)),
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: BrandTokens.a11yMinTapTarget,
                          minHeight: BrandTokens.a11yMinTapTarget,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconFor(link.id),
                              color: palette.primaryGlow,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              link.label,
                              style: udaanGoogleFont(
                                context,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: palette.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
