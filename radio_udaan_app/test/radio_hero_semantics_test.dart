import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/config/app_branding.dart';
import 'package:radio_udaan_app/core/config/app_copy_accessors.dart';

void main() {
  final copy = AppCopy.fallback;

  group('radioPlayButtonSemantics', () {
    test('includes title and hosts when stopped', () {
      final label = copy.radioPlayButtonSemantics(
        loading: false,
        isPlaying: false,
        showTitle: 'Vocabulary Dose',
        hostsLine: 'with Divya Sharma',
      );
      expect(label, 'Play Live Stream. Vocabulary Dose. with Divya Sharma');
      expect(label, isNot(contains('On air')));
    });

    test('uses stop action when playing', () {
      final label = copy.radioPlayButtonSemantics(
        loading: false,
        isPlaying: true,
        showTitle: 'Vocabulary Dose',
        hostsLine: 'with Divya Sharma',
      );
      expect(label, 'Stop Live Stream. Vocabulary Dose. with Divya Sharma');
    });

    test('connecting when loading', () {
      final label = copy.radioPlayButtonSemantics(
        loading: true,
        isPlaying: false,
        showTitle: 'Vocabulary Dose',
        hostsLine: 'with Divya Sharma',
      );
      expect(label, copy.radioConnecting);
    });
  });

  testWidgets('hero pattern: semantics onTap activates excluded ink well child',
      (tester) async {
    var played = false;
    const label = 'Play Live Stream. Vocabulary Dose. with Divya Sharma';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Semantics(
            button: true,
            label: label,
            onTap: () => played = true,
            child: ExcludeSemantics(
              child: Material(
                child: InkWell(
                  onTap: () => played = true,
                  child: const SizedBox(
                    width: 320,
                    height: 400,
                    child: Center(child: Text('Hero')),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(label), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(label));
    expect(played, isTrue);

    played = false;
    await tester.tap(find.text('Hero'));
    expect(played, isTrue);

    handle.dispose();
  });
}
