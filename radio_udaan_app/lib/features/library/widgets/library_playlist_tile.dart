import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/youtube_video.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';

const double _libraryMinTapTarget = 56;

/// Full-width featured playlist card (first in grid).
class LibraryPlaylistFeaturedTile extends StatelessWidget {
  const LibraryPlaylistFeaturedTile({
    required this.playlist,
    required this.thumbnailUrl,
    required this.onTap,
    super.key,
  });

  final YoutubePlaylist playlist;
  final String thumbnailUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playlist.title,
      child: Material(
        color: UdaanColors.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: _libraryMinTapTarget),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
              border: Border.all(color: UdaanColors.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlaylistVisual(
                  thumbnailUrl: thumbnailUrl,
                  icon: Icons.queue_music_outlined,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  playlist.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: UdaanColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Half-width compact playlist card (icon + title).
class LibraryPlaylistCompactTile extends StatelessWidget {
  const LibraryPlaylistCompactTile({
    required this.playlist,
    required this.thumbnailUrl,
    required this.onTap,
    this.icon = Icons.playlist_play_outlined,
    super.key,
  });

  final YoutubePlaylist playlist;
  final String thumbnailUrl;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: playlist.title,
      child: Material(
        color: UdaanColors.surfaceContainer,
        borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          child: Container(
            constraints: const BoxConstraints(minHeight: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
              border: Border.all(color: UdaanColors.outlineVariant),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PlaylistVisual(
                  thumbnailUrl: thumbnailUrl,
                  icon: icon,
                  size: 40,
                ),
                const SizedBox(height: 10),
                Text(
                  playlist.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

class LibraryPlaylistGridTile extends StatelessWidget {
  const LibraryPlaylistGridTile({
    required this.playlist,
    required this.thumbnailUrl,
    required this.onTap,
    super.key,
  });

  final YoutubePlaylist playlist;
  final String thumbnailUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LibraryPlaylistCompactTile(
      playlist: playlist,
      thumbnailUrl: thumbnailUrl,
      onTap: onTap,
    );
  }
}

class LibraryPlaylistListTile extends StatelessWidget {
  const LibraryPlaylistListTile({
    required this.playlist,
    required this.thumbnailUrl,
    required this.onTap,
    super.key,
  });

  final YoutubePlaylist playlist;
  final String thumbnailUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = playlist.itemCount;
    final countLabel = count != null && count > 0 ? '$count videos' : '';

    return Semantics(
      button: true,
      label: countLabel.isEmpty ? playlist.title : '${playlist.title}, $countLabel',
      child: Card(
        color: UdaanColors.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
          side: const BorderSide(color: UdaanColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: thumbnailUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: thumbnailUrl,
                              fit: BoxFit.cover,
                              memCacheHeight: 144,
                              placeholder: (_, _) =>
                                  const _PlaylistPlaceholder(),
                              errorWidget: (_, _, _) =>
                                  const _PlaylistPlaceholder(),
                            )
                          : const _PlaylistPlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            playlist.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.atkinsonHyperlegible(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: UdaanColors.onBackground,
                            ),
                          ),
                          if (countLabel.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              countLabel,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: UdaanColors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: UdaanColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistVisual extends StatelessWidget {
  const _PlaylistVisual({
    required this.thumbnailUrl,
    required this.icon,
    required this.size,
  });

  final String thumbnailUrl;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (thumbnailUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size * 1.6,
          height: size,
          child: CachedNetworkImage(
            imageUrl: thumbnailUrl,
            fit: BoxFit.cover,
            memCacheHeight: (size * 2).round(),
            placeholder: (_, _) => _IconBadge(icon: icon, size: size),
            errorWidget: (_, _, _) => _IconBadge(icon: icon, size: size),
          ),
        ),
      );
    }
    return _IconBadge(icon: icon, size: size);
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.size});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: UdaanColors.primaryGlow,
    );
  }
}

class _PlaylistPlaceholder extends StatelessWidget {
  const _PlaylistPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: UdaanColors.surfaceContainerHigh,
      child: Center(
        child: Icon(
          Icons.playlist_play,
          size: 36,
          color: UdaanColors.onSurfaceMuted.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
