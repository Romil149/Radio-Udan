import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/accessibility/accessible_text_field_semantics.dart';
import '../../../core/accessibility/udaan_semantics.dart';
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
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  void _clearSearch() {
    widget.controller.clear();
    ref.read(librarySearchQueryProvider.notifier).state = '';
    // Confirm clear for TalkBack/VoiceOver after leaving the text field.
    announce(context, _copy.librarySearchCleared);
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final copy = _copy;

    return Column(
      key: widget.sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LibrarySectionHeading(title: copy.librarySearchVideos),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AccessibleTextFieldSemantics(
                  controller: widget.controller,
                  semanticsLabel: copy.librarySearchHint,
                  focusNode: widget.focusNode,
                  sortKey: const OrdinalSortKey(1.0),
                  onClear: hasText ? _clearSearch : null,
                  clearActionLabel:
                      hasText ? copy.librarySearchClear : null,
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
                      hintText: copy.librarySearchHint,
                      hintStyle: GoogleFonts.atkinsonHyperlegible(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: context.udaan.onSurfaceMuted,
                      ),
                      // Decorative search icon only when empty — non-interactive.
                      suffixIcon: hasText
                          ? null
                          : ExcludeSemantics(
                              child: Icon(
                                Icons.search,
                                color: context.udaan.primaryGlow,
                              ),
                            ),
                      filled: true,
                      fillColor: context.udaan.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: context.udaan.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            BorderSide(color: context.udaan.outlineVariant),
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
              if (hasText) ...[
                const SizedBox(width: 4),
                // Sibling Clear: Semantics.excludeSemantics (property) so
                // TalkBack/VoiceOver keep onTap; OrdinalSortKey keeps it
                // between the field and results below.
                Semantics(
                  sortKey: const OrdinalSortKey(1.1),
                  button: true,
                  label: copy.librarySearchClear,
                  excludeSemantics: true,
                  onTap: _clearSearch,
                  container: true,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: _clearSearch,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: BrandTokens.a11yMinTapTarget,
                        height: BrandTokens.a11yMinTapTarget,
                        child: Icon(
                          Icons.clear,
                          color: context.udaan.primaryGlow,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
