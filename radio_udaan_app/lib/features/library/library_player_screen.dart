import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/models/youtube_video.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/brand_app_bar.dart';
import 'library_formatters.dart';
import 'library_image_url.dart';

/// Mobile WebView embed params — `youtube-nocookie` origin avoids YouTube error 15/153.
const _libraryYoutubeParams = YoutubePlayerParams(
  showControls: true,
  showFullscreenButton: true,
  origin: 'https://www.youtube-nocookie.com',
  enableCaption: false,
  showVideoAnnotations: false,
  playsInline: true,
  pointerEvents: PointerEvents.auto,
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

  String? get _videoId {
    return YoutubePlayerController.convertUrlToId(widget.video.watchUrl) ??
        (widget.video.id.trim().isNotEmpty ? widget.video.id.trim() : null);
  }

  void _announce(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        Directionality.of(context),
      );
    });
  }

  @override
  void dispose() {
    _cancelPlaybackTimeout();
    _playerSubscription?.cancel();
    _videoStateSubscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  void _clearStartingPlayback() {
    _cancelPlaybackTimeout();
    if (!_startingPlayback || !mounted) return;
    setState(() => _startingPlayback = false);
  }

  bool _isActivePlaybackState(PlayerState state) {
    return state == PlayerState.playing ||
        state == PlayerState.buffering ||
        state == PlayerState.paused;
  }

  Future<void> _pollUntilPlaybackStarts(YoutubePlayerController controller) async {
    const pollInterval = Duration(milliseconds: 400);
    final deadline = DateTime.now().add(_playbackStartTimeout);

    while (mounted && _startingPlayback && DateTime.now().isBefore(deadline)) {
      try {
        final state = await controller.playerState;
        if (_isActivePlaybackState(state)) {
          _clearStartingPlayback();
          return;
        }
        final elapsed = await controller.currentTime;
        if (elapsed > 0.25) {
          _clearStartingPlayback();
          return;
        }
      } catch (_) {
        // Player iframe may not be ready yet.
      }
      await Future<void>.delayed(pollInterval);
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
    _announce(_copy.libraryEmbedError);
  }

  void _bindPlayerListener(YoutubePlayerController controller) {
    _playerSubscription?.cancel();
    _videoStateSubscription?.cancel();

    _playerSubscription = controller.listen((value) {
      if (value.hasError) {
        _handlePlayerFailure();
        return;
      }

      final state = value.playerState;
      if (_isActivePlaybackState(state)) {
        _clearStartingPlayback();
      }

      if (state == _lastAnnouncedPlayerState) return;
      switch (state) {
        case PlayerState.paused:
          _announce(_copy.libraryPlayerPaused);
          _lastAnnouncedPlayerState = state;
        case PlayerState.buffering:
          _announce(_copy.libraryPlayerBuffering);
          _lastAnnouncedPlayerState = state;
        case PlayerState.playing:
          _lastAnnouncedPlayerState = state;
        case PlayerState.ended:
        case PlayerState.cued:
        case PlayerState.unStarted:
        case PlayerState.unknown:
          _lastAnnouncedPlayerState = state;
          break;
      }
    });

    _videoStateSubscription = controller.videoStateStream.listen((state) {
      if (state.position.inMilliseconds > 250) {
        _clearStartingPlayback();
      }
    });
  }

  Future<void> _loadAndPlay(YoutubePlayerController controller, String videoId) async {
    try {
      await controller.loadVideoById(videoId: videoId);
      await controller.playVideo();
      unawaited(_pollUntilPlaybackStarts(controller));
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
        await controller.playVideo();
        if (mounted) setState(() => _startingPlayback = false);
        _cancelPlaybackTimeout();
      }
      _announce('Playing ${widget.video.title}');
    } catch (_) {
      _handlePlayerFailure();
    }
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
                color: UdaanColors.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
              Semantics(
                label: 'Video player for ${video.title}',
                container: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _TapToPlayPoster(
                      copy: copy,
                      title: video.title,
                      thumbnailUrl: thumbnailUrl,
                      loading: _startingPlayback,
                      onPlay: () => unawaited(_startPlayback()),
                    ),
                  ),
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
                Semantics(
                  label: 'Video player for ${video.title}',
                  container: true,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          player,
                          if (_startingPlayback)
                            const ColoredBox(
                              color: Color(0xCC000000),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: UdaanColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
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
            child: Text(
              copy.libraryEmbedError,
              style: const TextStyle(
                color: UdaanColors.error,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: copy.retry,
            child: OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              icon: const Icon(Icons.refresh),
              label: Text(copy.retry),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          video.title,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: UdaanColors.onBackground,
          ),
        ),
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
          Text(
            description,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: UdaanColors.onSurfaceVariant,
              height: 1.45,
            ),
          )
        else
          Text(
            copy.libraryNoDescription,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: UdaanColors.onSurfaceMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        const SizedBox(height: 16),
        Semantics(
          label: copy.libraryYoutubeAttribution,
          child: Text(
            copy.libraryYoutubeAttribution,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: UdaanColors.onSurfaceMuted,
            ),
          ),
        ),
      ],
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
    return Semantics(
      button: true,
      enabled: !loading,
      label: '${copy.libraryPlayVideo}, $title. ${copy.libraryTapToPlay}',
      child: Material(
        color: UdaanColors.surfaceContainer,
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
                color: Colors.black.withValues(alpha: 0.25),
              ),
              Center(
                child: loading
                    ? const CircularProgressIndicator(color: UdaanColors.primary)
                    : ExcludeSemantics(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: UdaanColors.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 40,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              copy.libraryTapToPlay,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: UdaanColors.onBackground,
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
      color: UdaanColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.video_library_outlined,
          size: 48,
          color: UdaanColors.onSurfaceMuted.withValues(alpha: 0.7),
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
          color: UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: UdaanColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(icon, size: 16, color: UdaanColors.primaryGlow),
            ),
            const SizedBox(width: 6),
            ExcludeSemantics(
              child: Text(
                label,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: UdaanColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
