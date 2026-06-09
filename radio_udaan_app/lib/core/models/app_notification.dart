/// In-app notification from `GET /notifications`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.readAt,
    this.createdAt,
    this.data = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? 'general',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true,
      readAt: json['read_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      data: rawData is Map<String, dynamic> ? rawData : const {},
    );
  }

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? readAt;
  final String? createdAt;
  final Map<String, dynamic> data;
}

class NotificationListResult {
  const NotificationListResult({
    required this.items,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.unreadCount,
  });

  factory NotificationListResult.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return NotificationListResult(
      items: items
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  final List<AppNotification> items;
  final int page;
  final int total;
  final int totalPages;
  final int unreadCount;
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.liveBroadcastsEnabled,
    required this.eventsEnabled,
    required this.promotionsEnabled,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final prefs = json['preferences'] as Map<String, dynamic>? ?? json;
    return NotificationPreferences(
      liveBroadcastsEnabled:
          prefs['live_broadcasts_enabled'] != false,
      eventsEnabled: prefs['events_enabled'] != false,
      promotionsEnabled: prefs['promotions_enabled'] == true,
    );
  }

  final bool liveBroadcastsEnabled;
  final bool eventsEnabled;
  final bool promotionsEnabled;

  Map<String, bool> toApiPayload() => {
        'live_broadcasts_enabled': liveBroadcastsEnabled,
        'events_enabled': eventsEnabled,
        'promotions_enabled': promotionsEnabled,
      };
}
