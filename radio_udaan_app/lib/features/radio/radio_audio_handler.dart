import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// System media session for live radio (`just_audio` + `audio_service`).
class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    _initSession();
  }

  final AudioPlayer _player = AudioPlayer();
  bool _sessionReady = false;
  bool _resumeAfterInterruption = false;
  Uri? _loadedStreamUri;

  AudioPlayer get player => _player;

  bool canResumeLiveStream(Uri streamUri) {
    return _loadedStreamUri == streamUri &&
        _player.processingState != ProcessingState.idle;
  }

  Future<void> resumeLiveStream() async {
    await _ensureSession();
    await _player.play();
  }

  Future<void> _initSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    session.becomingNoisyEventStream.listen((_) {
      if (_player.playing) pause();
    });

    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (event.type == AudioInterruptionType.pause ||
            event.type == AudioInterruptionType.unknown) {
          _resumeAfterInterruption = _player.playing;
          if (_player.playing) pause();
        }
      } else if (_resumeAfterInterruption &&
          event.type == AudioInterruptionType.pause) {
        _resumeAfterInterruption = false;
        play();
      }
    });

    _sessionReady = true;
  }

  Future<void> _ensureSession() async {
    if (_sessionReady) return;
    await _initSession();
  }

  /// Silent buffer at volume 0 so ICY `StreamTitle` arrives before the user taps Play.
  Future<void> prepareStreamMetadataProbe({
    required Uri streamUri,
    required String title,
    required String artist,
  }) async {
    await _ensureSession();
    final item = MediaItem(
      id: streamUri.toString(),
      title: title,
      artist: artist,
      album: artist,
      extras: const {'live': true},
    );
    mediaItem.add(item);

    if (!canResumeLiveStream(streamUri)) {
      _loadedStreamUri = streamUri;
      await _player.setVolume(0);
      await _player.setAudioSource(AudioSource.uri(streamUri, tag: item));
    } else if (_player.volume > 0) {
      await _player.setVolume(0);
    }

    if (!_player.playing) {
      await _player.play();
    }
  }

  /// Loads the live stream URL and starts playback (WP `stream_url` only).
  Future<void> playLiveStream({
    required Uri streamUri,
    required String title,
    required String artist,
    Uri? artUri,
  }) async {
    await _ensureSession();
    final item = MediaItem(
      id: streamUri.toString(),
      title: title,
      artist: artist,
      album: artist,
      artUri: artUri,
      extras: const {'live': true},
    );
    mediaItem.add(item);

    if (canResumeLiveStream(streamUri)) {
      await _player.play();
      return;
    }

    _loadedStreamUri = streamUri;
    await _player.setAudioSource(AudioSource.uri(streamUri, tag: item));
    await _player.play();
  }

  /// Updates lock-screen / notification metadata when the on-air show changes.
  void updateNowPlayingMetadata({
    required String title,
    required String artist,
    Uri? artUri,
  }) {
    final current = mediaItem.value;
    if (current == null) return;
    final updated = current.copyWith(
      title: title,
      artist: artist,
      album: artist,
      artUri: artUri,
    );
    mediaItem.add(updated);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) async {
    // Live MP3 has no DVR — ignore lock-screen / notification scrubbing.
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _loadedStreamUri = null;
    await super.stop();
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (_player.playing) MediaControl.stop else MediaControl.play,
      ],
      androidCompactActionIndices: const [0],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
