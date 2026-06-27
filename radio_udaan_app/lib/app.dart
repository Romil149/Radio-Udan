import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/accessibility_scope.dart';
import 'core/theme/udaan_colors.dart';
import 'core/theme/udaan_theme.dart';
import 'core/widgets/dismiss_keyboard.dart';

/// Root widget: WordPress-driven theme, routing, accessibility defaults.
class RadioUdaanApp extends ConsumerWidget {
  const RadioUdaanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final branding = ref.watch(appBrandingProvider);
    final settings = ref.watch(appSettingsProvider);
    final palette = settings.highContrast
        ? UdaanPalette.highContrast()
        : branding.colors.udaanPalette;
    final theme = UdaanTheme.fromPalette(
      palette: palette,
      branding: branding,
      settings: settings,
    );
    final settingsKey = Object.hash(
      settings.highContrast,
      settings.textScale,
      settings.boldText,
      settings.reduceMotion,
    );

    return MaterialApp.router(
      key: ValueKey(settingsKey),
      title: branding.appName,
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return AccessibilityScope(
          settings: settings,
          palette: palette,
          child: MediaQuery(
            data: media.copyWith(
              textScaler: TextScaler.linear(settings.textScale),
              disableAnimations: settings.reduceMotion,
            ),
            child: DefaultTextStyle.merge(
              style: settings.boldText
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : const TextStyle(),
              child: DismissKeyboard(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
