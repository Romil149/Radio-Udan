import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/providers/app_providers.dart';
import 'android_media_notification_permission.dart';
import 'live_now_playing.dart';
import 'radio_audio_service.dart';
import 'radio_stream_metadata.dart';

/// Live stream UI: idle → loading → playing → idle (Play / Stop only).
enum RadioPlayerStatus { idle, loading, playing, error }

class RadioPlayerState {
  const RadioPlayerState({
    this.status = RadioPlayerStatus.idle,
    this.errorMessage,
  });

  final RadioPlayerStatus status;
  final String? errorMessage;
}

final radioPlayerProvider =
    StateNotifierProvider<RadioPlayerNotifier, RadioPlayerState>((ref) {
  return RadioPlayerNotifier(ref);
});

class RadioPlayerNotifier extends StateNotifier<RadioPlayerState> {
  RadioPlayerNotifier(this._ref) : super(const RadioPlayerState()) {
    if (isRadioAudioServiceReady) {
      attachPlayerIfReady();
    }
  }

  final Ref _ref;
  bool _startInProgress = false;
  bool _playerBound = false;
  bool _metadataProbeInProgress = false;
  int _playbackSession = 0;

  /// Binds just_audio streams after [ensureRadioAudioService] succeeds.
  void attachPlayerIfReady() {
    if (_playerBound || !isRadioAudioServiceReady) return;
    _playerBound = true;
    _bindPlayerStateStream();
  }

  /// Buffer the live stream at volume 0 so ICY title is available before Play.
  Future<void> probeStreamMetadata() async {
    if (_ref.read(radioAudiblePlaybackProvider) ||
        _metadataProbeInProgress ||
        state.status == RadioPlayerStatus.playing ||
        state.status == RadioPlayerStatus.loading) {
      return;
    }

    final copy = _ref.read(appCopyProvider);
    final ready = await ensureRadioAudioService();
    if (!ready) return;
    attachPlayerIfReady();

    final url = _ref.read(remoteConfigProvider)?.streamUrl ?? '';
    if (url.isEmpty) return;

    final config = _ref.read(liveRadioProvider);
    final streamUri = Uri.parse(url);
    final handler = radioAudioHandler;

    _metadataProbeInProgress = true;
    try {
      await handler.prepareStreamMetadataProbe(
        streamUri: streamUri,
        title: config.showTitle,
        artist: config.showSubtitle.isNotEmpty
            ? config.showSubtitle
            : copy.radioLiveLabel,
      );
    } catch (_) {
      // Hero falls back to WP admin title when metadata probe fails.
    } finally {
      _metadataProbeInProgress = false;
    }
  }

  void _bindPlayerStateStream() {
    _ref.listen<LiveNowPlaying>(liveNowPlayingProvider, (previous, next) {
      if (previous?.title == next.title &&
          previous?.hostsLine == next.hostsLine &&
          previous?.imageUrl == next.imageUrl) {
        return;
      }
      if (_ref.read(radioAudiblePlaybackProvider)) {
        _syncNowPlayingMetadata(next);
      }
    });

    final player = radioAudioHandler.player;
    player.icyMetadataStream.listen((metadata) {
      final title = metadata?.info?.title?.trim() ?? '';
      _ref.read(radioStreamIcyTitleProvider.notifier).state =
          title.isEmpty ? null : title;
      if (_ref.read(radioAudiblePlaybackProvider)) {
        _syncNowPlayingMetadata(_ref.read(liveNowPlayingProvider));
      }
    });

    player.playerStateStream.listen((playerState) {
      if (!_ref.read(radioAudiblePlaybackProvider)) {
        // Keep UI on Play when user stopped but the silent metadata probe buffers.
        if ((state.status == RadioPlayerStatus.playing ||
                state.status == RadioPlayerStatus.loading) &&
            !_startInProgress &&
            !_metadataProbeInProgress) {
          state = RadioPlayerState(
            status: RadioPlayerStatus.idle,
            errorMessage: state.errorMessage,
          );
        }
        return;
      }

      if (playerState.playing) {
        state = RadioPlayerState(
          status: RadioPlayerStatus.playing,
          errorMessage: state.errorMessage,
        );
        return;
      }

      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        state = RadioPlayerState(
          status: RadioPlayerStatus.loading,
          errorMessage: state.errorMessage,
        );
      } else if (playerState.processingState == ProcessingState.idle) {
        if (_startInProgress) {
          return;
        }
        state = RadioPlayerState(
          status: RadioPlayerStatus.idle,
          errorMessage: state.errorMessage,
        );
      } else if (playerState.processingState == ProcessingState.ready) {
        if (_startInProgress || state.status == RadioPlayerStatus.loading) {
          return;
        }
        if (state.status != RadioPlayerStatus.playing) {
          state = RadioPlayerState(
            status: RadioPlayerStatus.idle,
            errorMessage: state.errorMessage,
          );
        }
      }
    });
  }

  Future<void> play({double volume = 1.0}) async {
    final copy = _ref.read(appCopyProvider);
    final session = ++_playbackSession;
    await requestAndroidMediaNotificationPermissionIfNeeded();
    final ready = await ensureRadioAudioService();
    if (session != _playbackSession) return;
    if (!ready) {
      state = RadioPlayerState(
        status: RadioPlayerStatus.error,
        errorMessage: copy.radioAudioUnavailable,
      );
      return;
    }
    attachPlayerIfReady();

    final url = _ref.read(remoteConfigProvider)?.streamUrl ?? '';
    if (url.isEmpty) {
      state = RadioPlayerState(
        status: RadioPlayerStatus.error,
        errorMessage: copy.radioStreamMissing,
      );
      return;
    }

    final branding = _ref.read(appBrandingProvider);
    final nowPlaying = _ref.read(liveNowPlayingProvider);

    final streamUri = Uri.parse(url);
    final handler = radioAudioHandler;
    final resumeOnly = handler.canResumeLiveStream(streamUri);

    _ref.read(radioAudiblePlaybackProvider.notifier).state = true;
    _startInProgress = true;
    state = const RadioPlayerState(status: RadioPlayerStatus.loading);
    try {
      final artist = nowPlaying.hostsLine.isNotEmpty
          ? nowPlaying.hostsLine
          : copy.radioLiveLabel;
      final artUri = nowPlaying.imageUrl.isNotEmpty
          ? Uri.tryParse(nowPlaying.imageUrl)
          : (branding.hasLogo ? Uri.tryParse(branding.logoUrl) : null);
      await handler.player.setVolume(volume.clamp(0.0, 1.0));
      if (resumeOnly) {
        handler.updateNowPlayingMetadata(
          title: nowPlaying.title,
          artist: artist,
          artUri: artUri,
        );
        await handler.resumeLiveStream();
      } else {
        await handler.playLiveStream(
          streamUri: streamUri,
          title: nowPlaying.title,
          artist: artist,
          artUri: artUri,
        );
      }
      if (session != _playbackSession) return;
      state = const RadioPlayerState(status: RadioPlayerStatus.playing);
    } catch (e) {
      if (session != _playbackSession) return;
      _ref.read(radioAudiblePlaybackProvider.notifier).state = false;
      state = RadioPlayerState(
        status: RadioPlayerStatus.error,
        errorMessage: copy.radioPlaybackError,
      );
    } finally {
      _startInProgress = false;
    }
  }

  Future<void> stop() async {
    final session = ++_playbackSession;
    _startInProgress = false;
    _ref.read(radioAudiblePlaybackProvider.notifier).state = false;
    _ref.read(radioStreamIcyTitleProvider.notifier).state = null;
    // Optimistic UI — do not wait on audio engine / metadata probe.
    state = const RadioPlayerState(status: RadioPlayerStatus.idle);

    if (!isRadioAudioServiceReady) return;

    try {
      await radioAudioHandler.stop();
    } catch (_) {
      // UI already idle; best-effort engine stop.
    }

    if (session != _playbackSession) return;

    // Refresh ICY title for hero without blocking the stop → play transition.
    unawaited(probeStreamMetadata());
  }

  /// Saves user volume; only changes audio output during intentional live play.
  /// Metadata probe buffers the stream at volume 0 — must not unmute when idle.
  Future<void> applyVolumePreference(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (!_ref.read(radioAudiblePlaybackProvider)) {
      if (!isRadioAudioServiceReady) return;
      try {
        final player = radioAudioHandler.player;
        if (player.playing && player.volume > 0) {
          await player.setVolume(0);
        }
      } catch (_) {}
      return;
    }
    if (!isRadioAudioServiceReady) return;
    try {
      await radioAudioHandler.player.setVolume(clamped);
    } catch (_) {}
  }

  void _syncNowPlayingMetadata(LiveNowPlaying nowPlaying) {
    if (!isRadioAudioServiceReady) return;

    final copy = _ref.read(appCopyProvider);
    final branding = _ref.read(appBrandingProvider);
    final icy = parseRadioStreamTitle(_ref.read(radioStreamIcyTitleProvider));
    final title = icy?.title ?? nowPlaying.title;
    final artist = icy?.artist != null
        ? formatRadioHostsLine(icy!.artist!, copy)
        : (nowPlaying.hostsLine.isNotEmpty
            ? nowPlaying.hostsLine
            : copy.radioLiveLabel);
    final artUri = nowPlaying.imageUrl.isNotEmpty
        ? Uri.tryParse(nowPlaying.imageUrl)
        : (branding.hasLogo ? Uri.tryParse(branding.logoUrl) : null);
    radioAudioHandler.updateNowPlayingMetadata(
      title: title,
      artist: artist,
      artUri: artUri,
    );
  }
}
