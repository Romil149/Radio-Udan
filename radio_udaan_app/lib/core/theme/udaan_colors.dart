import 'package:flutter/material.dart';

import '../config/app_branding.dart';

export 'accessibility_scope.dart';

/// Runtime palette from WordPress `GET /config` → `branding.colors`.
class UdaanPalette {
  const UdaanPalette({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.surface,
    required this.surfaceDark,
    required this.error,
    required this.background,
    required this.onBackground,
    required this.onSurfaceVariant,
    required this.primaryGlow,
    required this.outlineVariant,
    required this.surfaceContainerHigh,
    required this.surfaceContainer,
    required this.hint,
    required this.onSurfaceMuted,
    required this.onError,
    required this.scrim,
  });

  factory UdaanPalette.fromBrand(BrandColors brand) {
    return UdaanPalette(
      primary: brand.primary,
      onPrimary: brand.onPrimary,
      secondary: brand.secondary,
      surface: brand.surface,
      surfaceDark: brand.surfaceDark,
      error: brand.error,
      background: brand.background,
      onBackground: brand.onBackground,
      onSurfaceVariant: brand.onSurfaceVariant,
      primaryGlow: brand.primaryGlow,
      outlineVariant: brand.outlineVariant,
      surfaceContainerHigh: brand.surfaceContainerHigh,
      surfaceContainer: brand.surfaceContainer,
      hint: brand.hint,
      onSurfaceMuted: brand.onSurfaceMuted,
      onError: brand.onError,
      scrim: brand.scrim,
    );
  }

  /// High-contrast variant derived from WordPress brand colors (Settings).
  factory UdaanPalette.highContrastFrom(BrandColors brand) {
    return UdaanPalette(
      background: brand.surfaceDark,
      onBackground: brand.onPrimary,
      onSurfaceVariant: brand.onPrimary,
      primary: brand.primary,
      primaryGlow: brand.onPrimary,
      outlineVariant: brand.onPrimary,
      surfaceContainerHigh: brand.background,
      surfaceContainer: brand.surfaceDark,
      onPrimary: brand.surfaceDark,
      hint: brand.onSurfaceVariant,
      error: brand.error,
      secondary: brand.secondary,
      onSurfaceMuted: brand.onPrimary,
      surface: brand.surface,
      surfaceDark: brand.surfaceDark,
      onError: brand.onError,
      scrim: brand.scrim,
    );
  }

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color surface;
  final Color surfaceDark;
  final Color error;
  final Color background;
  final Color onBackground;
  final Color onSurfaceVariant;
  final Color primaryGlow;
  final Color outlineVariant;
  final Color surfaceContainerHigh;
  final Color surfaceContainer;
  final Color hint;
  final Color onSurfaceMuted;
  final Color onError;
  final Color scrim;
}

extension BrandColorsUdaan on BrandColors {
  UdaanPalette get udaanPalette => UdaanPalette.fromBrand(this);
}
