import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_branding.dart';
import '../models/app_user_settings.dart';
import 'udaan_colors.dart';

/// Stitch Udaan Core dark theme; merges WP [AppBranding] and accessibility palette.
class UdaanTheme {
  UdaanTheme._();

  static ThemeData fromPalette({
    required UdaanPalette palette,
    required AppBranding branding,
    required AppUserSettings settings,
  }) {
    final baseWeight = settings.boldText ? FontWeight.w700 : FontWeight.w400;
    final colorScheme = ColorScheme.dark(
      primary: palette.primary,
      onPrimary: palette.onPrimary,
      secondary: palette.secondary,
      surface: palette.surfaceContainer,
      onSurface: palette.onBackground,
      error: palette.error,
      onError: Colors.white,
    );

    final textTheme = GoogleFonts.atkinsonHyperlegibleTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: palette.onBackground,
      displayColor: palette.onBackground,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: textTheme,
    );

    final cardBorder = BorderSide(
      color: palette.outlineVariant,
      width: settings.highContrast ? 2 : 1,
    );

    return base.copyWith(
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surfaceContainerHigh,
        indicatorColor: palette.primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.atkinsonHyperlegible(
            fontSize: 12,
            fontWeight: selected
                ? FontWeight.w700
                : (settings.boldText ? FontWeight.w700 : FontWeight.w500),
            color: selected ? palette.primary : palette.onSurfaceMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.primary : palette.onSurfaceMuted,
          );
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.onBackground,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: palette.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: cardBorder,
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: palette.primaryGlow,
        textColor: palette.onBackground,
      ),
      dividerTheme: DividerThemeData(color: palette.outlineVariant),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderSide: cardBorder),
        enabledBorder: OutlineInputBorder(borderSide: cardBorder),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: palette.primary,
            width: settings.highContrast ? 3 : 2,
          ),
        ),
        labelStyle: GoogleFonts.atkinsonHyperlegible(
          fontWeight: baseWeight,
          color: palette.onSurfaceVariant,
        ),
        hintStyle: GoogleFonts.atkinsonHyperlegible(
          fontWeight: baseWeight,
          color: palette.hint,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.onPrimary;
          }
          return palette.onSurfaceMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.primary;
          }
          return palette.surfaceContainerHigh;
        }),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          textStyle: GoogleFonts.atkinsonHyperlegible(fontWeight: baseWeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.onBackground,
          side: BorderSide(color: palette.outlineVariant),
          textStyle: GoogleFonts.atkinsonHyperlegible(fontWeight: baseWeight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.onPrimary,
          textStyle: GoogleFonts.atkinsonHyperlegible(
            fontWeight: settings.boldText ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static ThemeData dark(AppBranding branding) {
    return fromPalette(
      palette: branding.colors.udaanPalette,
      branding: branding,
      settings: const AppUserSettings(),
    );
  }

  /// Stronger borders and higher contrast for low-vision users.
  static ThemeData highContrast(AppBranding branding) {
    return fromPalette(
      palette: UdaanPalette.highContrast(),
      branding: branding,
      settings: const AppUserSettings(highContrast: true, boldText: true),
    );
  }
}
