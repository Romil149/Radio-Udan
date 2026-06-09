import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/youtube_video.dart';
import '../../core/providers/app_providers.dart';

/// Debounced search query (empty = recent uploads on the Library tab).
final librarySearchQueryProvider = StateProvider<String>((ref) => '');

final featuredYoutubePlaylistsProvider =
    FutureProvider<YoutubePlaylistListResponse>((ref) async {
  return ref.read(radioudaanApiProvider).listFeaturedYoutubePlaylists();
});

final allYoutubePlaylistsProvider =
    FutureProvider<YoutubePlaylistListResponse>((ref) async {
  return ref.read(radioudaanApiProvider).listYoutubePlaylists();
});

final youtubePlaylistVideosProvider = FutureProvider.family<
    YoutubeVideoListResponse, String>((ref, playlistId) async {
  return ref
      .read(radioudaanApiProvider)
      .listYoutubePlaylistVideos(playlistId.trim());
});

final libraryRecentUploadsProvider =
    FutureProvider<YoutubeVideoListResponse>((ref) async {
  return ref.read(radioudaanApiProvider).listYoutubeRecent();
});

final libraryYoutubeSearchProvider = FutureProvider.family<
    YoutubeVideoListResponse, String>((ref, query) async {
  return ref.read(radioudaanApiProvider).searchYoutubeVideos(query: query);
});
