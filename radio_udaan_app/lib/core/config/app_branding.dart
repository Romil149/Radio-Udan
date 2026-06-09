import 'package:flutter/material.dart';

import '../constants/app_strings.dart';

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
  const AppCopy({
    required this.bootstrapLoading,
    required this.signInIntro,
    required this.verifyIntro,
    required this.radioIntro,
    required this.radioLiveLabel,
    required this.tabRadio,
    required this.tabLibrary,
    required this.tabEvents,
    required this.tabMore,
    required this.eventsEmpty,
    required this.libraryShows,
    required this.libraryWhatsNew,
    required this.libraryShowsEmpty,
    required this.libraryWhatsNewEmpty,
    required this.submitRegistration,
    required this.registrationSuccessPrefix,
    required this.unsupportedFieldsNotice,
  });

  factory AppCopy.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return AppCopy.fallback;
    }
    String pick(String key, String fallback) {
      final v = json[key]?.toString().trim() ?? '';
      return v.isNotEmpty ? v : fallback;
    }
    final f = AppCopy.fallback;
    return AppCopy(
      bootstrapLoading: pick('bootstrap_loading', f.bootstrapLoading),
      signInIntro: pick('sign_in_intro', f.signInIntro),
      verifyIntro: pick('verify_intro', f.verifyIntro),
      radioIntro: pick('radio_intro', f.radioIntro),
      radioLiveLabel: pick('radio_live_label', f.radioLiveLabel),
      tabRadio: pick('tab_radio', f.tabRadio),
      tabLibrary: pick('tab_library', f.tabLibrary),
      tabEvents: pick('tab_events', f.tabEvents),
      tabMore: pick('tab_more', f.tabMore),
      eventsEmpty: pick('events_empty', f.eventsEmpty),
      libraryShows: pick('library_shows', f.libraryShows),
      libraryWhatsNew: pick('library_whats_new', f.libraryWhatsNew),
      libraryShowsEmpty: pick('library_shows_empty', f.libraryShowsEmpty),
      libraryWhatsNewEmpty: pick('library_whats_new_empty', f.libraryWhatsNewEmpty),
      submitRegistration: pick('submit_registration', f.submitRegistration),
      registrationSuccessPrefix: pick(
        'registration_success_prefix',
        f.registrationSuccessPrefix,
      ),
      unsupportedFieldsNotice: pick(
        'unsupported_fields_notice',
        f.unsupportedFieldsNotice,
      ),
    );
  }

  static final AppCopy fallback = AppCopy(
    bootstrapLoading: AppStrings.bootstrapLoading,
    signInIntro: AppStrings.signInIntro,
    verifyIntro: AppStrings.verifyIntroManual,
    radioIntro:
        'Listen to Radio Udaan live — community radio by and for persons with disabilities.',
    radioLiveLabel: 'Live now',
    tabRadio: AppStrings.tabRadio,
    tabLibrary: AppStrings.tabLibrary,
    tabEvents: AppStrings.tabEvents,
    tabMore: AppStrings.tabMore,
    eventsEmpty: AppStrings.eventsEmpty,
    libraryShows: AppStrings.libraryPlaylists,
    libraryWhatsNew: AppStrings.libraryRecentUploads,
    libraryShowsEmpty: AppStrings.libraryPlaylistsEmpty,
    libraryWhatsNewEmpty: AppStrings.libraryRecentUploadsEmpty,
    submitRegistration: AppStrings.submitRegistration,
    registrationSuccessPrefix: AppStrings.registrationSuccessPrefix,
    unsupportedFieldsNotice: AppStrings.unsupportedFieldsNotice,
  );

  final String bootstrapLoading;
  final String signInIntro;
  final String verifyIntro;
  final String radioIntro;
  final String radioLiveLabel;
  final String tabRadio;
  final String tabLibrary;
  final String tabEvents;
  final String tabMore;
  final String eventsEmpty;
  final String libraryShows;
  final String libraryWhatsNew;
  final String libraryShowsEmpty;
  final String libraryWhatsNewEmpty;
  final String submitRegistration;
  final String registrationSuccessPrefix;
  final String unsupportedFieldsNotice;
}
