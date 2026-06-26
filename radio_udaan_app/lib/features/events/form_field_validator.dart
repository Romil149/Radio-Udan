import '../../core/utils/phone_e164.dart';
import '../auth/auth_validators.dart';
import 'models/form_schema.dart';

/// Client-side validation mirroring server constraints for a single field.
String? validateField(FormFieldSchema field, dynamic value) {
  if (field.hasSubfields) {
    return _validateSubfields(field, value);
  }

  if (_isEmpty(value, field)) {
    if (field.required) {
      return _requiredMessage(field);
    }
    return null;
  }

  if (field.type == 'email' && !isValidEmail(value.toString())) {
    return 'Enter a valid email address.';
  }

  if (field.type == 'phone') {
    final normalized = normalizeE164Phone(value.toString()) ??
        normalizeIndiaPhone(value.toString());
    if (normalized == null) {
      return 'Enter a valid mobile number.';
    }
  }

  if (field.type == 'url' && !_isValidUrl(value.toString())) {
    return 'Enter a valid URL starting with http:// or https://.';
  }

  if (field.type == 'number' || field.type == 'slider') {
    final n = double.tryParse(value.toString().trim());
    if (n == null) {
      return 'Enter a valid number.';
    }
    if (field.min != null && n < field.min!) {
      return 'Minimum value is ${field.min!.toStringAsFixed(field.min! % 1 == 0 ? 0 : 1)}.';
    }
    if (field.max != null && n > field.max!) {
      return 'Maximum value is ${field.max!.toStringAsFixed(field.max! % 1 == 0 ? 0 : 1)}.';
    }
  }

  if (field.type == 'radio' || field.type == 'select' || field.type == 'rating') {
    if (!_choiceAllowed(field, value.toString())) {
      return 'Invalid selection.';
    }
  }

  if (field.type == 'checkbox') {
    if (field.effectiveChoiceOptions.length > 1 && value is List) {
      for (final item in value) {
        if (!_choiceAllowed(field, item.toString())) {
          return 'Invalid selection.';
        }
      }
    } else if (field.required && value != true && value != '1') {
      return _requiredMessage(field);
    }
  }

  if (field.type == 'upload' &&
      field.isMultiFileUpload &&
      field.required &&
      value is! List) {
    return _requiredMessage(field);
  }

  return null;
}

String? _validateSubfields(FormFieldSchema field, dynamic value) {
  final map = value is Map
      ? Map<String, dynamic>.from(value)
      : <String, dynamic>{};

  for (final sub in field.subfields) {
    final raw = map[sub.key];
    final text = raw?.toString().trim() ?? '';
    if (sub.required && text.isEmpty) {
      return '${_cleanLabel(sub.label)}. This field is required.';
    }
  }

  if (field.required) {
    final anyFilled = field.subfields.any((sub) {
      final text = map[sub.key]?.toString().trim() ?? '';
      return text.isNotEmpty;
    });
    if (!anyFilled) {
      return _requiredMessage(field);
    }
  }

  return null;
}

bool _isEmpty(dynamic value, FormFieldSchema field) {
  if (value == null) return true;
  if (value is bool) {
    if (field.type == 'checkbox' &&
        field.effectiveChoiceOptions.length <= 1) {
      return !value;
    }
  }
  if (value is List) return value.isEmpty;
  if (value is Map) {
    return value.values.every(
      (v) => v == null || v.toString().trim().isEmpty,
    );
  }
  return value.toString().trim().isEmpty;
}

bool _choiceAllowed(FormFieldSchema field, String selected) {
  if (selected.isEmpty) return true;
  final allowed = field.effectiveChoiceOptions;
  if (allowed.isEmpty) return true;
  return allowed.any(
    (opt) => opt.value == selected || opt.label == selected,
  );
}

bool _isValidUrl(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme) return false;
  return uri.scheme == 'http' || uri.scheme == 'https';
}

String _requiredMessage(FormFieldSchema field) {
  final label = _cleanLabel(field.label);
  return label.isEmpty
      ? 'This field is required.'
      : '$label. This field is required.';
}

String _cleanLabel(String raw) {
  return raw.replaceAll(RegExp(r'\s*\*+\s*$'), '').trim();
}
