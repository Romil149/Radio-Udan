import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../accessibility/udaan_semantics.dart';
import '../config/app_branding.dart';
import '../config/app_copy_accessors.dart';
import '../theme/brand_tokens.dart';
import '../theme/udaan_colors.dart';
import '../utils/keyboard_dismiss.dart';

/// VoiceOver-friendly country picker (search + list) replacing the default sheet.
Future<Country?> showAccessibleCountryPicker({
  required BuildContext context,
  required AppCopy copy,
  List<String> favoriteIso = const ['IN'],
}) {
  return showModalBottomSheet<Country>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.udaan.surfaceContainer,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return UdaanModalSheet(
        title: copy.phoneCountryPickerTitle,
        child: _AccessibleCountryPickerSheet(
          copy: copy,
          favoriteIso: favoriteIso,
        ),
      );
    },
  );
}

class _AccessibleCountryPickerSheet extends StatefulWidget {
  const _AccessibleCountryPickerSheet({
    required this.copy,
    required this.favoriteIso,
  });

  final AppCopy copy;
  final List<String> favoriteIso;

  @override
  State<_AccessibleCountryPickerSheet> createState() =>
      _AccessibleCountryPickerSheetState();
}

class _AccessibleCountryPickerSheetState
    extends State<_AccessibleCountryPickerSheet> {
  final _searchController = TextEditingController();
  late List<Country> _allCountries;

  @override
  void initState() {
    super.initState();
    final service = CountryService();
    _allCountries = List<Country>.from(service.getAll())
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Country> get _filteredCountries {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _allCountries;
    return _allCountries.where((country) {
      final name = country.name.toLowerCase();
      final code = country.countryCode.toLowerCase();
      final dial = country.phoneCode;
      return name.contains(query) ||
          code.contains(query) ||
          dial.contains(query) ||
          '+$dial'.contains(query);
    }).toList();
  }

  List<Country> get _favoriteCountries {
    final favorites = <Country>[];
    for (final iso in widget.favoriteIso) {
      final match = _allCountries.where((c) => c.countryCode == iso);
      favorites.addAll(match);
    }
    return favorites;
  }

  String _countrySemanticsLabel(Country country) {
    return widget.copy.phoneCountryCodeSemantics(
      countryName: country.name,
      dialCode: country.phoneCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = _favoriteCountries;
    final countries = _filteredCountries;
    final query = _searchController.text.trim();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            BrandTokens.screenPadding,
            12,
            BrandTokens.screenPadding,
            16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UdaanScreenHeader(
                title: widget.copy.phoneCountryPickerTitle,
                style: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: context.udaan.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: widget.copy.phoneCountrySearchHint,
                textField: true,
                child: ExcludeSemantics(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    onTapOutside: (_) => dismissKeyboard(context),
                    style: GoogleFonts.atkinsonHyperlegible(
                      fontSize: 16,
                      color: context.udaan.onBackground,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.copy.phoneCountrySearchHint,
                    filled: true,
                    fillColor: context.udaan.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: context.udaan.outlineVariant),
                    ),
                  ),
                ),
              ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    if (query.isEmpty && favorites.isNotEmpty) ...[
                      Semantics(
                        header: true,
                        label: widget.copy.phoneCountryFavorites,
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              widget.copy.phoneCountryFavorites,
                              style: GoogleFonts.atkinsonHyperlegible(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: context.udaan.primaryGlow,
                              ),
                            ),
                          ),
                        ),
                      ),
                      for (final country in favorites)
                        _CountryTile(
                          country: country,
                          semanticsLabel: _countrySemanticsLabel(country),
                          onTap: () => Navigator.of(context).pop(country),
                        ),
                      const SizedBox(height: 12),
                    ],
                    for (final country in countries)
                      _CountryTile(
                        country: country,
                        semanticsLabel: _countrySemanticsLabel(country),
                        onTap: () => Navigator.of(context).pop(country),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({
    required this.country,
    required this.semanticsLabel,
    required this.onTap,
  });

  final Country country;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Text(
                      country.flagEmoji,
                      style: TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        country.name,
                        style: GoogleFonts.atkinsonHyperlegible(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: context.udaan.onBackground,
                        ),
                      ),
                    ),
                    Text(
                      '+${country.phoneCode}',
                      style: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.udaan.primaryGlow,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
