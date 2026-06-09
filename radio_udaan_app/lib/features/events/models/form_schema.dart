/// Event metadata bundled with `GET /events/{id}/form`.
class EventFormInfo {
  const EventFormInfo({
    required this.eventId,
    required this.title,
    this.eventCode,
    this.summary,
    this.eventTypeLabel,
    this.startAt,
    this.bannerUrl,
  });

  factory EventFormInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return const EventFormInfo(eventId: 0, title: 'Event');
    }
    final banner = json['banner_image'];
    String? bannerUrl;
    if (banner is Map<String, dynamic>) {
      bannerUrl = banner['url']?.toString();
    }
    return EventFormInfo(
      eventId: (json['event_id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? 'Event',
      eventCode: json['event_code']?.toString(),
      summary: json['summary']?.toString(),
      eventTypeLabel: json['event_type_label']?.toString(),
      startAt: _parseDate(json['start_at']?.toString()),
      bannerUrl: bannerUrl,
    );
  }

  final int eventId;
  final String title;
  final String? eventCode;
  final String? summary;
  final String? eventTypeLabel;
  final DateTime? startAt;
  final String? bannerUrl;
}

DateTime? _parseDate(String? raw) {
  final value = raw?.trim() ?? '';
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

class FormSchema {
  const FormSchema({
    required this.eventId,
    required this.formId,
    required this.formName,
    required this.fields,
    required this.sections,
    required this.unsupportedFields,
    required this.maxFileMb,
    required this.event,
  });

  factory FormSchema.fromJson(Map<String, dynamic> json) {
    final upload = json['upload_constraints'] as Map<String, dynamic>? ?? {};
    final event = json['event'] as Map<String, dynamic>? ?? {};
    final form = json['form'] as Map<String, dynamic>? ?? {};
    final fieldsRaw = json['fields'] as List<dynamic>? ?? [];
    final sectionsRaw = json['sections'] as List<dynamic>? ?? [];
    final unsupportedRaw = json['unsupported_fields'] as List<dynamic>? ?? [];

    final eventInfo = EventFormInfo.fromJson(event);

    return FormSchema(
      eventId: eventInfo.eventId,
      formId: (form['form_id'] as num?)?.toInt() ?? 0,
      formName: form['name']?.toString() ?? 'Registration',
      maxFileMb: (upload['max_file_mb'] as num?)?.toInt() ?? 10,
      event: eventInfo,
      fields: fieldsRaw
          .whereType<Map<String, dynamic>>()
          .map(FormFieldSchema.fromJson)
          .toList(),
      sections: sectionsRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (s) => FormSection(
              id: s['id']?.toString() ?? 'default',
              title: s['title']?.toString() ?? 'Details',
            ),
          )
          .toList(),
      unsupportedFields: unsupportedRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (u) => UnsupportedField(
              key: u['key']?.toString() ?? '',
              label: u['label']?.toString() ?? '',
              type: u['type']?.toString() ?? '',
            ),
          )
          .toList(),
    );
  }

  final int eventId;
  final int formId;
  final String formName;
  final List<FormFieldSchema> fields;
  final List<FormSection> sections;
  final List<UnsupportedField> unsupportedFields;
  final int maxFileMb;
  final EventFormInfo event;
}

class FormSection {
  const FormSection({required this.id, required this.title});

  final String id;
  final String title;
}

class UnsupportedField {
  const UnsupportedField({
    required this.key,
    required this.label,
    required this.type,
  });

  final String key;
  final String label;
  final String type;
}

class FormFieldSchema {
  const FormFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.sectionId,
    this.options = const [],
    this.placeholder,
    this.maxSizeMb,
    this.allowedExt = const [],
  });

  factory FormFieldSchema.fromJson(Map<String, dynamic> json) {
    final opts = json['options'] as List<dynamic>? ?? [];
    final ext = json['allowed_ext'] as List<dynamic>? ?? [];
    return FormFieldSchema(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      required: json['required'] == true,
      sectionId: json['section_id']?.toString() ?? 'default',
      options: opts.map((e) => e.toString()).toList(),
      placeholder: json['placeholder']?.toString(),
      maxSizeMb: (json['max_size_mb'] as num?)?.toInt(),
      allowedExt: ext.map((e) => e.toString().toLowerCase()).toList(),
    );
  }

  final String key;
  final String label;
  final String type;
  final bool required;
  final String sectionId;
  final List<String> options;
  final String? placeholder;
  final int? maxSizeMb;
  final List<String> allowedExt;
}
