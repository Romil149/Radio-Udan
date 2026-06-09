import '../../core/models/auth_session.dart';
import 'models/form_schema.dart';

/// Whether a Forminator text field represents the registrant's full name.
bool looksLikeNameField(FormFieldSchema field) {
  if (field.type != 'text') return false;
  final label = field.label.toLowerCase();
  final key = field.key.toLowerCase();
  return label.contains('full name') ||
      label.contains('your name') ||
      (label.contains('name') && !label.contains('user name')) ||
      key.contains('name');
}

bool looksLikePhoneField(FormFieldSchema field) {
  if (field.type == 'phone') return true;
  if (field.type != 'text') return false;
  final label = field.label.toLowerCase();
  final key = field.key.toLowerCase();
  return label.contains('phone') ||
      label.contains('mobile') ||
      label.contains('contact number') ||
      key.contains('phone');
}

/// Value from the signed-in account for a schema field, if applicable.
String? accountValueForField(FormFieldSchema field, AuthSession user) {
  if (looksLikePhoneField(field) && user.phoneE164.trim().isNotEmpty) {
    return user.phoneE164.trim();
  }
  if (field.type == 'email' && (user.email?.trim().isNotEmpty ?? false)) {
    return user.email!.trim();
  }
  if (looksLikeNameField(field) && (user.name?.trim().isNotEmpty ?? false)) {
    return user.name!.trim();
  }
  return null;
}

/// Display E.164 phone in a screen-reader-friendly grouped format.
String formatPhoneForDisplay(String e164) {
  final trimmed = e164.trim();
  if (trimmed.startsWith('+91') && trimmed.length >= 13) {
    final rest = trimmed.substring(3).replaceAll(RegExp(r'\D'), '');
    if (rest.length == 10) {
      return '+91 ${rest.substring(0, 5)} ${rest.substring(5)}';
    }
  }
  return trimmed;
}

String displayValueForField(FormFieldSchema field, dynamic raw) {
  if (raw == null) return '';
  final text = raw.toString();
  if (looksLikePhoneField(field)) return formatPhoneForDisplay(text);
  return text;
}
