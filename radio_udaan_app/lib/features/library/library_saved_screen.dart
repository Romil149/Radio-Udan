import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/saved_favorite.dart';
import '../../core/models/youtube_video.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/brand_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import '../favorites/app_favorites_provider.dart';
import '../radio/radio_schedule_sheet.dart';
import 'library_image_url.dart';
import 'widgets/library_section_heading.dart';
import 'widgets/library_video_card.dart';

/// Saved radio shows and library videos for the signed-in or guest user.
class LibrarySavedScreen extends ConsumerWidget {
  const LibrarySavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final favorites = ref.watch(appFavoritesProvider);
    final radioItems = favorites
        .where((item) => item.type == SavedFavoriteType.radioShow)
        .toList();
    final videoItems = favorites
        .where((item) => item.type == SavedFavoriteType.libraryVideo)
        .toList();
    final isEmpty = radioItems.isEmpty && videoItems.isEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: copy.librarySavedScreenTitle),
      body: SafeArea(
        child: isEmpty
            ? EmptyState(
                icon: Icons.bookmark_border,
                message: copy.librarySavedEmpty,
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  BrandTokens.screenPadding,
                  8,
                  BrandTokens.screenPadding,
                  24,
                ),
                children: [
                  if (radioItems.isNotEmpty) ...[
                    LibrarySectionHeading(title: copy.librarySavedRadioSection),
                    const SizedBox(height: 8),
                    for (final item in radioItems)
                      _SavedRadioTile(item: item, copy: copy),
                  ],
                  if (videoItems.isNotEmpty) ...[
                    if (radioItems.isNotEmpty) const SizedBox(height: 20),
                    LibrarySectionHeading(title: copy.librarySavedVideosSection),
                    const SizedBox(height: 8),
                    for (final item in videoItems)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LibraryVideoCard(
                          video: _videoFromFavorite(item),
                          thumbnailUrl: videoThumbnailFor(
                            ref,
                            _videoFromFavorite(item),
                            fallbackUrl: item.thumbnailUrl,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  YoutubeVideo _videoFromFavorite(SavedFavorite item) {
    return YoutubeVideo(
      id: item.itemId,
      title: item.title,
      description: item.meta['description'],
      thumbnailUrl: item.thumbnailUrl,
      durationLabel: item.meta['duration'],
    );
  }
}

class _SavedRadioTile extends ConsumerWidget {
  const _SavedRadioTile({
    required this.item,
    required this.copy,
  });

  final SavedFavorite item;
  final AppCopy copy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = item.title.trim().isNotEmpty
        ? item.title.trim()
        : copy.radioFavorite;
    final hosts = item.meta['hosts']?.trim() ?? '';
    final isFavorite = ref.watch(radioFavoritesProvider).contains(item.itemId);

    return Semantics(
      label: '$title. ${hosts.isNotEmpty ? hosts : copy.radioFavorite}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: UdaanColors.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BrandTokens.cardRadius),
            side: const BorderSide(color: UdaanColors.outlineVariant),
          ),
          child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minVerticalPadding: 12,
          leading: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.thumbnailUrl!,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.radio,
                      color: UdaanColors.primaryGlow,
                      size: 32,
                    ),
                  ),
                )
              : const Icon(Icons.radio, color: UdaanColors.primaryGlow, size: 32),
          title: Text(
            title,
            style: GoogleFonts.atkinsonHyperlegible(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: UdaanColors.onBackground,
            ),
          ),
          subtitle: hosts.isNotEmpty
              ? Text(
                  hosts,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 14,
                    color: UdaanColors.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: Semantics(
            button: true,
            label: copy.radioFavoriteButtonLabel(
              showTitle: title,
              isFavorite: isFavorite,
            ),
            child: IconButton(
              constraints: const BoxConstraints(
                minWidth: BrandTokens.minTapTarget,
                minHeight: BrandTokens.minTapTarget,
              ),
              onPressed: () async {
                await ref.read(appFavoritesProvider.notifier).toggleRadioShow(
                      showId: item.itemId,
                      title: title,
                      meta: item.meta,
                    );
                if (!context.mounted) return;
                SemanticsService.sendAnnouncement(
                  View.of(context),
                  copy.radioFavoriteAnnouncement(
                    showTitle: title,
                    added: !isFavorite,
                  ),
                  Directionality.of(context),
                );
              },
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? UdaanColors.primary
                    : UdaanColors.primaryGlow,
              ),
            ),
          ),
          onTap: () => showRadioScheduleSheet(context),
          ),
        ),
      ),
    );
  }
}

String videoThumbnailFor(
  WidgetRef ref,
  YoutubeVideo video, {
  String? fallbackUrl,
}) {
  final direct = fallbackUrl?.trim() ?? video.thumbnailUrl?.trim() ?? '';
  if (direct.isNotEmpty) return direct;
  return libraryThumbnailFor(ref, video);
}
