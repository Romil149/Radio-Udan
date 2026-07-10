import 'package:flutter/material.dart';

import '../config/app_copy_defaults.dart';
import 'udaan_semantics.dart';

/// Spoken [Semantics.value] for a text field — null when empty or obscured.
String? accessibilitySpokenFieldValue(
  String text, {
  bool obscured = false,
}) {
  if (obscured) return null;
  final trimmed = text.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Keeps TalkBack / VoiceOver [Semantics.value] in sync with a [TextEditingController].
///
/// Use when the inner [TextField] is wrapped in [ExcludeSemantics] so refocus
/// announces both the field label and the current contents.
///
/// Pass [focusNode] so [Semantics.focused] stays accurate and focus gain
/// announces "Editing {label}" (L6 GLOBAL).
///
/// When [isPassword] is true and [obscured] flips, announces "Password shown"
/// / "Password hidden" (state only — never the password string). While
/// obscured, [Semantics.value] stays null so contents are never spoken.
class AccessibleTextFieldSemantics extends StatefulWidget {
  const AccessibleTextFieldSemantics({
    required this.controller,
    required this.semanticsLabel,
    required this.child,
    this.hint,
    this.obscured = false,
    this.isPassword = false,
    this.passwordShownAnnounce,
    this.passwordHiddenAnnounce,
    this.readOnly = false,
    this.focusNode,
    super.key,
  });

  final TextEditingController controller;
  final String semanticsLabel;
  final Widget child;
  final String? hint;
  final bool obscured;

  /// When true, obscure toggles announce shown/hidden state (not the value).
  final bool isPassword;

  /// Override for [password_shown_announce]; defaults from [appCopyDefaults].
  final String? passwordShownAnnounce;

  /// Override for [password_hidden_announce]; defaults from [appCopyDefaults].
  final String? passwordHiddenAnnounce;
  final bool readOnly;
  final FocusNode? focusNode;

  @override
  State<AccessibleTextFieldSemantics> createState() =>
      _AccessibleTextFieldSemanticsState();
}

class _AccessibleTextFieldSemanticsState
    extends State<AccessibleTextFieldSemantics> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_repaint);
    widget.focusNode?.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(AccessibleTextFieldSemantics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_repaint);
      widget.controller.addListener(_repaint);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      widget.focusNode?.addListener(_onFocusChanged);
    }
    if (widget.isPassword && oldWidget.obscured != widget.obscured) {
      _announcePasswordVisibility();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_repaint);
    widget.focusNode?.removeListener(_onFocusChanged);
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
  }

  void _announcePasswordVisibility() {
    // State only — never speak the password string here. Value is available
    // on the next focus/swipe when not obscured.
    final message = widget.obscured
        ? (widget.passwordHiddenAnnounce ??
            appCopyDefaults['password_hidden_announce']!)
        : (widget.passwordShownAnnounce ??
            appCopyDefaults['password_shown_announce']!);
    announce(context, message);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() {});
    final node = widget.focusNode;
    if (node != null && node.hasFocus) {
      announce(context, 'Editing ${widget.semanticsLabel}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: widget.semanticsLabel,
      hint: widget.hint,
      value: accessibilitySpokenFieldValue(
        widget.controller.text,
        obscured: widget.obscured,
      ),
      obscured: widget.obscured,
      readOnly: widget.readOnly,
      focused: widget.focusNode?.hasFocus ?? false,
      child: ExcludeSemantics(child: widget.child),
    );
  }
}

/// Static-value variant for [TextFormField.initialValue] subfields.
class AccessibleStaticFieldSemantics extends StatelessWidget {
  const AccessibleStaticFieldSemantics({
    required this.semanticsLabel,
    required this.value,
    required this.child,
    this.hint,
    this.readOnly = false,
    super.key,
  });

  final String semanticsLabel;
  final String? value;
  final Widget child;
  final String? hint;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticsLabel,
      hint: hint,
      value: accessibilitySpokenFieldValue(value ?? ''),
      readOnly: readOnly,
      child: ExcludeSemantics(child: child),
    );
  }
}
