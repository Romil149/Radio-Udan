import 'package:audio_service/audio_service.dart';

import '../../core/constants/app_strings.dart';
import 'radio_audio_handler.dart';

RadioAudioHandler? _handler;

/// Initializes background audio + lock-screen / notification controls.
Future<void> initRadioAudioService() async {
  if (_handler != null) return;

  _handler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.radioudaan.radio_udaan_app.channel.radio',
      androidNotificationChannelName: AppStrings.tabRadio,
      androidNotificationOngoing: true,
    ),
  );
}

RadioAudioHandler get radioAudioHandler {
  final handler = _handler;
  if (handler == null) {
    throw StateError('initRadioAudioService() must run before using radio');
  }
  return handler;
}
