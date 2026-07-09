import 'package:flutter/material.dart';

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
class AccessibleTextFieldSemantics extends StatefulWidget {
  const AccessibleTextFieldSemantics({
    required this.controller,
    required this.semanticsLabel,
    required this.child,
    this.hint,
    this.obscured = false,
    this.readOnly = false,
    super.key,
  });

  final TextEditingController controller;
  final String semanticsLabel;
  final Widget child;
  final String? hint;
  final bool obscured;
  final bool readOnly;

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
  }

  @override
  void didUpdateWidget(AccessibleTextFieldSemantics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_repaint);
      widget.controller.addListener(_repaint);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_repaint);
    super.dispose();
  }

  void _repaint() {
    if (mounted) setState(() {});
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
