/// Build-time defaults. Override with `--dart-define=API_BASE_URL=...` when needed.
class AppEnv {
  AppEnv._();

  static const String _apiBaseFromEnv = String.fromEnvironment('API_BASE_URL');

  static const String productionApiBaseUrl =
      'https://radioudaan.com/wp-json/radioudaan/v1';

  /// Bootstrap URL for the first `GET /config`.
  ///
  /// Defaults to [productionApiBaseUrl]. CI release builds also pass
  /// `--dart-define=API_BASE_URL=...` (same production URL).
  static String get bootstrapApiBaseUrl {
    if (_apiBaseFromEnv.isNotEmpty) return _apiBaseFromEnv;
    return productionApiBaseUrl;
  }

  static const String appName = 'Radio Udaan';
}
