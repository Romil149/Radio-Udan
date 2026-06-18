import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Registers Flutter and async error handlers with Firebase Crashlytics.
class CrashReporting {
  CrashReporting._();

  /// Call after [PushNotificationService.ensureFirebase] succeeds.
  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) return;

      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);

      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      debugPrint('Crashlytics init skipped: $e');
    }
  }
}
