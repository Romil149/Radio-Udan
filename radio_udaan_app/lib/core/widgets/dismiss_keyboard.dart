import 'package:flutter/material.dart';

import '../utils/keyboard_dismiss.dart';

/// Tapping outside a focused field dismisses the software keyboard.
class DismissKeyboard extends StatelessWidget {
  const DismissKeyboard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => dismissKeyboard(context),
      child: child,
    );
  }
}
