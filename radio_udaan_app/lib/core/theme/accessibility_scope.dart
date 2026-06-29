import 'package:flutter/material.dart';

import '../models/app_user_settings.dart';
import '../config/app_branding.dart';
import 'udaan_colors.dart';

/// Provides accessibility settings + resolved [UdaanPalette] to the widget tree.
class AccessibilityScope extends InheritedWidget {
  const AccessibilityScope({
    required this.settings,
    required this.palette,
    required super.child,
    super.key,
  });

  final AppUserSettings settings;
  final UdaanPalette palette;

  static AccessibilityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AccessibilityScope>();
  }

  static AppUserSettings settingsOf(BuildContext context) {
    return maybeOf(context)?.settings ?? const AppUserSettings();
  }

  static UdaanPalette paletteOf(BuildContext context) {
    return maybeOf(context)?.palette ??
        UdaanPalette.fromBrand(BrandColors.defaults);
  }

  @override
  bool updateShouldNotify(AccessibilityScope oldWidget) {
    return settings != oldWidget.settings || palette != oldWidget.palette;
  }
}

extension UdaanAccessibilityContext on BuildContext {
  UdaanPalette get udaan => AccessibilityScope.paletteOf(this);

  AppUserSettings get accessibilitySettings =>
      AccessibilityScope.settingsOf(this);

  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
