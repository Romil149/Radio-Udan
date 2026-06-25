import 'package:flutter/material.dart';

import 'app_copy_defaults.dart';

/// Colors and identity from `GET /config` → `branding`.
class AppBranding {
  const AppBranding({
    required this.appName,
    required this.tagline,
    required this.logoUrl,
    required this.colors,
  });

  factory AppBranding.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return AppBranding.defaults;
    }
    final colorsJson = json['colors'] as Map<String, dynamic>? ?? {};
    return AppBranding(
      appName: json['app_name']?.toString().trim() ?? defaults.appName,
      tagline: json['tagline']?.toString().trim() ?? defaults.tagline,
      logoUrl: json['logo_url']?.toString().trim() ?? '',
      colors: BrandColors.fromJson(colorsJson),
    );
  }

  static const AppBranding defaults = AppBranding(
    appName: 'Radio Udaan',
    tagline: 'Community radio by and for persons with disabilities',
    logoUrl: '',
    colors: BrandColors.defaults,
  );

  final String appName;
  final String tagline;
  final String logoUrl;
  final BrandColors colors;

  bool get hasLogo => logoUrl.isNotEmpty;
}

class BrandColors {
  const BrandColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.surface,
    required this.surfaceDark,
    required this.error,
  });

  factory BrandColors.fromJson(Map<String, dynamic> json) {
    return BrandColors(
      primary: _parseColor(json['primary'], defaults.primary),
      onPrimary: _parseColor(json['on_primary'], defaults.onPrimary),
      secondary: _parseColor(json['secondary'], defaults.secondary),
      surface: _parseColor(json['surface'], defaults.surface),
      surfaceDark: _parseColor(json['surface_dark'], defaults.surfaceDark),
      error: _parseColor(json['error'], defaults.error),
    );
  }

  static const BrandColors defaults = BrandColors(
    primary: Color(0xFFFF6B00),
    onPrimary: Color(0xFFFFFFFF),
    secondary: Color(0xFF1D9E75),
    surface: Color(0xFFFFFFFF),
    surfaceDark: Color(0xFF1A1A1A),
    error: Color(0xFFDC2626),
  );

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color surface;
  final Color surfaceDark;
  final Color error;

  static Color _parseColor(dynamic value, Color fallback) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return fallback;
    var hex = raw.toLowerCase();
    if (!hex.startsWith('#')) hex = '#$hex';
    if (hex.length == 4) {
      final r = hex[1];
      final g = hex[2];
      final b = hex[3];
      hex = '#$r$r$g$g$b$b';
    }
    if (hex.length != 7) return fallback;
    final parsed = int.tryParse(hex.substring(1), radix: 16);
    if (parsed == null) return fallback;
    return Color(0xFF000000 | parsed);
  }
}

/// User-visible strings from `GET /config` → `copy`.
class AppCopy {
  const AppCopy({required this.values});

  factory AppCopy.fromJson(Map<String, dynamic>? json) {
    final merged = Map<String, String>.from(appCopyDefaults);
    if (json != null) {
      for (final entry in json.entries) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          merged[entry.key] = value;
        }
      }
    }
    return AppCopy(values: merged);
  }

  static final AppCopy fallback = AppCopy(
    values: Map<String, String>.from(appCopyDefaults),
  );

  final Map<String, String> values;

  String text(String key) => values[key] ?? appCopyDefaults[key] ?? key;
}
