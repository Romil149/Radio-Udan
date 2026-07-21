/// Build-time and client metadata sent to the App API.
abstract final class AppConstants {
  /// Android marketing version (`pubspec` 3.0.0+N). iOS store builds stay on
  /// 2.0.0 via `ios/Flutter/{Debug,Release}.xcconfig` overrides.
  static const String appVersion = '3.0.0';

  static const String clientPlatform = 'flutter';

  static const Duration apiConnectTimeout = Duration(seconds: 12);
  static const Duration apiReceiveTimeout = Duration(seconds: 20);
}
