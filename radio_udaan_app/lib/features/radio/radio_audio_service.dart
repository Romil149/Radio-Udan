import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/app_strings.dart';
import 'radio_audio_handler.dart';

RadioAudioHandler? _handler;

/// True when background audio was initialized successfully.
bool get isRadioAudioServiceReady => _handler != null;

/// Initializes background audio + lock-screen / notification controls.
Future<bool> initRadioAudioService() async {
  if (_handler != null) return true;

  try {
    _handler = await AudioService.init(
      builder: () => RadioAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.radioudaan.radio_udaan_app.channel.radio',
        androidNotificationChannelName: AppStrings.tabRadio,
        androidNotificationOngoing: true,
      ),
    );
    return true;
  } catch (e, st) {
    debugPrint('Radio audio service init failed: $e\n$st');
    _handler = null;
    return false;
  }
}

/// Retries audio init when cold-start init failed (common on some Android builds).
Future<bool> ensureRadioAudioService() => initRadioAudioService();

RadioAudioHandler get radioAudioHandler {
  final handler = _handler;
  if (handler == null) {
    throw StateError('initRadioAudioService() must run before using radio');
  }
  return handler;
}
