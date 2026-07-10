import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibility/udaan_semantics.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/accessibility_scope.dart';
import '../../../core/theme/brand_tokens.dart';
import '../../../core/theme/udaan_text_styles.dart';
import '../models/form_schema.dart';

/// Strip trailing asterisks Forminator adds — we show one required marker in the app.
String registrationFieldDisplayLabel(String rawLabel) {
  return rawLabel.replaceAll(RegExp(r'\s*\*+\s*$'), '').trim();
}

/// Persistent label above a field (single asterisk when required).
String registrationFieldLabelText(FormFieldSchema field) {
  final base = registrationFieldDisplayLabel(field.label);
  if (base.isEmpty) return field.required ? '*' : '';
  return field.required ? '$base *' : base;
}

/// Udaan-styled input decoration for event registration (label is outside).
InputDecoration registrationFieldDecoration(
  BuildContext context, {
  String? hint,
  String? errorText,
  Widget? suffixIcon,
}) {
  final palette = context.udaan;
  return InputDecoration(
    hintText: hint,
    hintStyle: udaanTextStyle(context, fontSize: 18, color: palette.hint),
    errorText: errorText,
    errorStyle: udaanTextStyle(context, fontSize: 14, color: palette.error),
    filled: true,
    fillColor: palette.surfaceContainer,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    suffixIcon: suffixIcon,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.primaryGlow),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.primaryGlow, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.error, width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: palette.error, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: palette.primaryGlow.withValues(alpha: 0.6),
      ),
    ),
  );
}

TextStyle registrationFieldLabelStyle(
  BuildContext context, {
  bool required = false,
}) {
  final palette = context.udaan;
  return udaanTextStyle(
    context,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: required ? palette.primaryGlow : palette.onBackground,
  );
}

TextStyle registrationFieldInputStyle(
  BuildContext context, {
  bool readOnly = false,
}) {
  final palette = context.udaan;
  return udaanTextStyle(
    context,
    fontSize: 18,
    color: readOnly
        ? palette.onBackground.withValues(alpha: 0.72)
        : palette.onBackground,
  );
}

TextStyle registrationChoiceOptionStyle(BuildContext context) {
  return udaanTextStyle(
    context,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );
}

/// Radio or checkbox row — 56px min height, Udaan colors.
///
/// Spoken label includes checked/selected state because custom [Semantics.onTap]
/// often fails to announce state changes on TalkBack (Flutter #155298).
Widget registrationChoiceTile({
  required BuildContext context,
  required String label,
  required bool selected,
  required VoidCallback onTap,
  required bool isRadio,
  String? groupLabel,
}) {
  final palette = context.udaan;
  final copy = ProviderScope.containerOf(context).read(appCopyProvider);
  final stateWord = isRadio
      ? (selected ? copy.a11ySelected : copy.a11yNotSelected)
      : (selected ? copy.a11yChecked : copy.a11yNotChecked);
  final base = groupLabel != null ? '$groupLabel, $label' : label;
  final semanticsLabel = '$base, $stateWord';

  void handleActivate() {
    onTap();
    final newStateWord = isRadio
        ? copy.a11ySelected
        : (!selected ? copy.a11yChecked : copy.a11yNotChecked);
    announce(context, '$label, $newStateWord');
  }

  return Semantics(
    checked: selected,
    inMutuallyExclusiveGroup: isRadio,
    label: semanticsLabel,
    onTap: handleActivate,
    child: ExcludeSemantics(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: handleActivate,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: BrandTokens.a11yMinTapTarget,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isRadio
                        ? (selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off)
                        : (selected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank),
                    color: palette.primaryGlow,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: registrationChoiceOptionStyle(context),
                      softWrap: true,
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
