/// Combined what's-new + community news items from `GET /library/updates`.

enum WhatsNewUpdateType {
  whatsNew('whats-new'),
  communityNews('latestcommunitynews');

  const WhatsNewUpdateType(this.apiValue);

  final String apiValue;

  static WhatsNewUpdateType? fromApi(String? raw) {
    final v = raw?.trim() ?? '';
    for (final type in WhatsNewUpdateType.values) {
      if (type.apiValue == v) return type;
    }
    return null;
  }
}

class WhatsNewListItem {
  const WhatsNewListItem({
    required this.id,
    required this.type,
    required this.kindLabel,
    required this.title,
    required this.summary,
    this.publishedAt,
    this.thumbnailUrl,
  });

  factory WhatsNewListItem.fromJson(Map<String, dynamic> json) {
    return WhatsNewListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: WhatsNewUpdateType.fromApi(json['type']?.toString()) ??
          WhatsNewUpdateType.whatsNew,
      kindLabel: json['kind_label']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      publishedAt: json['published_at']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
    );
  }

  final int id;
  final WhatsNewUpdateType type;
  final String kindLabel;
  final String title;
  final String summary;
  final String? publishedAt;
  final String? thumbnailUrl;
}

class WhatsNewListResponse {
  const WhatsNewListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory WhatsNewListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return WhatsNewListResponse(
      items: raw
          .whereType<Map<String, dynamic>>()
          .map(WhatsNewListItem.fromJson)
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['per_page'] as num?)?.toInt() ?? 50,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  final List<WhatsNewListItem> items;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;
}

/// Shared detail shape for whats-new and latestcommunitynews.
class WhatsNewAnnouncementDetail {
  const WhatsNewAnnouncementDetail({
    required this.id,
    required this.title,
    required this.summary,
    required this.kindLabel,
    this.category,
    this.bodyHtml,
    this.thumbnailUrl,
    this.youtubeUrl,
    this.publishedAt,
    this.permalink,
  });

  factory WhatsNewAnnouncementDetail.fromJson(Map<String, dynamic> json) {
    return WhatsNewAnnouncementDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      kindLabel: json['kind_label']?.toString() ?? '',
      category: json['category']?.toString(),
      bodyHtml: json['body_html']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      youtubeUrl: json['youtube_url']?.toString(),
      publishedAt: json['published_at']?.toString(),
      permalink: json['permalink']?.toString(),
    );
  }

  final int id;
  final String title;
  final String summary;
  final String kindLabel;
  final String? category;
  final String? bodyHtml;
  final String? thumbnailUrl;
  final String? youtubeUrl;
  final String? publishedAt;
  final String? permalink;
}
