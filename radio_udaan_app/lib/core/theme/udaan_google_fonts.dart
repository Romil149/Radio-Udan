import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'accessibility_scope.dart';

/// Atkinson Hyperlegible with accessibility palette + bold setting applied.
TextStyle udaanGoogleFont(
  BuildContext context, {
  double fontSize = 16,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
  FontStyle? fontStyle,
}) {
  final settings = context.accessibilitySettings;
  final palette = context.udaan;
  final resolvedWeight = settings.boldText
      ? FontWeight.w700
      : (fontWeight ?? FontWeight.w500);

  return GoogleFonts.atkinsonHyperlegible(
    fontSize: fontSize,
    fontWeight: resolvedWeight,
    color: color ?? palette.onBackground,
    height: height,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
}
