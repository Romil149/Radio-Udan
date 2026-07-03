import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/accessibility/udaan_semantics.dart';

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
}
