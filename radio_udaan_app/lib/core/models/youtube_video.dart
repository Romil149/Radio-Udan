/// YouTube video and playlist payloads from `/library/youtube/*` App API routes.
class YoutubeVideo {
  const YoutubeVideo({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.durationSeconds,
    this.durationLabel,
    this.publishedAt,
    this.youtubeUrl,
  });

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) {
    return YoutubeVideo(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      durationSeconds: _parseInt(json['duration_seconds']),
      durationLabel: json['duration_label']?.toString(),
      publishedAt: json['published_at']?.toString(),
      youtubeUrl: json['youtube_url']?.toString(),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? durationSeconds;
  final String? durationLabel;
  final String? publishedAt;
  final String? youtubeUrl;

  bool get hasPlayableId => id.trim().isNotEmpty;

  String get watchUrl {
    final direct = youtubeUrl?.trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final videoId = id.trim();
    if (videoId.isEmpty) return '';
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  String get displayDuration {
    final label = durationLabel?.trim() ?? '';
    if (label.isNotEmpty) return label;
    final seconds = durationSeconds;
    if (seconds == null || seconds <= 0) return '';
    return formatYoutubeDuration(seconds);
  }

  DateTime? get publishedAtDate {
    final raw = publishedAt?.trim() ?? '';
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class YoutubePlaylist {
  const YoutubePlaylist({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.itemCount,
  });

  factory YoutubePlaylist.fromJson(Map<String, dynamic> json) {
    return YoutubePlaylist(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      itemCount: _parseInt(json['item_count']) ?? _parseInt(json['video_count']),
    );
  }

  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int? itemCount;

  bool get hasId => id.trim().isNotEmpty;
}

class YoutubeVideoListResponse {
  const YoutubeVideoListResponse({
    required this.items,
    required this.total,
    this.page,
    this.perPage,
    this.nextPageToken,
  });

  factory YoutubeVideoListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return YoutubeVideoListResponse(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(YoutubeVideo.fromJson)
          .toList(),
      total: _parseInt(json['total']) ?? raw.length,
      page: _parseInt(json['page']),
      perPage: _parseInt(json['per_page']),
      nextPageToken: json['next_page_token']?.toString(),
    );
  }

  final List<YoutubeVideo> items;
  final int total;
  final int? page;
  final int? perPage;
  final String? nextPageToken;
}

class YoutubePlaylistListResponse {
  const YoutubePlaylistListResponse({
    required this.items,
    required this.total,
    this.page,
    this.perPage,
  });

  factory YoutubePlaylistListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return YoutubePlaylistListResponse(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(YoutubePlaylist.fromJson)
          .toList(),
      total: _parseInt(json['total']) ?? raw.length,
      page: _parseInt(json['page']),
      perPage: _parseInt(json['per_page']),
    );
  }

  final List<YoutubePlaylist> items;
  final int total;
  final int? page;
  final int? perPage;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

/// Formats seconds as `m:ss` or `h:mm:ss`.
String formatYoutubeDuration(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  return '$minutes:${secs.toString().padLeft(2, '0')}';
}
