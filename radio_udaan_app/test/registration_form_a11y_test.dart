import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/accessibility/udaan_semantics.dart';
import 'package:radio_udaan_app/core/config/app_branding.dart';
import 'package:radio_udaan_app/core/models/app_user_settings.dart';
import 'package:radio_udaan_app/core/theme/accessibility_scope.dart';
import 'package:radio_udaan_app/core/theme/udaan_colors.dart';
import 'package:radio_udaan_app/features/events/widgets/registration_form_styles.dart';

void main() {
  testWidgets('UdaanAccessibleButton is one VoiceOver-activatable button', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UdaanAccessibleButton(
            label: 'Choose file for UDID card, required',
            onPressed: () => tapped = true,
            child: FilledButton(
              onPressed: () => tapped = true,
              child: const Text('Choose file'),
            ),
          ),
        ),
      ),
    );

    final node =
        tester.getSemantics(find.byType(UdaanAccessibleButton)).getSemanticsData();
    expect(node.label, 'Choose file for UDID card, required');
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);

    await tester.tap(find.byType(UdaanAccessibleButton));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('registrationChoiceTile is one TalkBack focus stop per option', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccessibilityScope(
          settings: const AppUserSettings(),
          palette: UdaanPalette.fromBrand(BrandColors.defaults),
          child: Builder(
            builder: (context) => Scaffold(
              body: registrationChoiceTile(
                context: context,
                label: 'Male',
                selected: false,
                isRadio: true,
                groupLabel: 'Gender, required',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.bySemanticsLabel('Gender, required, Male'),
      findsOneWidget,
    );
  });
}
