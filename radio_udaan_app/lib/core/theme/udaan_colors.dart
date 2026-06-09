import 'package:flutter/material.dart';

import '../config/app_branding.dart';

/// Stitch Udaan Core palette (`stitch/udaan_core/DESIGN.md`).
///
/// Static fields are **Stitch defaults** for const widgets and tests.
/// For screens that have [AppBranding] / [BrandColors] from `GET /config`,
/// use [fromBranding] or [BrandColors.udaanPalette] so `primary`, `onPrimary`,
/// `secondary`, and `error` follow WordPress when they differ from Stitch.
abstract final class UdaanColors {
  static const Color background = Color(0xFF131313);
  static const Color onBackground = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFE3BFB1);
  static const Color stitchPrimary = Color(0xFFFF6000);
  static const Color primary = stitchPrimary;
  static const Color primaryGlow = Color(0xFFFFB598);
  static const Color outlineVariant = Color(0xFF5B4137);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainer = Color(0xFF20201F);
  static const Color stitchOnPrimary = Color(0xFF1A1A1A);
  static const Color onPrimary = stitchOnPrimary;
  static const Color hint = Color(0xFFAA8A7D);
  static const Color stitchError = Color(0xFFDC2626);
  static const Color error = stitchError;
  static const Color stitchSecondary = Color(0xFF68DBAE);
  static const Color secondary = stitchSecondary;
  static const Color onSurfaceMuted = Color(0xFF939494);

  /// Stitch defaults aligned with [BrandColors.defaults] for merge comparisons.
  static const BrandColors stitchBrandDefaults = BrandColors(
    primary: stitchPrimary,
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF1D9E75),
    surface: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFF1A1A1A),
    error: stitchError,
  );

  /// Resolves Udaan Core colors, overlaying [branding] when API values differ
  /// from Stitch (see `stitch/udaan_core/DESIGN.md`).
  static UdaanPalette fromBranding(BrandColors branding) {
    return UdaanPalette._merge(branding);
  }

  /// Convenience when only [primary] is needed from config.
  static Color primaryFrom(BrandColors branding) {
    return fromBranding(branding).primary;
  }

  static Color _mergeColor(Color remote, Color stitch) {
    return remote == stitch ? stitch : remote;
  }
}

/// Runtime palette for Udaan Core (auth / splash) with optional WP overrides.
class UdaanPalette {
  const UdaanPalette({
    required this.background,
    required this.onBackground,
    required this.onSurfaceVariant,
    required this.primary,
    required this.primaryGlow,
    required this.outlineVariant,
    required this.surfaceContainerHigh,
    required this.surfaceContainer,
    required this.onPrimary,
    required this.hint,
    required this.error,
    required this.secondary,
    required this.onSurfaceMuted,
  });

  factory UdaanPalette.stitch() => UdaanPalette._merge(BrandColors.defaults);

  /// High-visibility palette for low-vision users (Settings → High contrast).
  factory UdaanPalette.highContrast() {
    return const UdaanPalette(
      background: Color(0xFF000000),
      onBackground: Color(0xFFFFFFFF),
      onSurfaceVariant: Color(0xFFFFFFFF),
      primary: Color(0xFFFF6000),
      primaryGlow: Color(0xFFFFFFFF),
      outlineVariant: Color(0xFFFFFFFF),
      surfaceContainerHigh: Color(0xFF1A1A1A),
      surfaceContainer: Color(0xFF000000),
      onPrimary: Color(0xFF000000),
      hint: Color(0xFFCCCCCC),
      error: Color(0xFFFF6B6B),
      secondary: Color(0xFF68DBAE),
      onSurfaceMuted: Color(0xFFE0E0E0),
    );
  }

  factory UdaanPalette._merge(BrandColors branding) {
    return UdaanPalette(
      background: UdaanColors.background,
      onBackground: UdaanColors.onBackground,
      onSurfaceVariant: UdaanColors.onSurfaceVariant,
      primary: UdaanColors._mergeColor(
        branding.primary,
        UdaanColors.stitchPrimary,
      ),
      primaryGlow: UdaanColors.primaryGlow,
      outlineVariant: UdaanColors.outlineVariant,
      surfaceContainerHigh: UdaanColors.surfaceContainerHigh,
      surfaceContainer: UdaanColors.surfaceContainer,
      onPrimary: UdaanColors._mergeColor(
        branding.onPrimary,
        UdaanColors.stitchOnPrimary,
      ),
      hint: UdaanColors.hint,
      error: UdaanColors._mergeColor(branding.error, UdaanColors.stitchError),
      secondary: UdaanColors._mergeColor(
        branding.secondary,
        UdaanColors.stitchSecondary,
      ),
      onSurfaceMuted: UdaanColors.onSurfaceMuted,
    );
  }

  final Color background;
  final Color onBackground;
  final Color onSurfaceVariant;
  final Color primary;
  final Color primaryGlow;
  final Color outlineVariant;
  final Color surfaceContainerHigh;
  final Color surfaceContainer;
  final Color onPrimary;
  final Color hint;
  final Color error;
  final Color secondary;
  final Color onSurfaceMuted;
}

/// WordPress `branding.colors` → Udaan Core palette.
extension BrandColorsUdaan on BrandColors {
  UdaanPalette get udaanPalette => UdaanColors.fromBranding(this);
}
