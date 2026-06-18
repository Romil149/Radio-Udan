import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/monitoring/crash_reporting.dart';
import 'core/push/push_notification_service.dart';
import 'features/radio/radio_audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.ensureFirebase();
  await CrashReporting.init();
  // Radio init is retried from Radio tab / Play; avoid blocking first frame.
  runApp(
    const ProviderScope(
      child: RadioUdaanApp(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initRadioAudioService();
  });
}
