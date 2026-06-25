import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_branding.dart';
import '../../core/config/app_copy_accessors.dart';
import 'radio_audio_handler.dart';

RadioAudioHandler? _handler;
bool _backgroundControlsEnabled = false;

/// True when a live radio player is available (background service or in-app fallback).
bool get isRadioAudioServiceReady => _handler != null;

/// True when lock-screen / notification controls were registered via [AudioService].
bool get isRadioBackgroundPlaybackEnabled => _backgroundControlsEnabled;

/// Initializes background audio + lock-screen / notification controls.
Future<bool> initRadioAudioService() async {
  if (_handler != null) return true;

  final config = AudioServiceConfig(
    androidNotificationChannelId:
        'com.radioudaan.radio_udaan_app.channel.radio',
    androidNotificationChannelName: AppCopy.fallback.tabRadio,
    androidStopForegroundOnPause: false,
  );

  for (var attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }
    try {
      _handler = await AudioService.init(
        builder: () => RadioAudioHandler(),
        config: config,
      );
      _backgroundControlsEnabled = true;
      return true;
    } catch (e, st) {
      debugPrint(
        'Radio audio service init attempt ${attempt + 1} failed: $e\n$st',
      );
      _handler = null;
      _backgroundControlsEnabled = false;
    }
  }

  // Last resort: in-app playback without background notification controls.
  try {
    _handler = RadioAudioHandler();
    _backgroundControlsEnabled = false;
    debugPrint(
      'Radio audio: using in-app player fallback (background controls unavailable).',
    );
    return true;
  } catch (e, st) {
    debugPrint('Radio audio fallback init failed: $e\n$st');
    _handler = null;
    _backgroundControlsEnabled = false;
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
