import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_branding.dart';
import '../providers/app_providers.dart';
import '../theme/brand_tokens.dart';

/// Network logo from WordPress (disk + memory cache), or text fallback.
class BrandLogo extends ConsumerWidget {
  const BrandLogo({
    super.key,
    this.height = BrandTokens.logoHeight,
    this.showTagline = false,
  });

  final double height;
  final bool showTagline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appBrandingProvider);

    if (branding.hasLogo) {
      final cacheHeight = (height * MediaQuery.devicePixelRatioOf(context))
          .round();
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: '${branding.appName} logo',
            image: true,
            child: CachedNetworkImage(
              imageUrl: branding.logoUrl,
              height: height,
              fit: BoxFit.contain,
              memCacheHeight: cacheHeight,
              maxHeightDiskCache: cacheHeight,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, _) => SizedBox(
                height: height,
                width: height,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, _, _) =>
                  _TextFallback(branding: branding, showTagline: false),
            ),
          ),
          if (showTagline && branding.tagline.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              branding.tagline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      );
    }

    return _TextFallback(branding: branding, showTagline: showTagline);
  }
}

class _TextFallback extends StatelessWidget {
  const _TextFallback({required this.branding, required this.showTagline});

  final AppBranding branding;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final primary = branding.colors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          branding.appName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        if (showTagline && branding.tagline.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            branding.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
