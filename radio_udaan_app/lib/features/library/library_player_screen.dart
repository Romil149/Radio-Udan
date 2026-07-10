import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/accessibility/udaan_semantics.dart';
import '../../core/models/youtube_video.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/brand_app_bar.dart';
import 'library_formatters.dart';
import 'library_image_url.dart';

/// Mobile WebView embed params — `youtube-nocookie` origin avoids YouTube error 15/153.
const _libraryYoutubeParams = YoutubePlayerParams(
  showControls: false,
  showFullscreenButton: false,
  origin: 'https://www.youtube-nocookie.com',
  enableCaption: true,
  showVideoAnnotations: false,
  playsInline: true,
  pointerEvents: PointerEvents.none,
);

const _playbackStartTimeout = Duration(seconds: 15);

/// In-app YouTube playback with Udaan chrome (IFrame API — stream only, store compliant).
class LibraryPlayerScreen extends ConsumerStatefulWidget {
  const LibraryPlayerScreen({required this.video, super.key});

  final YoutubeVideo video;

  @override
  ConsumerState<LibraryPlayerScreen> createState() => _LibraryPlayerScreenState();
}

class _LibraryPlayerScreenState extends ConsumerState<LibraryPlayerScreen> {
  AppCopy get _copy => ref.read(appCopyProvider);

  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  StreamSubscription<YoutubeVideoState>? _videoStateSubscription;
  Timer? _playbackTimeoutTimer;
  PlayerState? _lastAnnouncedPlayerState;
  bool _playerError = false;
  bool _startingPlayback = false;
  bool _isPlaying = false;

  String? get _videoId {
    return YoutubePlayerController.convertUrlToId(widget.video.watchUrl) ??
        (widget.video.id.trim().isNotEmpty ? widget.video.id.trim() : null);
  }

  void _announce(String message) {
    announce(context, message);
  }

  @override
  void dispose() {
    _cancelPlaybackTimeout();
    _playerSubscription?.cancel();
    _videoStateSubscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  void _onPlaybackStarted({bool announce = true}) {
    _cancelPlaybackTimeout();
    if (!mounted) return;
    // Always clear the loader when real playback is detected — even if
    // `_isPlaying` was already true from a flaky prior state event.
    setState(() {
      _startingPlayback = false;
      _isPlaying = true;
    });
    if (announce && _lastAnnouncedPlayerState != PlayerState.playing) {
      _lastAnnouncedPlayerState = PlayerState.playing;
      _announce('${_copy.libraryPlayVideo}. ${widget.video.title}');
    }
  }

  bool _isAudiblePlaybackState(PlayerState state) {
    return state == PlayerState.playing || state == PlayerState.buffering;
  }

  /// Single source of truth for iframe [PlayerState] → UI flags.
  ///
  /// Iframe often emits [PlayerState.unknown] / [PlayerState.cued] /
  /// [PlayerState.unStarted] while audio continues — those must not flip
  /// `_isPlaying` to false once playback has started.
  void _applyPlayerState(PlayerState state) {
    switch (state) {
      case PlayerState.playing:
      case PlayerState.buffering:
        _onPlaybackStarted();
        break;
      case PlayerState.paused:
        _cancelPlaybackTimeout();
        if (!mounted) return;
        setState(() {
          _startingPlayback = false;
          _isPlaying = false;
        });
        if (_lastAnnouncedPlayerState != PlayerState.paused) {
          _lastAnnouncedPlayerState = PlayerState.paused;
          _announce(_copy.libraryPlayerPaused);
        }
        break;
      case PlayerState.ended:
        _cancelPlaybackTimeout();
        if (!mounted) return;
        setState(() {
          _startingPlayback = false;
          _isPlaying = false;
        });
        _lastAnnouncedPlayerState = PlayerState.ended;
        break;
      case PlayerState.unknown:
      case PlayerState.unStarted:
      case PlayerState.cued:
        // Keep `_isPlaying` as-is; poll / position / timeout resolve starting.
        break;
    }
  }


  Future<void> _pollUntilPlaybackStarts(YoutubePlayerController controller) async {
    const pollInterval = Duration(milliseconds: 400);
    final deadline = DateTime.now().add(_playbackStartTimeout);

    while (mounted && _startingPlayback && DateTime.now().isBefore(deadline)) {
      try {
        final state = await controller.playerState;
        if (_isAudiblePlaybackState(state)) {
          _onPlaybackStarted();
          return;
        }
        if (state == PlayerState.paused || state == PlayerState.ended) {
          _applyPlayerState(state);
          return;
        }
        final elapsed = await controller.currentTime;
        if (elapsed > 0.1) {
          _onPlaybackStarted();
          return;
        }
        final loaded = await controller.videoLoadedFraction;
        if (loaded > 0.05 && elapsed > 0) {
          _onPlaybackStarted();
          return;
        }
      } catch (_) {
        // Player iframe may not be ready yet.
      }
      await Future<void>.delayed(pollInterval);
    }
  }

  /// One-shot probe shortly after load — catches playback when state events lag.
  Future<void> _probePlaybackAfterLoad(YoutubePlayerController controller) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted || !_startingPlayback) return;
    try {
      final state = await controller.playerState;
      if (_isAudiblePlaybackState(state)) {
        _onPlaybackStarted();
        return;
      }
      final elapsed = await controller.currentTime;
      if (elapsed > 0.1) {
        _onPlaybackStarted();
      }
    } catch (_) {
      // Iframe may still be initializing.
    }
  }

  void _cancelPlaybackTimeout() {
    _playbackTimeoutTimer?.cancel();
    _playbackTimeoutTimer = null;
  }

  void _startPlaybackTimeout() {
    _cancelPlaybackTimeout();
    _playbackTimeoutTimer = Timer(_playbackStartTimeout, () {
      if (!mounted || !_startingPlayback) return;
      _handlePlayerFailure();
    });
  }

  void _handlePlayerFailure() {
    _cancelPlaybackTimeout();
    if (!mounted) return;
    if (_playerError && !_startingPlayback) return;
    setState(() {
      _playerError = true;
      _startingPlayback = false;
    });
    announce(context, _copy.libraryEmbedError);
  }

  void _bindPlayerListener(YoutubePlayerController controller) {
    _playerSubscription?.cancel();
    _videoStateSubscription?.cancel();

    _playerSubscription = controller.listen((value) {
      if (value.hasError) {
        _handlePlayerFailure();
        return;
      }
      _applyPlayerState(value.playerState);
    });

    _videoStateSubscription = controller.videoStateStream.listen((state) {
      if (state.position.inMilliseconds > 100) {
        _onPlaybackStarted();
      }
    });
  }

  Future<void> _loadAndPlay(YoutubePlayerController controller, String videoId) async {
    unawaited(_pollUntilPlaybackStarts(controller));
    try {
      await controller.loadVideoById(videoId: videoId);
      // loadVideoById auto-plays; do not await playVideo — it can hang after playback starts.
      unawaited(controller.playVideo());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_probePlaybackAfterLoad(controller));
      });
    } catch (_) {
      _handlePlayerFailure();
    }
  }

  Future<void> _startPlayback() async {
    final videoId = _videoId;
    if (videoId == null || _startingPlayback) return;

    setState(() {
      _startingPlayback = true;
      _playerError = false;
    });
    _startPlaybackTimeout();

    try {
      final controller = _controller;
      if (controller == null) {
        final created = YoutubePlayerController(
          params: _libraryYoutubeParams,
          key: videoId,
          onWebResourceError: (_) => _handlePlayerFailure(),
        );
        _controller = created;
        _bindPlayerListener(created);
        if (mounted) setState(() {});
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_loadAndPlay(created, videoId));
        });
      } else {
        unawaited(_pollUntilPlaybackStarts(controller));
        unawaited(controller.playVideo());
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(_probePlaybackAfterLoad(controller));
        });
      }
    } catch (_) {
      _handlePlayerFailure();
    }
  }

  void _pausePlayback() {
    final controller = _controller;
    if (controller == null) return;
    _cancelPlaybackTimeout();
    if (!mounted) return;
    setState(() {
      _startingPlayback = false;
      _isPlaying = false;
    });
    if (_lastAnnouncedPlayerState != PlayerState.paused) {
      _lastAnnouncedPlayerState = PlayerState.paused;
      _announce(_copy.libraryPlayerPaused);
    }
    // Do not await — pauseVideo can hang the same way playVideo can.
    unawaited(_pauseVideoSafe(controller));
  }

  Future<void> _pauseVideoSafe(YoutubePlayerController controller) async {
    try {
      await controller.pauseVideo();
    } catch (_) {
      _handlePlayerFailure();
    }
  }

  Widget _buildVideoRegion({
    required AppCopy copy,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: copy.libraryPlayVideo,
          hint: copy.libraryPlayerNativeHint,
          child: ExcludeSemantics(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: child,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _LibraryNativeControls(
          copy: copy,
          enabled: !_playerError,
          loading: _startingPlayback,
          isPlaying: _isPlaying,
          onPlay: () => unawaited(_startPlayback()),
          onPause: _pausePlayback,
        ),
      ],
    );
  }

  void _resetPlayer() {
    _cancelPlaybackTimeout();
    _playerSubscription?.cancel();
    _videoStateSubscription?.cancel();
    _controller?.close();
    setState(() {
      _controller = null;
      _playerError = false;
      _startingPlayback = false;
      _isPlaying = false;
      _lastAnnouncedPlayerState = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final video = widget.video;
    final controller = _controller;
    final videoId = _videoId;
    final thumbnailUrl = libraryThumbnailFor(ref, video);
    final description = summarizeYoutubeDescription(video.description);
    final duration = video.displayDuration;
    final uploaded = video.publishedAtDate != null
        ? formatLibraryRelativeDate(video.publishedAtDate!, copy)
        : '';

    if (videoId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: BrandAppBar(title: video.title),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(BrandTokens.screenPadding),
            child: Semantics(
              label: copy.libraryNoVideo,
              liveRegion: true,
              child: Card(
                color: context.udaan.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ExcludeSemantics(
                    child: Text(
                      copy.libraryNoVideo,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final metadata = _PlayerMetadata(
      copy: copy,
      video: video,
      description: description,
      duration: duration,
      uploaded: uploaded,
      playerError: _playerError,
      onRetry: _resetPlayer,
    );

    if (controller == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: BrandAppBar(title: video.title),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(BrandTokens.screenPadding),
            children: [
              _buildVideoRegion(
                copy: copy,
                title: video.title,
                child: _TapToPlayPoster(
                  copy: copy,
                  title: video.title,
                  thumbnailUrl: thumbnailUrl,
                  loading: _startingPlayback,
                  onPlay: () => unawaited(_startPlayback()),
                ),
              ),
              metadata,
            ],
          ),
        ),
      );
    }

    return YoutubePlayerScaffold(
      controller: controller,
      aspectRatio: 16 / 9,
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: BrandAppBar(title: video.title),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(BrandTokens.screenPadding),
              children: [
                _buildVideoRegion(
                  copy: copy,
                  title: video.title,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      player,
                      if (_startingPlayback)
                        ColoredBox(
                          color: context.udaan.scrim,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: context.udaan.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                metadata,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlayerMetadata extends StatelessWidget {
  const _PlayerMetadata({
    required this.copy,
    required this.video,
    required this.description,
    required this.duration,
    required this.uploaded,
    required this.playerError,
    required this.onRetry,
  });

  final AppCopy copy;
  final YoutubeVideo video;
  final String description;
  final String duration;
  final String uploaded;
  final bool playerError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (playerError) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: copy.libraryEmbedError,
            child: ExcludeSemantics(
              child: Text(
                copy.libraryEmbedError,
                style: TextStyle(
                  color: context.udaan.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: copy.retry,
            child: ExcludeSemantics(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: Icon(Icons.refresh),
                label: Text(copy.retry),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (duration.isNotEmpty || uploaded.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (duration.isNotEmpty)
                _MetaChip(
                  icon: Icons.schedule_outlined,
                  label: '${copy.libraryDurationPrefix}$duration',
                ),
              if (uploaded.isNotEmpty)
                _MetaChip(
                  icon: Icons.calendar_today_outlined,
                  label: uploaded,
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        if (description.isNotEmpty)
          Semantics(
            label: description,
            child: ExcludeSemantics(
              child: Text(
                description,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.udaan.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          )
        else
          Text(
            copy.libraryNoDescription,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: context.udaan.onSurfaceMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 16),
        Semantics(
          label: copy.libraryYoutubeAttribution,
          child: ExcludeSemantics(
            child: Text(
              copy.libraryYoutubeAttribution,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.udaan.onSurfaceMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LibraryNativeControls extends StatelessWidget {
  const _LibraryNativeControls({
    required this.copy,
    required this.enabled,
    required this.loading,
    required this.isPlaying,
    required this.onPlay,
    required this.onPause,
  });

  final AppCopy copy;
  final bool enabled;
  final bool loading;
  final bool isPlaying;
  final VoidCallback onPlay;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Semantics(
        button: true,
        enabled: false,
        label: copy.libraryPlayVideo,
        child: ExcludeSemantics(
          child: FilledButton.icon(
            onPressed: null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
            icon: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: context.udaan.onPrimary.withValues(alpha: 0.7),
              ),
            ),
            label: Text(copy.libraryPlayVideo),
          ),
        ),
      );
    }

    final showPause = isPlaying;
    final label = showPause ? copy.libraryPauseVideo : copy.libraryPlayVideo;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: ExcludeSemantics(
        child: FilledButton.icon(
          onPressed: !enabled ? null : (showPause ? onPause : onPlay),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
          ),
          icon: Icon(
            showPause ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(label),
        ),
      ),
    );
  }
}

class _TapToPlayPoster extends StatelessWidget {
  const _TapToPlayPoster({
    required this.copy,
    required this.title,
    required this.thumbnailUrl,
    required this.onPlay,
    this.loading = false,
  });

  final AppCopy copy;
  final String title;
  final String thumbnailUrl;
  final VoidCallback onPlay;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Material(
        color: context.udaan.surfaceContainer,
        child: InkWell(
          onTap: loading ? null : onPlay,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (thumbnailUrl.isNotEmpty)
                ExcludeSemantics(
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    memCacheHeight: 360,
                    placeholder: (_, _) => const _PosterPlaceholder(),
                    errorWidget: (_, _, _) => const _PosterPlaceholder(),
                  ),
                )
              else
                const _PosterPlaceholder(),
              Container(
                color: context.udaan.scrim.withValues(alpha: 0.25),
              ),
              Center(
                child: loading
                    ? CircularProgressIndicator(color: context.udaan.primary)
                    : ExcludeSemantics(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: context.udaan.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: context.udaan.onPrimary,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              copy.libraryTapToPlay,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: context.udaan.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.udaan.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 48,
          color: context.udaan.onSurfaceMuted.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.udaan.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.udaan.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 16, color: context.udaan.primaryGlow),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: Text(
                label,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.udaan.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
