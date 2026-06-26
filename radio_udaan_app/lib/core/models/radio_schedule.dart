import 'package:intl/intl.dart';

DateTime? _tryParseDateTime(dynamic value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String _pickString(Map<String, dynamic> json, String key) {
  final v = json[key]?.toString().trim() ?? '';
  return v;
}

String _pickId(Map<String, dynamic> json) {
  final raw = json['id'] ?? json['show_id'];
  if (raw is num) return raw.toInt().toString();
  return raw?.toString().trim() ?? '';
}

/// Plain text for schedule UI (decode WP entities, strip tags).
String sanitizeScheduleText(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return '';
  text = text
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&hellip;', '…')
      .replaceAll('&#8230;', '…')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return text;
}

/// e.g. DivyaSharma → Divya Sharma when WP has no space.
String formatScheduleHosts(String hosts) {
  final cleaned = sanitizeScheduleText(hosts);
  if (cleaned.isEmpty) return '';
  if (cleaned.contains(' ')) return cleaned;
  return cleaned.replaceAllMapped(
    RegExp(r'(?<=[a-z])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
    (_) => ' ',
  );
}

/// A single scheduled segment / show entry returned by `/library/schedule`.
class RadioScheduleSegment {
  const RadioScheduleSegment({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.hosts,
    required this.imageUrl,
    required this.broadcastTime,
    required this.category,
    required this.startsAt,
    required this.endsAt,
  });

  factory RadioScheduleSegment.fromJson(Map<String, dynamic> json) {
    final title = sanitizeScheduleText(_pickString(json, 'title'));
    final subtitle = sanitizeScheduleText(
      _pickString(json, 'subtitle').isNotEmpty
          ? _pickString(json, 'subtitle')
          : _pickString(json, 'summary'),
    );
    final hosts = formatScheduleHosts(
      _pickString(json, 'hosts').isNotEmpty
          ? _pickString(json, 'hosts')
          : _pickString(json, 'program_host'),
    );
    final category = sanitizeScheduleText(
      _pickString(json, 'category').isNotEmpty
          ? _pickString(json, 'category')
          : _pickString(json, 'program_category'),
    );
    final imageUrl = _pickString(json, 'image_url').isNotEmpty
        ? _pickString(json, 'image_url')
        : _pickString(json, 'thumbnail_url');
    final broadcastTime = _pickString(json, 'broadcast_time');
    final startsAt = _tryParseDateTime(json['starts_at']);
    final endsAt = _tryParseDateTime(json['ends_at']);

    return RadioScheduleSegment(
      id: _pickId(json),
      title: title,
      subtitle: subtitle,
      hosts: hosts,
      imageUrl: imageUrl,
      broadcastTime: broadcastTime,
      category: category,
      startsAt: startsAt,
      endsAt: endsAt,
    );
  }

  final String id;
  final String title;
  final String subtitle;
  final String hosts;
  final String imageUrl;
  final String broadcastTime;
  final String category;
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool get hasId => id.isNotEmpty;
  bool get hasImage => imageUrl.isNotEmpty;
  bool get hasHosts => hosts.isNotEmpty;
  bool get hasCategory => category.isNotEmpty;

  String timeRangeLabel({DateFormat? timeFormat}) {
    if (broadcastTime.isNotEmpty) return broadcastTime;
    final fmt = timeFormat ?? DateFormat('h:mm a');
    final s = startsAt;
    final e = endsAt;
    if (s != null && e != null) {
      return '${fmt.format(s)} – ${fmt.format(e)}';
    }
    if (s != null) return fmt.format(s);
    return '';
  }
}

class RadioScheduleDay {
  const RadioScheduleDay({
    required this.date,
    required this.label,
    required this.segments,
  });

  factory RadioScheduleDay.fromJson(Map<String, dynamic> json) {
    final label = _pickString(json, 'label');
    final dateRaw = _pickString(json, 'date');
    final date = DateTime.tryParse(dateRaw);

    final rawItems = json['items'] ?? json['segments'];
    final segments = (rawItems as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RadioScheduleSegment.fromJson)
        .toList();

    return RadioScheduleDay(
      date: date,
      label: label,
      segments: segments,
    );
  }

  final DateTime? date;
  final String label;
  final List<RadioScheduleSegment> segments;

  String displayLabel() {
    if (label.isNotEmpty) return label;
    final d = date;
    if (d == null) return '';
    return DateFormat('EEE, d MMM').format(d);
  }
}

/// Response for `GET /library/schedule?days=2`.
class RadioScheduleResponse {
  const RadioScheduleResponse({
    this.timezone,
    required this.onAir,
    required this.next,
    required this.days,
  });

  factory RadioScheduleResponse.fromJson(Map<String, dynamic> json) {
    final onAirJson = json['on_air'];
    final nextJson = json['next'];

    final days = (json['days'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(RadioScheduleDay.fromJson)
        .toList();

    return RadioScheduleResponse(
      timezone: json['timezone']?.toString(),
      onAir: onAirJson is Map<String, dynamic>
          ? RadioScheduleSegment.fromJson(onAirJson)
          : null,
      next: nextJson is Map<String, dynamic>
          ? RadioScheduleSegment.fromJson(nextJson)
          : null,
      days: days,
    );
  }

  final String? timezone;
  final RadioScheduleSegment? onAir;
  final RadioScheduleSegment? next;
  final List<RadioScheduleDay> days;
}

