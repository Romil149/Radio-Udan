import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/youtube_video.dart';
import '../../core/network/dio_exception_mapper.dart';
import '../../core/theme/brand_tokens.dart';
import '../../core/theme/udaan_colors.dart';
import 'library_image_url.dart';
import '../../core/widgets/brand_app_bar.dart';
import '../../core/widgets/empty_state.dart';
import 'library_playlist_videos_screen.dart';
import 'library_providers.dart';
import 'widgets/library_playlist_tile.dart';
import '../../core/providers/app_providers.dart';

/// Full playlist catalog (`GET /library/youtube/playlists`).
class LibraryPlaylistsScreen extends ConsumerWidget {
  const LibraryPlaylistsScreen({super.key});

  String _thumbnail(YoutubePlaylist playlist, WidgetRef ref) =>
      playlistThumbnailFor(ref, playlist);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = ref.watch(appCopyProvider);
    final playlists = ref.watch(allYoutubePlaylistsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BrandAppBar(title: copy.libraryPlaylists),
      body: SafeArea(
        child: playlists.when(
          data: (data) {
            if (data.items.isEmpty) {
              return EmptyState(
                message: copy.libraryPlaylistsEmpty,
                icon: Icons.playlist_play_outlined,
              );
            }
            return RefreshIndicator(
              color: UdaanColors.primary,
              backgroundColor: UdaanColors.surfaceContainer,
              onRefresh: () async {
                ref.invalidate(allYoutubePlaylistsProvider);
                await ref.read(allYoutubePlaylistsProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(BrandTokens.screenPadding),
                itemCount: data.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final playlist = data.items[index];
                  return LibraryPlaylistListTile(
                    playlist: playlist,
                    thumbnailUrl: _thumbnail(playlist, ref),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LibraryPlaylistVideosScreen(
                            playlist: playlist,
                          ),
                        ),
                      );
                    },
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
            onAction: () => ref.invalidate(allYoutubePlaylistsProvider),
          ),
        ),
      ),
    );
  }
}
