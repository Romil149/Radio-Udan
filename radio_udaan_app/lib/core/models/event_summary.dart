class EventBannerImage {
  const EventBannerImage({required this.url, this.alt});

  factory EventBannerImage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const EventBannerImage(url: '');
    }
    return EventBannerImage(
      url: json['url']?.toString() ?? '',
      alt: json['alt']?.toString(),
    );
  }

  final String url;
  final String? alt;

  bool get hasUrl => url.trim().isNotEmpty;
}

class EventSummary {
  const EventSummary({
    required this.eventId,
    required this.title,
    required this.status,
    this.summary,
    this.eventType = EventType.other,
    this.eventTypeLabel,
    this.startAt,
    this.bannerImage,
  });

  factory EventSummary.fromJson(Map<String, dynamic> json) {
    final bannerRaw = json['banner_image'];
    return EventSummary(
      eventId: (json['event_id'] as num).toInt(),
      title: json['title']?.toString() ?? 'Event',
      status: json['status']?.toString() ?? 'open',
      summary: json['summary']?.toString(),
      eventType: EventType.fromApi(json['event_type']?.toString()),
      eventTypeLabel: json['event_type_label']?.toString(),
      startAt: _parseDate(json['start_at']?.toString()),
      bannerImage: bannerRaw is Map<String, dynamic>
          ? EventBannerImage.fromJson(bannerRaw)
          : null,
    );
  }

  final int eventId;
  final String title;
  final String status;
  final String? summary;
  final EventType eventType;
  final String? eventTypeLabel;
  final DateTime? startAt;
  final EventBannerImage? bannerImage;

  bool get isOpen => status == 'open';

  String get badgeLabel {
    final label = eventTypeLabel?.trim() ?? '';
    if (label.isNotEmpty) return label;
    return eventType.defaultLabel;
  }

  bool get hasBadge => badgeLabel.isNotEmpty;
}

enum EventType {
  liveStream,
  workshop,
  other;

  static EventType fromApi(String? raw) {
    switch (raw?.trim()) {
      case 'live_stream':
        return EventType.liveStream;
      case 'workshop':
        return EventType.workshop;
      default:
        return EventType.other;
    }
  }

  String get defaultLabel {
    switch (this) {
      case EventType.liveStream:
        return 'LIVE STREAM';
      case EventType.workshop:
        return 'WORKSHOP';
      case EventType.other:
        return '';
    }
  }
}

DateTime? _parseDate(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}
