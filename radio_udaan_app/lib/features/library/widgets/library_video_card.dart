import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/youtube_video.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../library_formatters.dart' show formatLibraryRelativeDate, summarizeYoutubeDescription;
import '../library_player_screen.dart';
import '../../favorites/app_favorites_provider.dart';

const double _libraryMinTapTarget = 56;

/// Recent-upload card — Stitch layout with square play overlay and Save pill.
class LibraryVideoCard extends ConsumerWidget {
  const LibraryVideoCard({
    required this.video,
    required this.thumbnailUrl,
    super.key,
  });

  final YoutubeVideo video;
  final String thumbnailUrl;

  void _announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  void _openPlayer(BuildContext context, AppCopy copy) {
    if (!video.hasPlayableId) {
      _announce(context, copy.libraryNoVideo);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.libraryNoVideo)),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibraryPlayerScreen(video: video),
      ),
    );
  }

  String _summaryLine(AppCopy copy) {
    final parts = <String>[];
    final desc = summarizeYoutubeDescription(video.description);
    if (desc.isNotEmpty) {
      parts.add(desc.length > 80 ? '${desc.substring(0, 80).trim()}…' : desc);
    }
    final duration = video.displayDuration;
    if (duration.isNotEmpty) {
      parts.add('${copy.libraryDurationPrefix}$duration');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final savedIds = ref.watch(librarySavedVideoIdsProvider);
    final favoritesNotifier = ref.read(appFavoritesProvider.notifier);
    final isSaved = savedIds.contains(video.id.trim());
    final uploaded = video.publishedAtDate != null
        ? formatLibraryRelativeDate(video.publishedAtDate!, copy)
        : '';
    final summary = _summaryLine(copy);

    return Semantics(
      label: copy.libraryVideoSemantics(
        title: video.title,
        duration: video.displayDuration,
        uploaded: uploaded,
        saved: isSaved,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: UdaanColors.surfaceContainer,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          border: Border.all(color: UdaanColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label: '${copy.libraryPlayVideo}, ${video.title}',
              child: InkWell(
                onTap: () => _openPlayer(context, copy),
                child: _Thumbnail(
                  title: video.title,
                  thumbnailUrl: thumbnailUrl,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: UdaanColors.onBackground,
                    ),
                  ),
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: UdaanColors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(
                    height: 1,
                    color: UdaanColors.outlineVariant,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          uploaded,
                          style: GoogleFonts.atkinsonHyperlegible(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: UdaanColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      _SaveButton(
                        copy: copy,
                        isSaved: isSaved,
                        onPressed: () async {
                          await favoritesNotifier.toggleLibraryVideo(
                            video: video,
                            thumbnailUrl: thumbnailUrl,
                          );
                          if (!context.mounted) return;
                          final nowSaved = !isSaved;
                          _announce(
                            context,
                            nowSaved
                                ? copy.libraryVideoSaved
                                : copy.libraryVideoUnsaved,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.copy,
    required this.isSaved,
    required this.onPressed,
  });

  final AppCopy copy;
  final bool isSaved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final saveLabel =
        isSaved ? copy.librarySavedVideo : copy.librarySaveVideo;
    return Semantics(
      button: true,
      label: saveLabel,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(_libraryMinTapTarget, _libraryMinTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          foregroundColor: UdaanColors.primaryGlow,
          side: const BorderSide(color: UdaanColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: Icon(
          isSaved ? Icons.bookmark : Icons.bookmark_border,
          size: 20,
          color: isSaved ? UdaanColors.primary : UdaanColors.primaryGlow,
        ),
        label: Text(
          saveLabel,
          style: GoogleFonts.atkinsonHyperlegible(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.title,
    required this.thumbnailUrl,
  });

  final String title;
  final String thumbnailUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (thumbnailUrl.isNotEmpty)
            ExcludeSemantics(
              child: CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                memCacheHeight: 360,
                placeholder: (_, _) => const _ThumbnailPlaceholder(),
                errorWidget: (_, _, _) => const _ThumbnailPlaceholder(),
              ),
            )
          else
            const _ThumbnailPlaceholder(),
          Center(
            child: ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: UdaanColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

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
