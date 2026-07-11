import 'package:flutter/foundation.dart';

/// Build-time defaults. Override with `--dart-define=API_BASE_URL=...` for other environments.
class AppEnv {
  AppEnv._();

  static const String _apiBaseFromEnv = String.fromEnvironment('API_BASE_URL');

  static const String productionApiBaseUrl =
      'https://radioudaan.com/wp-json/radioudaan/v1';


  /// Bootstrap URL for the first `GET /config` (must reach a live API).
  ///
  /// Precedence: `--dart-define=API_BASE_URL=...` wins; Flutter web defaults to
  /// production (site is live); device/debug without defines uses local.
  static String get bootstrapApiBaseUrl {
    if (_apiBaseFromEnv.isNotEmpty) return _apiBaseFromEnv;
    if (kIsWeb) return productionApiBaseUrl;
    return localApiBaseUrl;
  }

  static const String appName = 'Radio Udaan';
}
