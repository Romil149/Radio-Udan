import 'package:flutter/material.dart';

/// Removes focus from the active text field so the software keyboard closes.
void dismissKeyboard([BuildContext? context]) {
  final scope = context != null ? FocusScope.of(context) : null;
  if (scope != null && !scope.hasPrimaryFocus && scope.focusedChild != null) {
    scope.unfocus();
    return;
  }
  FocusManager.instance.primaryFocus?.unfocus();
}
