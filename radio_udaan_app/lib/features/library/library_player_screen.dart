import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/constants/app_strings.dart';
import '../../core/models/youtube_video.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/brand_app_bar.dart';
import 'library_formatters.dart';
import 'library_image_url.dart';

/// In-app YouTube playback with Udaan chrome (IFrame API — stream only, store compliant).
class LibraryPlayerScreen extends ConsumerStatefulWidget {
  const LibraryPlayerScreen({required this.video, super.key});

  final YoutubeVideo video;

  @override
  ConsumerState<LibraryPlayerScreen> createState() => _LibraryPlayerScreenState();
}

class _LibraryPlayerScreenState extends ConsumerState<LibraryPlayerScreen> {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _playerSubscription;
  PlayerState? _lastAnnouncedPlayerState;
  bool _playerStarted = false;

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
  void initState() {
    super.initState();
    final videoId = _resolveVideoId();
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
          enableCaption: false,
          showVideoAnnotations: false,
          color: 'white',
        ),
      );
      _playerSubscription = _controller!.listen((value) {
        final state = value.playerState;
        if (state == _lastAnnouncedPlayerState) return;
        switch (state) {
          case PlayerState.paused:
            _announce(AppStrings.libraryPlayerPaused);
            _lastAnnouncedPlayerState = state;
          case PlayerState.buffering:
            _announce(AppStrings.libraryPlayerBuffering);
            _lastAnnouncedPlayerState = state;
          case PlayerState.playing:
          case PlayerState.ended:
          case PlayerState.cued:
          case PlayerState.unStarted:
          case PlayerState.unknown:
            _lastAnnouncedPlayerState = state;
            break;
        }
      });
    } else {
      _announce(AppStrings.libraryNoVideo);
    }
  }

  String? _resolveVideoId() {
    return YoutubePlayerController.convertUrlToId(widget.video.watchUrl) ??
        (widget.video.id.trim().isNotEmpty ? widget.video.id.trim() : null);
  }

  Future<void> _startPlayback() async {
    if (_controller == null || _playerStarted) return;
    setState(() => _playerStarted = true);
    await _controller!.playVideo();
    _announce('Playing ${widget.video.title}');
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = widget.video;
    final thumbnailUrl = libraryThumbnailFor(ref, video);
    final description = summarizeYoutubeDescription(video.description);
    final duration = video.displayDuration;
    final uploaded = video.publishedAtDate != null
        ? formatLibraryRelativeDate(video.publishedAtDate!)
        : '';

    return Scaffold(
      backgroundColor: UdaanColors.background,
      appBar: BrandAppBar(title: video.title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(BrandTokens.screenPadding),
          children: [
            if (_controller != null)
              Semantics(
                label: 'Video player for ${video.title}',
                container: true,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _playerStarted
                        ? YoutubePlayer(
                            controller: _controller!,
                            aspectRatio: 16 / 9,
                          )
                        : _TapToPlayPoster(
                            title: video.title,
                            thumbnailUrl: thumbnailUrl,
                            onPlay: _startPlayback,
                          ),
                  ),
                ),
              )
            else
              Semantics(
                label: AppStrings.libraryNoVideo,
                liveRegion: true,
                child: Card(
                  color: UdaanColors.surfaceContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      AppStrings.libraryNoVideo,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
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
                      label: '${AppStrings.libraryDurationPrefix}$duration',
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
                AppStrings.libraryNoDescription,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: UdaanColors.onSurfaceMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 16),
            Semantics(
              label: AppStrings.libraryYoutubeAttribution,
              child: Text(
                AppStrings.libraryYoutubeAttribution,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: UdaanColors.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapToPlayPoster extends StatelessWidget {
  const _TapToPlayPoster({
    required this.title,
    required this.thumbnailUrl,
    required this.onPlay,
  });

  final String title;
  final String thumbnailUrl;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${AppStrings.libraryPlayVideo}, $title. ${AppStrings.libraryTapToPlay}',
      child: Material(
        color: UdaanColors.surfaceContainer,
        child: InkWell(
          onTap: onPlay,
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
                child: ExcludeSemantics(
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
                        AppStrings.libraryTapToPlay,
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
