import 'dart:async';

import 'package:flutter/material.dart';
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

/// Mobile WebView embed params — `youtube-nocookie` origin avoids YouTube error 15/153.
const _libraryYoutubeParams = YoutubePlayerParams(
  showControls: true,
  showFullscreenButton: true,
  origin: 'https://www.youtube-nocookie.com',
  enableCaption: true,
  showVideoAnnotations: false,
  playsInline: true,
  pointerEvents: PointerEvents.auto,
);

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
  bool _playerError = false;

  String? get _videoId {
    return YoutubePlayerController.convertUrlToId(widget.video.watchUrl) ??
        (widget.video.id.trim().isNotEmpty ? widget.video.id.trim() : null);
  }

  @override
  void initState() {
    super.initState();
    final videoId = _videoId;
    if (videoId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _createAndCuePlayer(videoId);
      });
    }
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _controller?.close();
    super.dispose();
  }

  void _handlePlayerFailure() {
    if (!mounted) return;
    if (_playerError) return;
    setState(() => _playerError = true);
    announce(context, ref.read(appCopyProvider).libraryEmbedError);
  }

  void _bindPlayerListener(YoutubePlayerController controller) {
    _playerSubscription?.cancel();
    _playerSubscription = controller.listen((value) {
      if (value.hasError) {
        _handlePlayerFailure();
      }
    });
  }

  void _createAndCuePlayer(String videoId) {
    _playerSubscription?.cancel();
    _controller?.close();

    setState(() {
      _controller = null;
      _playerError = false;
    });

    try {
      final created = YoutubePlayerController(
        params: _libraryYoutubeParams,
        key: videoId,
        onWebResourceError: (_) => _handlePlayerFailure(),
      );
      _controller = created;
      _bindPlayerListener(created);
      if (mounted) setState(() {});
      // Cue after the scaffold/WebView is in the tree.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _controller != created) return;
        unawaited(created.cueVideoById(videoId: videoId));
      });
    } catch (_) {
      _handlePlayerFailure();
    }
  }

  void _resetPlayer() {
    final videoId = _videoId;
    if (videoId == null) return;
    _createAndCuePlayer(videoId);
  }

  Widget _buildVideoRegion({
    required AppCopy copy,
    required String title,
    required Widget child,
  }) {
    return Semantics(
      label: '$title. ${copy.libraryYoutubeAttribution}. '
          'YouTube player controls are in the video area.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = ref.watch(appCopyProvider);
    final video = widget.video;
    final controller = _controller;
    final videoId = _videoId;
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
                child: ColoredBox(color: context.udaan.surfaceContainer),
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
                  child: player,
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
