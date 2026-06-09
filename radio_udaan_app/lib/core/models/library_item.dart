class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    this.summary,
    this.youtubeUrl,
    this.thumbnailUrl,
    this.permalink,
    this.publishedAt,
    this.category,
    this.programHost,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString(),
      youtubeUrl: json['youtube_url']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      permalink: json['permalink']?.toString(),
      publishedAt: json['published_at']?.toString(),
      category: json['category']?.toString() ??
          json['program_category']?.toString(),
      programHost: json['program_host']?.toString(),
    );
  }

  final int id;
  final String title;
  final String? summary;
  final String? youtubeUrl;
  final String? thumbnailUrl;
  final String? permalink;
  final String? publishedAt;
  final String? category;
  final String? programHost;

  bool get hasYoutube =>
      youtubeUrl != null && youtubeUrl!.trim().isNotEmpty;
}

class LibraryListResponse {
  const LibraryListResponse({required this.items, required this.total});

  factory LibraryListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return LibraryListResponse(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(LibraryItem.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? raw.length,
    );
  }

  final List<LibraryItem> items;
  final int total;
}
