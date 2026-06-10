import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/push/push_notification_service.dart';
import 'features/radio/radio_audio_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.ensureFirebase();
  try {
    await initRadioAudioService();
  } catch (e, st) {
    debugPrint('Radio audio service init deferred: $e\n$st');
  }
  runApp(
    const ProviderScope(
      child: RadioUdaanApp(),
    ),
  );
}
