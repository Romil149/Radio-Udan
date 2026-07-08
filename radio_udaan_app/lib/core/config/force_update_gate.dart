import 'package:flutter/foundation.dart';

import 'remote_config.dart';

class ForceUpdateState {
  const ForceUpdateState({
    required this.required,
    this.storeUrl,
    this.currentBuild,
  });

  final bool required;
  final String? storeUrl;
  final int? currentBuild;
}

/// Computes whether the app must hard-block and where the user can update.
class ForceUpdateGate {
  // Android fallback (used when WP admin hasn't set Play URL yet).
  static const String androidMarketFallbackUrl =
      'market://details?id=com.radioudaan.radio_udaan_app';

  static ForceUpdateState evaluate({
    required RemoteConfig? config,
    required int? currentBuild,
    TargetPlatform? platform,
  }) {
    if (kDebugMode) {
      // Avoid blocking local `flutter run` builds.
      return const ForceUpdateState(required: false);
    }

    if (config == null) return const ForceUpdateState(required: false);
    if (kIsWeb) return const ForceUpdateState(required: false);
    if (currentBuild == null) return const ForceUpdateState(required: false);

    final policy = config.appUpdate;
    if (!policy.enabled) return const ForceUpdateState(required: false);

    final p = platform ?? defaultTargetPlatform;
    final required = policy.isUpdateRequired(currentBuild, p);
    if (!required) return const ForceUpdateState(required: false);

    final storeUrl = p == TargetPlatform.android
        ? (config.playStoreUrl?.isNotEmpty == true
            ? config.playStoreUrl
            : androidMarketFallbackUrl)
        : config.appStoreUrl;

    return ForceUpdateState(
      required: true,
      storeUrl: storeUrl,
      currentBuild: currentBuild,
    );
  }
}

