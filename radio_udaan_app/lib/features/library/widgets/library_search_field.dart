import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_colors.dart';
import '../library_providers.dart';
import 'library_section_heading.dart';

/// Search Videos block — heading + bordered field (magnifier on the right).
class LibrarySearchField extends ConsumerStatefulWidget {
  const LibrarySearchField({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  ConsumerState<LibrarySearchField> createState() => _LibrarySearchFieldState();
}

class _LibrarySearchFieldState extends ConsumerState<LibrarySearchField> {
  @override
  Widget build(BuildContext context) {
    final query = ref.watch(librarySearchQueryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LibrarySectionHeading(title: AppStrings.librarySearchVideos),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
          child: Semantics(
            label:
                '${AppStrings.librarySearchVideos}, ${AppStrings.librarySearchHint}',
            textField: true,
            child: TextField(
              controller: widget.controller,
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: UdaanColors.onBackground,
              ),
              decoration: InputDecoration(
                hintText: AppStrings.librarySearchHint,
                hintStyle: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: UdaanColors.onSurfaceMuted,
                ),
                suffixIcon: query.isNotEmpty
                    ? Semantics(
                        button: true,
                        label: AppStrings.cancel,
                        child: IconButton(
                          onPressed: () {
                            widget.controller.clear();
                            ref.read(librarySearchQueryProvider.notifier).state =
                                '';
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: UdaanColors.primaryGlow,
                          ),
                        ),
                      )
                    : const ExcludeSemantics(
                        child: Icon(
                          Icons.search,
                          color: UdaanColors.primaryGlow,
                        ),
                      ),
                filled: true,
                fillColor: UdaanColors.surfaceContainer,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: UdaanColors.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: UdaanColors.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: UdaanColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
