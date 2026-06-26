import 'models/form_schema.dart';

/// Whether a schema field should be shown for the current answers.
bool isFormFieldVisible(
  FormFieldSchema field,
  List<FormFieldSchema> allFields,
  Map<String, dynamic> values,
) {
  final visibility = field.visibility;
  if (visibility == null || visibility.when.isEmpty) {
    return true;
  }

  final fieldsByKey = {
    for (final f in allFields) f.key: f,
  };

  return _isVisible(field, fieldsByKey, values, {});
}

bool _isVisible(
  FormFieldSchema field,
  Map<String, FormFieldSchema> fieldsByKey,
  Map<String, dynamic> values,
  Set<String> visiting,
) {
  if (visiting.contains(field.key)) {
    return true;
  }

  final visibility = field.visibility;
  if (visibility == null || visibility.when.isEmpty) {
    return true;
  }

  visiting.add(field.key);
  final matched = _conditionsMatched(
    visibility,
    fieldsByKey,
    values,
    visiting,
  );
  visiting.remove(field.key);

  if (visibility.action == 'show') {
    return matched;
  }
  return !matched;
}

bool _conditionsMatched(
  FormFieldVisibility visibility,
  Map<String, FormFieldSchema> fieldsByKey,
  Map<String, dynamic> values,
  Set<String> visiting,
) {
  final rules = visibility.when;
  if (rules.isEmpty) return true;

  var fulfilled = 0;
  var count = 0;

  for (final rule in rules) {
    if (rule.field.isEmpty) continue;
    count++;

    final dep = fieldsByKey[rule.field];
    if (dep != null &&
        !_isVisible(dep, fieldsByKey, values, visiting)) {
      if (visibility.match == 'all') return false;
      continue;
    }

    final matched = _ruleMatches(rule, values, fieldsByKey);
    if (matched) {
      fulfilled++;
    } else if (visibility.match == 'all') {
      return false;
    }

    if (visibility.match == 'any' && fulfilled > 0) {
      return true;
    }
  }

  if (count == 0) return true;
  if (visibility.match == 'any') return fulfilled > 0;
  return fulfilled == count;
}

bool _ruleMatches(
  FormVisibilityRule rule,
  Map<String, dynamic> values,
  Map<String, FormFieldSchema> fieldsByKey,
) {
  if (rule.isDateOperator) {
    return _dateRuleMatches(rule, values[rule.field]);
  }

  final dep = fieldsByKey[rule.field];
  final raw = values[rule.field];
  final expected = rule.value.trim().toLowerCase();

  switch (rule.operator) {
    case 'is':
      return matchChoiceValue(dep, raw, expected);

    case 'is_not':
      return !matchChoiceValue(dep, raw, expected);

    case 'is_great':
      final value = _normalizeValue(raw);
      if (!_isNumeric(value) || !_isNumeric(expected)) return false;
      return double.parse(value) > double.parse(expected);

    case 'is_less':
      final value = _normalizeValue(raw);
      if (!_isNumeric(value) || !_isNumeric(expected)) return false;
      return double.parse(value) < double.parse(expected);

    case 'contains':
      final value = _normalizeValue(raw);
      if (value is List<String>) {
        return value.any((item) => item.contains(expected));
      }
      return value.toLowerCase().contains(expected);

    case 'does_not_contain':
      final value = _normalizeValue(raw);
      if (value is List<String>) {
        return !value.any((item) => item.contains(expected));
      }
      return !value.toLowerCase().contains(expected);

    case 'starts':
      final value = _normalizeValue(raw);
      if (value is List<String>) {
        return value.any((item) => item.startsWith(expected));
      }
      return value.toLowerCase().startsWith(expected);

    case 'ends':
      final value = _normalizeValue(raw);
      if (value is List<String>) {
        return value.any((item) => item.endsWith(expected));
      }
      return value.toLowerCase().endsWith(expected);

    default:
      return false;
  }
}

/// Compares a stored choice against an expected rule value using value and label.
bool matchChoiceValue(
  FormFieldSchema? field,
  dynamic raw,
  String expected,
) {
  final normalizedExpected = expected.trim().toLowerCase();
  if (normalizedExpected.isEmpty) return false;

  if (raw is List) {
    return raw.any(
      (item) => matchChoiceValue(field, item, normalizedExpected),
    );
  }

  final stored = _normalizeValue(raw);
  if (stored is List<String>) {
    return stored.any(
      (item) => matchChoiceValue(field, item, normalizedExpected),
    );
  }

  final storedStr = stored.toString();
  if (storedStr == normalizedExpected) return true;

  final options = field?.effectiveChoiceOptions ?? const <ChoiceOption>[];
  if (options.isEmpty) {
    if (_isNumeric(storedStr) && _isNumeric(normalizedExpected)) {
      return double.parse(storedStr) == double.parse(normalizedExpected);
    }
    return false;
  }

  for (final opt in options) {
    final valueMatch = opt.value.toLowerCase() == storedStr ||
        opt.label.toLowerCase() == storedStr;
    if (!valueMatch) continue;
    if (opt.value.toLowerCase() == normalizedExpected ||
        opt.label.toLowerCase() == normalizedExpected) {
      return true;
    }
  }

  return false;
}

bool _dateRuleMatches(FormVisibilityRule rule, dynamic raw) {
  final parsed = parseFlexibleDate(raw);
  if (parsed == null) {
    return _oppositeDateOperator(rule.operator);
  }

  final expected = rule.value.trim().toLowerCase();

  switch (rule.operator) {
    case 'day_is':
      return parsed.weekday % 7 == _parseDayToken(expected);
    case 'day_is_not':
      return parsed.weekday % 7 != _parseDayToken(expected);
    case 'month_is':
      return parsed.month - 1 == _parseMonthToken(expected);
    case 'month_is_not':
      return parsed.month - 1 != _parseMonthToken(expected);
    case 'is_before':
      final target = parseFlexibleDate(expected);
      if (target == null) return false;
      return _dateOnly(parsed).isBefore(_dateOnly(target));
    case 'is_after':
      final target = parseFlexibleDate(expected);
      if (target == null) return false;
      return _dateOnly(parsed).isAfter(_dateOnly(target));
    case 'is_before_n_or_more_days':
      final n = int.tryParse(expected) ?? 0;
      final diff = _daysBetween(_dateOnly(parsed), _today());
      if (n == 0) return diff == 0;
      return diff >= n;
    case 'is_before_less_than_n_days':
      final n = int.tryParse(expected) ?? 0;
      final diff = _daysBetween(_dateOnly(parsed), _today());
      return diff > 0 && diff < n;
    case 'is_after_n_or_more_days':
      final n = int.tryParse(expected) ?? 0;
      final diff = _daysBetween(_today(), _dateOnly(parsed));
      if (n == 0) return diff == 0;
      return diff >= n;
    case 'is_after_less_than_n_days':
      final n = int.tryParse(expected) ?? 0;
      final diff = _daysBetween(_today(), _dateOnly(parsed));
      return diff > 0 && diff < n;
    default:
      return false;
  }
}

bool _oppositeDateOperator(String operator) {
  return operator == 'day_is_not' || operator == 'month_is_not';
}

/// Parses API date strings (`yyyy-MM-dd`, `yyyy-MM-dd HH:mm`, ISO, dd/mm/yy).
DateTime? parseFlexibleDate(dynamic raw) {
  if (raw == null) return null;
  var text = raw.toString().trim();
  if (text.isEmpty) return null;

  text = text.replaceFirst(' ', 'T');
  final iso = DateTime.tryParse(text);
  if (iso != null) return iso;

  for (final pattern in [
    RegExp(r'^(\d{2})/(\d{2})/(\d{2,4})$'),
    RegExp(r'^(\d{2})-(\d{2})-(\d{2,4})$'),
    RegExp(r'^(\d{2})\.(\d{2})\.(\d{2,4})$'),
  ]) {
    final match = pattern.firstMatch(text);
    if (match == null) continue;
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(1)!);
    return DateTime(year, month, day);
  }

  return null;
}

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

int _daysBetween(DateTime from, DateTime to) {
  return to.difference(from).inDays;
}

int _parseDayToken(String token) {
  const days = {
    'su': 0,
    'sun': 0,
    'mo': 1,
    'mon': 1,
    'tu': 2,
    'tue': 2,
    'we': 3,
    'wed': 3,
    'th': 4,
    'thu': 4,
    'fr': 5,
    'fri': 5,
    'sa': 6,
    'sat': 6,
  };
  if (days.containsKey(token)) return days[token]!;
  final n = int.tryParse(token);
  if (n != null && n >= 0 && n <= 6) return n;
  return 0;
}

int _parseMonthToken(String token) {
  const months = {
    'jan': 0,
    'feb': 1,
    'mar': 2,
    'apr': 3,
    'may': 4,
    'jun': 5,
    'jul': 6,
    'aug': 7,
    'sep': 8,
    'oct': 9,
    'nov': 10,
    'dec': 11,
  };
  if (months.containsKey(token)) return months[token]!;
  final n = int.tryParse(token);
  if (n != null && n >= 0 && n <= 11) return n;
  return 0;
}

dynamic _normalizeValue(dynamic raw) {
  if (raw is List) {
    return raw.map((e) => e.toString().trim().toLowerCase()).toList();
  }
  if (raw is bool) {
    return raw ? '1' : '';
  }
  if (raw is num) {
    return raw.toString();
  }
  return raw?.toString().trim().toLowerCase() ?? '';
}

bool _isNumeric(String value) {
  if (value.isEmpty) return false;
  return double.tryParse(value) != null;
}

/// Visible fields in schema order.
List<FormFieldSchema> visibleFormFields(
  FormSchema schema,
  Map<String, dynamic> values,
) {
  return schema.fields
      .where((f) => isFormFieldVisible(f, schema.fields, values))
      .toList();
}

/// Payload with hidden field keys removed.
Map<String, dynamic> visibleFormPayload(
  FormSchema schema,
  Map<String, dynamic> values,
) {
  final visibleKeys = visibleFormFields(schema, values).map((f) => f.key).toSet();
  return Map.fromEntries(
    values.entries.where((e) => visibleKeys.contains(e.key)),
  );
}
