import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/monitoring/crash_reporting.dart';
import 'core/push/push_notification_service.dart';

/// Firebase / Crashlytics must never hang forever on LaunchScreen (App Store 2.1).
Future<void> _safeInit() async {
  try {
    await PushNotificationService.ensureFirebase()
        .timeout(const Duration(seconds: 6));
  } catch (_) {}
  try {
    await CrashReporting.init().timeout(const Duration(seconds: 4));
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _safeInit();
  runApp(
    const ProviderScope(
      child: RadioUdaanApp(),
    ),
  );
}
