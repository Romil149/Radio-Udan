/// Build-time defaults. Override with `--dart-define` for other environments.
class AppEnv {
  AppEnv._();

  /// Bootstrap URL used for the first `GET /config` (must reach a live API).
  static const String bootstrapApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://radio/wp-json/radioudaan/v1',
  );

  static const String appName = 'Radio Udaan';
}
