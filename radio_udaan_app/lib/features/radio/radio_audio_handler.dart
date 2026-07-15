import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

/// System media session for live radio (`just_audio` + `audio_service`).
///
/// Lock screen / notification must expose **pause/play** (not stop-only).
/// iOS Control Center and Android media notifications primarily enable those.
class RadioAudioHandler extends BaseAudioHandler {
  RadioAudioHandler() {
    _player.playbackEventStream.listen((_) => _broadcastState());
    _player.playingStream.listen((_) => _broadcastState());
    _player.processingStateStream.listen((_) => _broadcastState());
    _initSession();
    _broadcastState();
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

  /// Loads the live stream URL and starts playback (WP `stream_url` only).
  Future<void> playLiveStream({
    required Uri streamUri,
    required String title,
    required String artist,
    Uri? artUri,
  }) async {
    await _ensureSession();
    final session = await AudioSession.instance;
    await session.setActive(true);
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
      _broadcastState();
      return;
    }

    _loadedStreamUri = streamUri;
    await _player.setAudioSource(AudioSource.uri(streamUri, tag: item));
    await _player.play();
    _broadcastState();
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
  Future<void> play() async {
    await _player.play();
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) async {
    // Live MP3 has no DVR — ignore lock-screen / notification scrubbing.
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    _loadedStreamUri = null;
    mediaItem.add(null);
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {
      // Best-effort — iOS may keep session until next activation.
    }
    _broadcastState();
    await super.stop();
  }

  void _broadcastState() {
    final playing = _player.playing;
    final processing = _player.processingState;
    final hasMedia = mediaItem.valueOrNull != null ||
        processing != ProcessingState.idle ||
        _loadedStreamUri != null;

    final controls = <MediaControl>[
      if (playing) MediaControl.pause else if (hasMedia) MediaControl.play,
      if (playing || hasMedia) MediaControl.stop,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.play,
          MediaAction.pause,
          MediaAction.stop,
        },
        androidCompactActionIndices: controls.isEmpty
            ? const <int>[]
            : List<int>.generate(
                controls.length.clamp(0, 2),
                (i) => i,
              ),
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[processing]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ),
    );
  }
}
