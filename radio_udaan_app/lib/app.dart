import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/providers/app_settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/accessibility_scope.dart';
import 'core/theme/udaan_colors.dart';
import 'core/theme/udaan_theme.dart';

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
    final theme = settings.highContrast
        ? UdaanTheme.highContrast(branding)
        : UdaanTheme.dark(branding);

    return MaterialApp.router(
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
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
