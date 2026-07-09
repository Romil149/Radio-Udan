import 'package:flutter/material.dart';

import '../config/app_branding.dart';
import '../theme/udaan_text_styles.dart';

/// Bundled logo for splash/auth before network config loads.
class OfflineBrandLogo extends StatelessWidget {
  const OfflineBrandLogo({
    required this.branding,
    this.height = 168,
    super.key,
  });

  static const String assetPath = 'assets/images/radio_udaan_logo.png';

  final AppBranding branding;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${branding.appName} logo',
      image: true,
      child: ExcludeSemantics(
        child: Image.asset(
          assetPath,
          height: height,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return _TextFallback(branding: branding, height: height);
          },
        ),
      ),
    );
  }
}

class _TextFallback extends StatelessWidget {
  const _TextFallback({required this.branding, required this.height});

  final AppBranding branding;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: ExcludeSemantics(
          child: Text(
            branding.appName,
            textAlign: TextAlign.center,
            style: udaanTextStyle(
              context,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: branding.colors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
