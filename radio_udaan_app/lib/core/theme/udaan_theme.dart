import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_branding.dart';
import 'udaan_colors.dart';

/// Stitch Udaan Core dark theme; merges WP [AppBranding] primary into palette.
class UdaanTheme {
  UdaanTheme._();

  static ThemeData dark(AppBranding branding) {
    final primary = branding.colors.primary;
    final onPrimary = branding.colors.onPrimary;
    final error = branding.colors.error;

    final colorScheme = ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      secondary: UdaanColors.secondary,
      surface: UdaanColors.surfaceContainer,
      onSurface: UdaanColors.onBackground,
      error: error,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UdaanColors.background,
      textTheme: GoogleFonts.atkinsonHyperlegibleTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: UdaanColors.onBackground,
        displayColor: UdaanColors.onBackground,
      ),
    );

    return base.copyWith(
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: UdaanColors.surfaceContainerHigh,
        indicatorColor: primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.atkinsonHyperlegible(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? primary : UdaanColors.onSurfaceMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primary : UdaanColors.onSurfaceMuted,
          );
        }),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: UdaanColors.surfaceContainerHigh,
        foregroundColor: UdaanColors.onBackground,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: UdaanColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: UdaanColors.outlineVariant),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: UdaanColors.primaryGlow,
        textColor: UdaanColors.onBackground,
      ),
      dividerTheme: const DividerThemeData(color: UdaanColors.outlineVariant),
    );
  }

  /// Stronger borders and higher contrast for low-vision users.
  static ThemeData highContrast(AppBranding branding) {
    final base = dark(branding);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.black,
      colorScheme: base.colorScheme.copyWith(
        surface: Colors.black,
        onSurface: Colors.white,
        primary: UdaanColors.primary,
        onPrimary: Colors.black,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: UdaanColors.primary, width: 3),
        ),
      ),
    );
  }
}
