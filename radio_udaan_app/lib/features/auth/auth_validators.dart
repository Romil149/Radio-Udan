import '../../core/utils/phone_e164.dart';

/// Normalizes login/forgot-password identifier to email or E.164 phone.
String? normalizeAuthIdentifier(String input) {
  final trimmed = input.trim();
  if (trimmed.contains('@')) {
    return _isValidEmail(trimmed) ? trimmed.toLowerCase() : null;
  }
  return normalizeE164Phone(trimmed) ?? normalizeIndiaPhone(trimmed);
}

bool _isValidEmail(String email) {
  return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
}

bool isValidEmail(String email) => _isValidEmail(email.trim());

bool isValidPassword(String password, {int minLength = 8}) =>
    password.length >= minLength;
