import 'package:flutter/foundation.dart';

/// Build-time defaults. Override with `--dart-define=API_BASE_URL=...` for other environments.
class AppEnv {
  AppEnv._();

  static const String _apiBaseFromEnv = String.fromEnvironment('API_BASE_URL');

  static const String stagingApiBaseUrl =
      'https://nexusfleck.com/radioudaan/wp-json/radioudaan/v1';

  static const String localApiBaseUrl =
      'https://radio/wp-json/radioudaan/v1';

  /// Bootstrap URL for the first `GET /config` (must reach a live API).
  ///
  /// Flutter web cannot resolve the local `https://radio` hostname unless
  /// `/etc/hosts` is configured, so web builds default to staging.
  static String get bootstrapApiBaseUrl {
    if (_apiBaseFromEnv.isNotEmpty) return _apiBaseFromEnv;
    if (kIsWeb) return stagingApiBaseUrl;
    return localApiBaseUrl;
  }

  static const String appName = 'Radio Udaan';
}
