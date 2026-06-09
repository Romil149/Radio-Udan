import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/youtube_video.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/wp_media_url.dart';

/// Resolves a YouTube playlist thumbnail for display (external URLs stay intact).
String resolvePlaylistThumbnail(
  YoutubePlaylist playlist, {
  required String apiBaseUrl,
  String? siteUrl,
}) {
  final raw = playlist.thumbnailUrl?.trim() ?? '';
  if (raw.isEmpty) return '';
  return resolveWpMediaUrl(raw, apiBaseUrl: apiBaseUrl, siteUrl: siteUrl);
}

String playlistThumbnailFor(WidgetRef ref, YoutubePlaylist playlist) {
  return resolvePlaylistThumbnail(
    playlist,
    apiBaseUrl: ref.watch(apiBaseUrlProvider),
    siteUrl: ref.watch(remoteConfigProvider)?.siteUrl,
  );
}

/// Resolves a YouTube video thumbnail for display (external URLs stay intact).
String resolveLibraryThumbnail(
  YoutubeVideo video, {
  required String apiBaseUrl,
  String? siteUrl,
}) {
  final raw = video.thumbnailUrl?.trim() ?? '';
  if (raw.isNotEmpty) {
    return resolveWpMediaUrl(raw, apiBaseUrl: apiBaseUrl, siteUrl: siteUrl);
  }
  final id = video.id.trim();
  if (id.isEmpty) return '';
  return 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
}

String libraryThumbnailFor(WidgetRef ref, YoutubeVideo video) {
  return resolveLibraryThumbnail(
    video,
    apiBaseUrl: ref.watch(apiBaseUrlProvider),
    siteUrl: ref.watch(remoteConfigProvider)?.siteUrl,
  );
}
