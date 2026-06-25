import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/phone_country.dart';
import '../../../core/utils/phone_e164.dart';

/// Country picker + national number → E.164 via [e164].
class PhoneCountryInputController extends ChangeNotifier {
  PhoneCountryInputController({Country? initialCountry})
      : country = initialCountry ?? defaultPhoneCountry(),
        nationalController = TextEditingController();

  Country country;
  final TextEditingController nationalController;

  String? get e164 => e164FromCountryAndNational(country, nationalController.text);

  int get maxNationalDigits => maxNationalDigitsForCountry(country);

  void selectCountry(Country value) {
    if (value.countryCode == country.countryCode) return;
    country = value;
    notifyListeners();
  }

  void setFromRawInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;

    final e164 = resolveSubmittedPhone(trimmed) ??
        normalizeE164Phone(trimmed) ??
        normalizeIndiaPhone(trimmed);

    if (e164 != null) {
      final split = splitE164Phone(e164);
      if (split != null) {
        country = split.country;
        nationalController.text = split.national;
        notifyListeners();
        return;
      }
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (!trimmed.contains('+') && digitsOnly.isNotEmpty) {
      nationalController.text = digitsOnly;
    }
  }

  @override
  void dispose() {
    nationalController.dispose();
    super.dispose();
  }
}

/// Split control: [country flag + dial code ▼] [national number].
class UdaanPhoneField extends StatefulWidget {
  const UdaanPhoneField({
    required this.copy,
    required this.controller,
    this.label,
    this.helperText,
    this.nationalHint,
    this.textInputAction,
    this.onSubmitted,
    this.required = false,
    super.key,
  });

  final AppCopy copy;
  final PhoneCountryInputController controller;
  final String? label;
  final String? helperText;
  final String? nationalHint;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool required;

  @override
  State<UdaanPhoneField> createState() => _UdaanPhoneFieldState();
}

class _UdaanPhoneFieldState extends State<UdaanPhoneField> {
  PhoneCountryInputController get _input => widget.controller;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      favorite: const ['IN'],
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: UdaanColors.surfaceContainer,
        textStyle: GoogleFonts.atkinsonHyperlegible(
          fontSize: 16,
          color: UdaanColors.onBackground,
        ),
        searchTextStyle: GoogleFonts.atkinsonHyperlegible(
          fontSize: 16,
          color: UdaanColors.onBackground,
        ),
        inputDecoration: InputDecoration(
          hintText: widget.copy.phoneCountrySearchHint,
          hintStyle: GoogleFonts.atkinsonHyperlegible(color: UdaanColors.hint),
          filled: true,
          fillColor: UdaanColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: UdaanColors.outlineVariant),
          ),
        ),
      ),
      onSelect: _input.selectCountry,
    );
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.atkinsonHyperlegible(
        fontSize: 18,
        color: UdaanColors.hint,
      ),
      filled: true,
      fillColor: UdaanColors.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UdaanColors.primaryGlow),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: UdaanColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final country = _input.country;
    final label = widget.label ?? widget.copy.phoneFieldLabel;
    final helper = widget.helperText ?? widget.copy.phoneFieldHelper;
    final hint = widget.nationalHint ?? widget.copy.phoneNationalHint;
    final countryLabel = widget.copy.phoneCountryCodeSemantics(
      countryName: country.name,
      dialCode: country.phoneCode,
    );
    final nationalSemanticsLabel = [
      label,
      country.name,
      'plus ${country.phoneCode}',
      if (widget.required) 'required',
    ].join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: UdaanColors.onBackground,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Text(
            helper,
            style: GoogleFonts.atkinsonHyperlegible(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: UdaanColors.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: true,
              label: countryLabel,
              child: SizedBox(
                width: 132,
                child: Material(
                  color: UdaanColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _openCountryPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: UdaanColors.primaryGlow),
                      ),
                      child: Row(
                        children: [
                          Text(
                            country.flagEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '+${country.phoneCode}',
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: UdaanColors.onBackground,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: UdaanColors.primaryGlow,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                textField: true,
                label: nationalSemanticsLabel,
                child: TextField(
                  controller: _input.nationalController,
                  keyboardType: TextInputType.phone,
                  textInputAction: widget.textInputAction,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_input.maxNationalDigits),
                  ],
                  onSubmitted: widget.onSubmitted,
                  style: GoogleFonts.atkinsonHyperlegible(
                    fontSize: 18,
                    color: UdaanColors.onBackground,
                  ),
                  decoration: _fieldDecoration(hint: hint),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
