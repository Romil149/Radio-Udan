import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/azuracast_now_playing.dart';
import '../../core/providers/app_providers.dart';

/// Lightweight Dio client for AzuraCast (separate from WP App API).
final _azuracastDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'Accept': 'application/json'},
    ),
  );
});

/// Live stream metadata fetched directly from AzuraCast (not GET /config).
final azuracastNowPlayingProvider =
    NotifierProvider<AzuracastNowPlayingNotifier, AzuraCastNowPlaying?>(
  AzuracastNowPlayingNotifier.new,
);

class AzuracastNowPlayingNotifier extends Notifier<AzuraCastNowPlaying?> {
  Timer? _pollTimer;
  bool _polling = false;

  static const _minPollInterval = Duration(seconds: 15);
  static const _maxPollInterval = Duration(seconds: 90);
  static const _defaultPollInterval = Duration(seconds: 20);

  @override
  AzuraCastNowPlaying? build() {
    ref.onDispose(stopPolling);
    return null;
  }

  /// Call when the Live tab is visible.
  void startPolling() {
    if (_polling) return;
    _polling = true;
    unawaited(refresh());
  }

  void stopPolling() {
    _polling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  static const _defaultNowPlayingApiUrl =
      'https://stream.radioudaan.com/api/nowplaying';

  Future<void> refresh() async {
    if (!_polling) return;

    final configured =
        ref.read(remoteConfigProvider)?.nowPlayingApiUrl?.trim() ?? '';
    final url =
        configured.isNotEmpty ? configured : _defaultNowPlayingApiUrl;

    try {
      final dio = ref.read(_azuracastDioProvider);
      final response = await dio.get<dynamic>(url);
      final parsed = AzuraCastNowPlaying.fromJson(response.data);
      if (parsed != null) {
        state = parsed;
      }
      _scheduleNextPoll(parsed?.remainingSeconds);
    } catch (_) {
      _scheduleNextPoll(null);
    }
  }

  void _scheduleNextPoll(int? remainingSeconds) {
    _pollTimer?.cancel();
    if (!_polling) return;

    Duration delay = _defaultPollInterval;
    if (remainingSeconds != null && remainingSeconds > 5) {
      final trackEnd = Duration(seconds: remainingSeconds + 2);
      if (trackEnd > _minPollInterval && trackEnd < _maxPollInterval) {
        delay = trackEnd;
      } else if (trackEnd >= _maxPollInterval) {
        delay = _maxPollInterval;
      }
    }

    _pollTimer = Timer(delay, () => unawaited(refresh()));
  }
}
