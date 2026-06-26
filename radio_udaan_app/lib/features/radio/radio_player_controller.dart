import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/providers/app_providers.dart';
import 'live_now_playing.dart';
import 'radio_audio_service.dart';

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

  /// Binds just_audio streams after [ensureRadioAudioService] succeeds.
  void attachPlayerIfReady() {
    if (_playerBound || !isRadioAudioServiceReady) return;
    _playerBound = true;
    _bindPlayerStateStream();
  }

  void _bindPlayerStateStream() {
    _ref.listen<LiveNowPlaying>(liveNowPlayingProvider, (previous, next) {
      if (previous?.title == next.title &&
          previous?.hostsLine == next.hostsLine &&
          previous?.imageUrl == next.imageUrl) {
        return;
      }
      if (state.status == RadioPlayerStatus.playing ||
          state.status == RadioPlayerStatus.loading) {
        _syncNowPlayingMetadata(next);
      }
    });

    final player = radioAudioHandler.player;
    player.playerStateStream.listen((playerState) {
      // Live MP3 streams often stay in `buffering` while audio is playing.
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
        // Between setAudioSource() and play(), just_audio emits ready + !playing.
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

  Future<void> play() async {
    final copy = _ref.read(appCopyProvider);
    final ready = await ensureRadioAudioService();
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

    _startInProgress = true;
    state = const RadioPlayerState(status: RadioPlayerStatus.loading);
    try {
      final artist = nowPlaying.hostsLine.isNotEmpty
          ? nowPlaying.hostsLine
          : copy.radioLiveLabel;
      final artUri = nowPlaying.imageUrl.isNotEmpty
          ? Uri.tryParse(nowPlaying.imageUrl)
          : (branding.hasLogo ? Uri.tryParse(branding.logoUrl) : null);
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
      state = const RadioPlayerState(status: RadioPlayerStatus.playing);
    } catch (e) {
      state = RadioPlayerState(
        status: RadioPlayerStatus.error,
        errorMessage: copy.radioPlaybackError,
      );
    } finally {
      _startInProgress = false;
    }
  }

  Future<void> stop() async {
    _startInProgress = false;
    if (!isRadioAudioServiceReady) {
      state = const RadioPlayerState(status: RadioPlayerStatus.idle);
      return;
    }
    await radioAudioHandler.stop();
    state = const RadioPlayerState(status: RadioPlayerStatus.idle);
  }

  void _syncNowPlayingMetadata(LiveNowPlaying nowPlaying) {
    if (!isRadioAudioServiceReady) return;

    final copy = _ref.read(appCopyProvider);
    final branding = _ref.read(appBrandingProvider);
    final artist = nowPlaying.hostsLine.isNotEmpty
        ? nowPlaying.hostsLine
        : copy.radioLiveLabel;
    final artUri = nowPlaying.imageUrl.isNotEmpty
        ? Uri.tryParse(nowPlaying.imageUrl)
        : (branding.hasLogo ? Uri.tryParse(branding.logoUrl) : null);
    radioAudioHandler.updateNowPlayingMetadata(
      title: nowPlaying.title,
      artist: artist,
      artUri: artUri,
    );
  }
}
