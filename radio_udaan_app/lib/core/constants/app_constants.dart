/// Build-time and client metadata sent to the App API.
abstract final class AppConstants {
  /// Sent in registration payloads; must match `pubspec.yaml` version.
  static const String appVersion = '0.1.0';

  static const String clientPlatform = 'flutter';

  static const Duration apiConnectTimeout = Duration(seconds: 12);
  static const Duration apiReceiveTimeout = Duration(seconds: 20);
}
