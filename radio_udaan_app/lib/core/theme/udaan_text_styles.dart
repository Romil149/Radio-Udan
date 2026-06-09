import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'accessibility_scope.dart';

/// Atkinson Hyperlegible text that respects bold accessibility setting.
TextStyle udaanTextStyle(
  BuildContext context, {
  double fontSize = 16,
  FontWeight? fontWeight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  final bold = AccessibilityScope.settingsOf(context).boldText;
  final resolvedWeight = bold
      ? FontWeight.w700
      : (fontWeight ?? FontWeight.w400);

  return GoogleFonts.atkinsonHyperlegible(
    fontSize: fontSize,
    fontWeight: resolvedWeight,
    color: color ?? context.udaan.onBackground,
    height: height,
    letterSpacing: letterSpacing,
  );
}
