/// A user-saved radio show or library video (local cache + server snapshot).
enum SavedFavoriteType {
  radioShow('radio_show'),
  libraryVideo('library_video');

  const SavedFavoriteType(this.apiValue);

  final String apiValue;

  static SavedFavoriteType? tryParse(String? raw) {
    final value = raw?.trim() ?? '';
    for (final type in SavedFavoriteType.values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

class SavedFavorite {
  const SavedFavorite({
    required this.type,
    required this.itemId,
    required this.title,
    this.meta = const {},
    this.savedAt,
  });

  factory SavedFavorite.fromJson(Map<String, dynamic> json) {
    return SavedFavorite(
      type: SavedFavoriteType.tryParse(json['type']?.toString()) ??
          SavedFavoriteType.libraryVideo,
      itemId: json['item_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      meta: _metaFromJson(json['meta']),
      savedAt: json['saved_at']?.toString(),
    );
  }

  final SavedFavoriteType type;
  final String itemId;
  final String title;
  final Map<String, String> meta;
  final String? savedAt;

  String? get thumbnailUrl {
    final value = meta['thumbnail_url']?.trim() ?? '';
    return value.isNotEmpty ? value : null;
  }

  Map<String, dynamic> toApiJson() => {
        'type': type.apiValue,
        'item_id': itemId,
        'title': title,
        if (meta.isNotEmpty) 'meta': meta,
      };

  Map<String, dynamic> toLocalJson() => {
        'type': type.apiValue,
        'item_id': itemId,
        'title': title,
        'meta': meta,
        if (savedAt != null) 'saved_at': savedAt,
      };

  static List<SavedFavorite> listFromJson(List<dynamic>? raw) {
    if (raw == null) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SavedFavorite.fromJson)
        .where((item) => item.itemId.trim().isNotEmpty)
        .toList();
  }
}

Map<String, String> _metaFromJson(dynamic raw) {
  if (raw is! Map) return const {};
  return raw.map(
    (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
  )..removeWhere((_, value) => value.trim().isEmpty);
}
