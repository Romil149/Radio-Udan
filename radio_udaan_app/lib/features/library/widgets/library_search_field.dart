import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/brand_tokens.dart';
import '../../../core/utils/keyboard_dismiss.dart';
import '../../../core/theme/udaan_colors.dart';
import '../library_providers.dart';
import 'library_section_heading.dart';
import '../../../core/providers/app_providers.dart';

/// Search Videos block — heading + bordered field (magnifier on the right).
class LibrarySearchField extends ConsumerStatefulWidget {
  const LibrarySearchField({
    required this.controller,
    this.focusNode,
    this.sectionKey,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final GlobalKey? sectionKey;

  @override
  ConsumerState<LibrarySearchField> createState() => _LibrarySearchFieldState();
}

class _LibrarySearchFieldState extends ConsumerState<LibrarySearchField> {
  AppCopy get _copy => ref.read(appCopyProvider);

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(librarySearchQueryProvider);

    return Column(
      key: widget.sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LibrarySectionHeading(title: _copy.librarySearchVideos),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
          child: Semantics(
            label: _copy.librarySearchHint,
            textField: true,
            child: ExcludeSemantics(
              child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => dismissKeyboard(context),
              onTapOutside: (_) => dismissKeyboard(context),
              style: GoogleFonts.atkinsonHyperlegible(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: context.udaan.onBackground,
              ),
              decoration: InputDecoration(
                hintText: _copy.librarySearchHint,
                hintStyle: GoogleFonts.atkinsonHyperlegible(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: context.udaan.onSurfaceMuted,
                ),
                suffixIcon: query.isNotEmpty
                    ? Semantics(
                        button: true,
                        label: _copy.cancel,
                        child: ExcludeSemantics(
                          child: IconButton(
                            onPressed: () {
                              widget.controller.clear();
                              ref
                                  .read(librarySearchQueryProvider.notifier)
                                  .state = '';
                            },
                            icon: Icon(
                              Icons.clear,
                              color: context.udaan.primaryGlow,
                            ),
                          ),
                        ),
                      )
                    : ExcludeSemantics(
                        child: Icon(
                          Icons.search,
                          color: context.udaan.primaryGlow,
                        ),
                      ),
                filled: true,
                fillColor: context.udaan.surfaceContainer,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.udaan.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.udaan.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: context.udaan.primary,
                    width: 2,
                  ),
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
