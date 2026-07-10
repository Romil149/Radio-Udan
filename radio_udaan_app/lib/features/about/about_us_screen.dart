import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/config/info_hub_config.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/accessibility_scope.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_google_fonts.dart';
import '../../core/widgets/brand_app_bar.dart';

/// About Us screen: story content from WordPress `info_hub.about`.
class AboutUsScreen extends ConsumerWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final about = ref.watch(remoteConfigProvider)?.infoHub.about ??
        const AboutUsConfig();
    final palette = context.udaan;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: copy.aboutUs),
      body: SafeArea(
        child: about.hasContent
            ? ListView(
                padding: const EdgeInsets.all(BrandTokens.screenPadding),
                children: [
                  if (about.badge.trim().isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: palette.primary,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          about.badge,
                          style: udaanGoogleFont(
                            context,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: palette.onBackground,
                          ),
                        ),
                      ),
                    ),
                  if (about.badge.trim().isNotEmpty) const SizedBox(height: 16),
                  if (about.headline.trim().isNotEmpty)
                    Semantics(
                      header: true,
                      child: ExcludeSemantics(
                        child: Text(
                          about.headline,
                          style: udaanGoogleFont(
                            context,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                            color: palette.onBackground,
                          ),
                        ),
                      ),
                    ),
                  if (about.intro.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      about.intro,
                      style: udaanGoogleFont(
                        context,
                        fontSize: 16,
                        height: 1.5,
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (about.imageUrl.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Semantics(
                      label: about.headline.trim().isNotEmpty
                          ? about.headline
                          : copy.aboutUs,
                      image: true,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(BrandTokens.cardRadius),
                        child: CachedNetworkImage(
                          imageUrl: about.imageUrl.trim(),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheHeight: 800,
                          placeholder: (_, _) => const SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, _, _) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              copy.linkUnavailable,
                              style: udaanGoogleFont(
                                context,
                                color: palette.onBackground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (about.body.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      about.body,
                      style: udaanGoogleFont(
                        context,
                        fontSize: 16,
                        height: 1.55,
                        color: palette.onBackground,
                      ),
                    ),
                  ],
                  if (about.accessibilityNote.trim().isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.surfaceContainer,
                        borderRadius:
                            BorderRadius.circular(BrandTokens.cardRadius),
                        border: Border(
                          left: BorderSide(color: palette.primary, width: 4),
                        ),
                      ),
                      child: Text(
                        about.accessibilityNote,
                        style: udaanGoogleFont(
                          context,
                          fontSize: 15,
                          height: 1.45,
                          color: palette.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(BrandTokens.screenPadding),
                child: Semantics(
                  label: copy.linkUnavailable,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: Text(
                      copy.linkUnavailable,
                      style: udaanGoogleFont(
                        context,
                        fontSize: 16,
                        color: palette.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
