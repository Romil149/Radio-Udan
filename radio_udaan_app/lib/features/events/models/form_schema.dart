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
    required this.pages,
    required this.unsupportedFields,
    required this.maxFileMb,
    required this.event,
    this.formWarnings = const [],
    this.appSubmittable = true,
  });

  factory FormSchema.fromJson(Map<String, dynamic> json) {
    final upload = json['upload_constraints'] as Map<String, dynamic>? ?? {};
    final event = json['event'] as Map<String, dynamic>? ?? {};
    final form = json['form'] as Map<String, dynamic>? ?? {};
    final fieldsRaw = json['fields'] as List<dynamic>? ?? [];
    final sectionsRaw = json['sections'] as List<dynamic>? ?? [];
    final pagesRaw = json['pages'] as List<dynamic>? ?? [];
    final unsupportedRaw = json['unsupported_fields'] as List<dynamic>? ?? [];
    final warningsRaw = json['form_warnings'] as List<dynamic>? ?? [];

    final eventInfo = EventFormInfo.fromJson(event);

    return FormSchema(
      eventId: eventInfo.eventId,
      formId: (form['form_id'] as num?)?.toInt() ?? 0,
      formName: form['name']?.toString() ?? 'Registration',
      maxFileMb: (upload['max_file_mb'] as num?)?.toInt() ?? 10,
      event: eventInfo,
      appSubmittable: json['app_submittable'] != false,
      formWarnings: warningsRaw.map((e) => e.toString()).toList(),
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
      pages: pagesRaw
          .whereType<Map<String, dynamic>>()
          .map(FormPage.fromJson)
          .toList(),
      unsupportedFields: unsupportedRaw
          .whereType<Map<String, dynamic>>()
          .map(UnsupportedField.fromJson)
          .toList(),
    );
  }

  final int eventId;
  final int formId;
  final String formName;
  final List<FormFieldSchema> fields;
  final List<FormSection> sections;
  final List<FormPage> pages;
  final List<UnsupportedField> unsupportedFields;
  final int maxFileMb;
  final EventFormInfo event;
  final List<String> formWarnings;
  final bool appSubmittable;

  /// True when unsupported fields block submission in the app.
  bool get hasBlockingUnsupported =>
      unsupportedFields.any((u) => u.blocksSubmit || u.required);
}

class FormSection {
  const FormSection({required this.id, required this.title});

  final String id;
  final String title;
}

class FormPage {
  const FormPage({required this.id, required this.title});

  factory FormPage.fromJson(Map<String, dynamic> json) {
    return FormPage(
      id: json['id']?.toString() ?? 'page_0',
      title: json['title']?.toString() ?? '',
    );
  }

  final String id;
  final String title;
}

class UnsupportedField {
  const UnsupportedField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.blocksSubmit = false,
  });

  factory UnsupportedField.fromJson(Map<String, dynamic> json) {
    return UnsupportedField(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      required: json['required'] == true,
      blocksSubmit: json['blocks_submit'] == true,
    );
  }

  final String key;
  final String label;
  final String type;
  final bool required;
  final bool blocksSubmit;
}

class ChoiceOption {
  const ChoiceOption({required this.value, required this.label});

  factory ChoiceOption.fromJson(Map<String, dynamic> json) {
    final value = json['value']?.toString() ?? '';
    final label = json['label']?.toString() ?? value;
    return ChoiceOption(value: value.isNotEmpty ? value : label, label: label);
  }

  final String value;
  final String label;
}

class FormSubfield {
  const FormSubfield({
    required this.key,
    required this.label,
    this.required = false,
  });

  factory FormSubfield.fromJson(Map<String, dynamic> json) {
    return FormSubfield(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      required: json['required'] == true,
    );
  }

  final String key;
  final String label;
  final bool required;
}

class FormFieldSchema {
  const FormFieldSchema({
    required this.key,
    required this.label,
    required this.type,
    required this.required,
    required this.sectionId,
    this.options = const [],
    this.choiceOptions = const [],
    this.subfields = const [],
    this.placeholder,
    this.maxSizeMb,
    this.allowedExt = const [],
    this.visibility,
    this.consentHtml,
    this.pageIndex = 0,
    this.min,
    this.max,
    this.maxFiles = 1,
    this.infoHtml,
    this.step,
  });

  factory FormFieldSchema.fromJson(Map<String, dynamic> json) {
    final opts = json['options'] as List<dynamic>? ?? [];
    final choiceRaw = json['choice_options'] as List<dynamic>? ?? [];
    final subfieldsRaw = json['subfields'] as List<dynamic>? ?? [];
    final ext = json['allowed_ext'] as List<dynamic>? ?? [];
    final visibilityRaw = json['visibility'] as Map<String, dynamic>?;

    return FormFieldSchema(
      key: json['key']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      required: json['required'] == true,
      sectionId: json['section_id']?.toString() ?? 'default',
      options: opts.map((e) => e.toString()).toList(),
      choiceOptions: choiceRaw
          .whereType<Map<String, dynamic>>()
          .map(ChoiceOption.fromJson)
          .toList(),
      subfields: subfieldsRaw
          .whereType<Map<String, dynamic>>()
          .map(FormSubfield.fromJson)
          .toList(),
      placeholder: json['placeholder']?.toString(),
      maxSizeMb: (json['max_size_mb'] as num?)?.toInt(),
      allowedExt: ext.map((e) => e.toString().toLowerCase()).toList(),
      consentHtml: json['consent_html']?.toString(),
      pageIndex: (json['page_index'] as num?)?.toInt() ?? 0,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      maxFiles: (json['max_files'] as num?)?.toInt() ?? 1,
      infoHtml: json['html']?.toString(),
      step: (json['step'] as num?)?.toDouble(),
      visibility: visibilityRaw != null
          ? FormFieldVisibility.fromJson(visibilityRaw)
          : null,
    );
  }

  final String key;
  final String label;
  final String type;
  final bool required;
  final String sectionId;
  final List<String> options;
  final List<ChoiceOption> choiceOptions;
  final List<FormSubfield> subfields;
  final String? placeholder;
  final int? maxSizeMb;
  final List<String> allowedExt;
  final FormFieldVisibility? visibility;
  final String? consentHtml;
  final int pageIndex;
  final double? min;
  final double? max;
  final int maxFiles;
  final String? infoHtml;
  final double? step;

  /// Choice options from schema v2, or legacy `options` strings as value+label.
  List<ChoiceOption> get effectiveChoiceOptions {
    if (choiceOptions.isNotEmpty) return choiceOptions;
    return options
        .map((o) => ChoiceOption(value: o, label: o))
        .toList();
  }

  bool get isMultiFileUpload => type == 'upload' && maxFiles > 1;

  bool get hasSubfields => subfields.isNotEmpty;
}

/// Forminator show/hide rules exported from the App API.
class FormFieldVisibility {
  const FormFieldVisibility({
    required this.action,
    required this.match,
    required this.when,
  });

  factory FormFieldVisibility.fromJson(Map<String, dynamic> json) {
    final whenRaw = json['when'] as List<dynamic>? ?? [];
    return FormFieldVisibility(
      action: json['action']?.toString() ?? 'show',
      match: json['match']?.toString() ?? 'all',
      when: whenRaw
          .whereType<Map<String, dynamic>>()
          .map(FormVisibilityRule.fromJson)
          .toList(),
    );
  }

  final String action;
  final String match;
  final List<FormVisibilityRule> when;
}

class FormVisibilityRule {
  const FormVisibilityRule({
    required this.field,
    required this.operator,
    required this.value,
  });

  factory FormVisibilityRule.fromJson(Map<String, dynamic> json) {
    return FormVisibilityRule(
      field: json['field']?.toString() ?? '',
      operator: json['operator']?.toString() ?? 'is',
      value: json['value']?.toString() ?? '',
    );
  }

  final String field;
  final String operator;
  final String value;

  bool get isDateOperator => const {
        'day_is',
        'day_is_not',
        'month_is',
        'month_is_not',
        'is_before',
        'is_after',
        'is_before_n_or_more_days',
        'is_before_less_than_n_days',
        'is_after_n_or_more_days',
        'is_after_less_than_n_days',
      }.contains(operator);
}
