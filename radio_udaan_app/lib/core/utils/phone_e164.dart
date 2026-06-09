/// Worldwide E.164 normalization (+[country][subscriber], 8–15 digits total).
String? normalizeE164Phone(String input) {
  var trimmed = input.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  if (trimmed.isEmpty) return null;

  if (!trimmed.startsWith('+')) {
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    trimmed = '+$digits';
  }

  if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(trimmed)) {
    return null;
  }

  return trimmed;
}

/// India-first helper (10-digit local → +91…) — alias for legacy call sites.
String? normalizeIndiaPhone(String input) {
  var digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.startsWith('91') && digits.length == 12) {
    return '+$digits';
  }
  if (digits.length == 10) {
    return '+91$digits';
  }
  return normalizeE164Phone(input);
}

/// Auth form submit: E.164 when + is present; legacy 10-digit India otherwise.
String? resolveSubmittedPhone(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.contains('+')) {
    return normalizeE164Phone(trimmed);
  }
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.length <= 10) {
    return normalizeIndiaPhone(trimmed);
  }
  return normalizeE164Phone(trimmed);
}

/// Prefills phone fields from login identifier or partial user input.
String phoneInputForDisplay(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';

  final e164 =
      normalizeE164Phone(trimmed) ?? normalizeIndiaPhone(trimmed);
  if (e164 != null) {
    return e164;
  }

  return trimmed.replaceAll(RegExp(r'[^\d+\s\-]'), '');
}

/// Resolves login identifier input to E.164 when it is a phone number.
String? phoneE164FromIdentifier(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed.contains('@')) {
    return null;
  }
  return normalizeE164Phone(trimmed) ?? normalizeIndiaPhone(trimmed);
}

/// Last four digits for “ending in •••• 4209” copy.
String phoneLastFourDigits(String? e164) {
  final digits = (e164 ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) {
    return digits.padLeft(4, '0');
  }
  return digits.substring(digits.length - 4);
}

/// Masked display for OTP screens (country prefix + obscured middle + last 4).
String maskPhoneForOtpDisplay(String? e164) {
  if (e164 == null || e164.isEmpty) {
    return '•••• ••••';
  }

  final normalized = normalizeE164Phone(e164) ?? e164;
  final lastFour = phoneLastFourDigits(normalized);

  if (normalized.startsWith('+91')) {
    return '+91 XXXXX $lastFour';
  }
  if (normalized.startsWith('+1')) {
    return '+1 ••• ••• $lastFour';
  }

  final country = RegExp(r'^(\+\d{1,3})').firstMatch(normalized)?.group(1) ?? '+';
  return '$country ••••• $lastFour';
}
