import 'package:flutter/material.dart';
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

    return Column(
      key: widget.sectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LibrarySectionHeading(title: _copy.librarySearchVideos),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BrandTokens.screenPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: AccessibleTextFieldSemantics(
                  controller: widget.controller,
                  semanticsLabel: _copy.librarySearchHint,
                  focusNode: widget.focusNode,
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
                // Outside the text-field ExcludeSemantics so SR can find it;
                // UdaanAccessibleButton supplies onTap (label-only Semantics
                // is often skipped / not activatable by TalkBack/VoiceOver).
                UdaanAccessibleButton(
                  label: _copy.librarySearchClear,
                  onPressed: _clearSearch,
                  child: SizedBox(
                    width: BrandTokens.a11yMinTapTarget,
                    height: BrandTokens.a11yMinTapTarget,
                    child: IconButton(
                      onPressed: _clearSearch,
                      tooltip: _copy.librarySearchClear,
                      constraints: const BoxConstraints(
                        minWidth: BrandTokens.a11yMinTapTarget,
                        minHeight: BrandTokens.a11yMinTapTarget,
                      ),
                      icon: Icon(
                        Icons.clear,
                        color: context.udaan.primaryGlow,
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
