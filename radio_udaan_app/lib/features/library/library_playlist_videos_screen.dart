import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/youtube_video.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import '../../core/widgets/brand_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import 'library_image_url.dart';
import 'library_providers.dart';
import 'widgets/library_video_card.dart';
import '../../core/providers/app_providers.dart';

/// Videos inside one YouTube playlist.
class LibraryPlaylistVideosScreen extends ConsumerWidget {
  const LibraryPlaylistVideosScreen({
    required this.playlist,
    super.key,
  });

  final YoutubePlaylist playlist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final videos = ref.watch(youtubePlaylistVideosProvider(playlist.id));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: playlist.title),
      body: SafeArea(
        child: videos.when(
          data: (data) {
            if (data.items.isEmpty) {
              return EmptyState(
                message: copy.libraryPlaylistVideosEmpty,
                icon: Icons.video_library_outlined,
              );
            }
            return RefreshIndicator(
              color: UdaanColors.primary,
              backgroundColor: UdaanColors.surfaceContainer,
              onRefresh: () async {
                ref.invalidate(youtubePlaylistVideosProvider(playlist.id));
                await ref.read(youtubePlaylistVideosProvider(playlist.id).future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(BrandTokens.screenPadding),
                itemCount: data.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final video = data.items[index];
                  return LibraryVideoCard(
                    video: video,
                    thumbnailUrl: libraryThumbnailFor(ref, video),
                  );
                },
              ),
            );
          },
          loading: () => Center(
            child: Semantics(
              label: copy.libraryLoading,
              liveRegion: true,
              child: const CircularProgressIndicator(color: UdaanColors.primary),
            ),
          ),
          error: (error, _) => EmptyState(
            message: parseApiError(error).message,
            icon: Icons.error_outline,
            actionLabel: copy.retry,
            onAction: () =>
                ref.invalidate(youtubePlaylistVideosProvider(playlist.id)),
          ),
        ),
      ),
    );
  }
}
