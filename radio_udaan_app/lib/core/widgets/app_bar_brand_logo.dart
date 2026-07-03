import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'offline_brand_logo.dart';

/// Compact logo for main-tab and shell app bars (top-left).
class AppBarBrandLogo extends ConsumerWidget {
  const AppBarBrandLogo({super.key});

  static const double _height = 40;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branding = ref.watch(appBrandingProvider);
    final copy = ref.watch(appCopyProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheHeight = (_height * dpr).round();

    Widget graphic;
    if (branding.hasLogo) {
      graphic = CachedNetworkImage(
        imageUrl: branding.logoUrl,
        height: _height,
        fit: BoxFit.contain,
        memCacheHeight: cacheHeight,
        maxHeightDiskCache: cacheHeight,
        fadeInDuration: const Duration(milliseconds: 150),
        errorWidget: (_, _, _) => _bundledLogo(branding),
      );
    } else {
      graphic = _bundledLogo(branding);
    }

    return Semantics(
      label: copy.appLogoSemantics,
      image: true,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: SizedBox(
            height: _height,
            child: graphic,
          ),
        ),
      ),
    );
  }

  Widget _bundledLogo(AppBranding branding) {
    return Image.asset(
      OfflineBrandLogo.assetPath,
      height: _height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          branding.appName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
