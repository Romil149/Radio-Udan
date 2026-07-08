import 'package:flutter/material.dart';

import '../theme/brand_tokens.dart';
import '../theme/udaan_colors.dart';
import '../theme/udaan_text_styles.dart';

/// Floating "Done" / "Next" bar shown above numeric soft keyboards.
///
/// Android and iOS numeric keypads (phone, number, OTP) do not render an
/// action button, so blind and low-vision users have no explicit control to
/// advance or dismiss the keyboard. This overlay adds one, labelled for
/// TalkBack / VoiceOver, pinned directly above the keyboard.
///
/// Wrap the widget that owns [focusNode]'s `TextField`; the bar appears while
/// that field holds focus and disappears when it loses focus.
class KeyboardAccessory extends StatefulWidget {
  const KeyboardAccessory({
    required this.focusNode,
    required this.child,
    required this.doneLabel,
    this.nextLabel,
    this.onNext,
    super.key,
  });

  final FocusNode focusNode;
  final Widget child;
  final String doneLabel;

  /// When both [nextLabel] and [onNext] are set, a "Next" control is shown.
  final String? nextLabel;
  final VoidCallback? onNext;

  @override
  State<KeyboardAccessory> createState() => _KeyboardAccessoryState();
}

class _KeyboardAccessoryState extends State<KeyboardAccessory> {
  OverlayEntry? _entry;
  UdaanPalette? _palette;
  TextStyle? _labelStyle;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant KeyboardAccessory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChange);
      widget.focusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    _removeEntry();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    if (widget.focusNode.hasFocus) {
      _insertEntry();
    } else {
      _removeEntry();
    }
  }

  void _insertEntry() {
    if (_entry != null) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    _entry = OverlayEntry(builder: _buildBar);
    overlay.insert(_entry!);
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  Widget _buildBar(BuildContext overlayContext) {
    final palette = _palette;
    final labelStyle = _labelStyle;
    if (palette == null || labelStyle == null) return const SizedBox.shrink();

    final keyboardInset = MediaQuery.of(overlayContext).viewInsets.bottom;
    // No soft keyboard on screen (hardware keyboard / desktop): hide the bar.
    if (keyboardInset <= 0) return const SizedBox.shrink();

    final showNext = widget.onNext != null && widget.nextLabel != null;

    return Positioned(
      left: 0,
      right: 0,
      bottom: keyboardInset,
      // TextFieldTapRegion keeps taps on the bar from triggering any field's
      // onTapOutside (which would dismiss the keyboard before the tap lands).
      child: TextFieldTapRegion(
        child: Material(
          color: palette.surfaceContainer,
          elevation: 8,
          child: Container(
            constraints: const BoxConstraints(
              minHeight: BrandTokens.a11yMinTapTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: palette.outlineVariant)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showNext)
                  _barButton(
                    palette: palette,
                    labelStyle: labelStyle,
                    label: widget.nextLabel!,
                    icon: Icons.arrow_downward,
                    onTap: widget.onNext!,
                  ),
                _barButton(
                  palette: palette,
                  labelStyle: labelStyle,
                  label: widget.doneLabel,
                  icon: Icons.keyboard_hide,
                  emphasized: true,
                  onTap: () => widget.focusNode.unfocus(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _barButton({
    required UdaanPalette palette,
    required TextStyle labelStyle,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    final color = emphasized ? palette.primary : palette.onBackground;
    return Semantics(
      button: true,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: BrandTokens.a11yMinTapTarget,
              minHeight: BrandTokens.a11yMinTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: labelStyle.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Capture theme values under AccessibilityScope so the overlay (built in
    // the root Overlay's context) styles itself consistently.
    _palette = context.udaan;
    _labelStyle = udaanTextStyle(context, fontSize: 16);
    _entry?.markNeedsBuild();
    return widget.child;
  }
}
