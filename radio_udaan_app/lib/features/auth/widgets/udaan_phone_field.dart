import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/config/app_copy_accessors.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/udaan_colors.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/widgets/accessible_country_picker_sheet.dart';
import '../../../core/widgets/keyboard_accessory.dart';
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
    this.focusNode,
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
  final FocusNode? focusNode;
  final bool required;

  @override
  State<UdaanPhoneField> createState() => _UdaanPhoneFieldState();
}

class _UdaanPhoneFieldState extends State<UdaanPhoneField> {
  PhoneCountryInputController get _input => widget.controller;
  FocusNode? _ownedFocusNode;

  FocusNode get _numberFocus => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _input.addListener(_onInputChanged);
    _input.nationalController.addListener(_onNationalTextChanged);
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.nationalController.removeListener(_onNationalTextChanged);
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  void _onNationalTextChanged() {
    final text = _input.nationalController.text;
    if (text.contains('+') ||
        text.startsWith('00') ||
        text.length > _input.maxNationalDigits + 1) {
      _input.setFromRawInput(text);
    }
  }

  Future<void> _openCountryPicker() async {
    dismissKeyboard(context);
    final selected = await showAccessibleCountryPicker(
      context: context,
      copy: widget.copy,
    );
    if (selected != null) {
      _input.selectCountry(selected);
    }
  }

  InputDecoration _fieldDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.atkinsonHyperlegible(
        fontSize: 18,
        color: context.udaan.hint,
      ),
      filled: true,
      fillColor: context.udaan.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.udaan.primaryGlow),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.udaan.primary, width: 2),
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
              color: context.udaan.onBackground,
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
              color: context.udaan.onSurfaceVariant,
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
                  color: context.udaan.surfaceContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _openCountryPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.udaan.primaryGlow),
                      ),
                      child: ExcludeSemantics(
                        child: Row(
                          children: [
                            Text(
                              country.flagEmoji,
                              style: TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '+${country.phoneCode}',
                                style: GoogleFonts.atkinsonHyperlegible(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: context.udaan.onBackground,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: context.udaan.primaryGlow,
                            ),
                          ],
                        ),
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
                child: ExcludeSemantics(
                  child: KeyboardAccessory(
                    focusNode: _numberFocus,
                    doneLabel: widget.copy.keyboardDone,
                    nextLabel:
                        widget.textInputAction == TextInputAction.next
                            ? widget.copy.keyboardNext
                            : null,
                    onNext: widget.textInputAction == TextInputAction.next
                        ? () => FocusScope.of(context).nextFocus()
                        : null,
                    child: TextField(
                      controller: _input.nationalController,
                      focusNode: _numberFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: widget.textInputAction,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          _input.maxNationalDigits,
                        ),
                      ],
                      onChanged: (_) => _onNationalTextChanged(),
                      onSubmitted: (value) {
                        if (widget.textInputAction == TextInputAction.next) {
                          FocusScope.of(context).nextFocus();
                          return;
                        }
                        dismissKeyboard(context);
                        widget.onSubmitted?.call(value);
                      },
                      onTapOutside: (_) => dismissKeyboard(context),
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 18,
                        color: context.udaan.onBackground,
                      ),
                      decoration: _fieldDecoration(hint: hint),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
