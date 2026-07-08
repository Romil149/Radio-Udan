import 'package:country_picker/country_picker.dart';

import 'phone_e164.dart';

/// Default market for Radio Udaan (India-first, worldwide capable).
Country defaultPhoneCountry() => Country.parse('IN');

/// Builds E.164 from [country] dial code and national digits only.
String? e164FromCountryAndNational(Country country, String nationalInput) {
  final national = nationalInput.replaceAll(RegExp(r'\D'), '');
  if (national.isEmpty) return null;
  return normalizeE164Phone('+${country.phoneCode}$national');
}

/// Max national digits for a country.
///
/// Uses the package's example national number length (e.g. India 10, UAE 9,
/// Singapore 8) so the input cannot exceed the real subscriber-number length.
/// Falls back to the ITU-T E.164 ceiling (15 − country code) when no example
/// is available (e.g. World Wide).
int maxNationalDigitsForCountry(Country country) {
  final exampleDigits = country.example.replaceAll(RegExp(r'\D'), '');
  if (exampleDigits.isNotEmpty) {
    return exampleDigits.length;
  }
  final ccLen = country.phoneCode.length;
  return (15 - ccLen).clamp(4, 14);
}

/// Splits a normalized E.164 string into country + national subscriber number.
({Country country, String national})? splitE164Phone(String? e164) {
  if (e164 == null || e164.trim().isEmpty) return null;

  final normalized =
      normalizeE164Phone(e164.trim()) ?? normalizeIndiaPhone(e164.trim());
  if (normalized == null || !normalized.startsWith('+')) return null;

  final allDigits = normalized.substring(1);
  final service = CountryService();
  final countries = List<Country>.from(service.getAll())
    ..sort((a, b) => b.phoneCode.length.compareTo(a.phoneCode.length));

  for (final country in countries) {
    final code = country.phoneCode;
    if (code.isEmpty) continue;
    if (!allDigits.startsWith(code)) continue;
    final national = allDigits.substring(code.length);
    if (national.isEmpty) continue;
    return (country: country, national: national);
  }

  return (country: defaultPhoneCountry(), national: allDigits);
}

