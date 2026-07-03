import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/config/app_branding.dart';
import 'package:radio_udaan_app/core/config/app_copy_accessors.dart';
import 'package:radio_udaan_app/core/models/app_user_settings.dart';
import 'package:radio_udaan_app/core/theme/accessibility_scope.dart';
import 'package:radio_udaan_app/core/theme/udaan_colors.dart';
import 'package:radio_udaan_app/features/radio/widgets/radio_volume_control.dart';

void main() {
  final copy = AppCopy.fallback;

  group('RadioVolumeControl.snapToStep', () {
    test('snaps to ten percent steps', () {
      expect(RadioVolumeControl.snapToStep(0.74), 0.7);
      expect(RadioVolumeControl.snapToStep(0.76), 0.8);
      expect(RadioVolumeControl.snapToStep(1.0), 1.0);
      expect(RadioVolumeControl.snapToStep(0.0), 0.0);
    });
  });

  group('volume copy', () {
    test('radioVolumeAnnounce speaks percent', () {
      expect(copy.radioVolumeAnnounce(75), 'Volume, 75 percent');
    });

    test('radioVolumeSliderHint is non-empty', () {
      expect(copy.radioVolumeSliderHint.trim().isNotEmpty, isTrue);
    });
  });

  testWidgets('volume slider is a single adjustable semantics node', (tester) async {
    var volume = 0.5;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AccessibilityScope(
            settings: const AppUserSettings(),
            palette: UdaanPalette.fromBrand(BrandColors.defaults),
            child: StatefulBuilder(
              builder: (context, setState) {
                return RadioVolumeControl(
                  copy: copy,
                  value: volume,
                  onChanged: (v) => setState(() => volume = v),
                );
              },
            ),
          ),
        ),
      ),
    );

    final handle = tester.ensureSemantics();
    final sliderFinder = find.bySemanticsLabel(
      RegExp('^${copy.radioVolume}\$'),
      skipOffstage: false,
    );
    expect(sliderFinder, findsOneWidget);

    final node = tester.getSemantics(sliderFinder);
    expect(node.label, copy.radioVolume);
    expect(node.value, '50 percent');
    expect(node.hint, copy.radioVolumeSliderHint);
    expect(node.increasedValue, '60 percent');
    expect(node.decreasedValue, '40 percent');

    await tester.drag(find.byType(Slider), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(volume, greaterThan(0.5));

    handle.dispose();
  });
}
