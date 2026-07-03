import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/core/config/app_branding.dart';
import 'package:radio_udaan_app/core/config/app_copy_accessors.dart';
import 'package:radio_udaan_app/core/models/event_summary.dart';
import 'package:radio_udaan_app/features/events/widgets/event_card.dart';

void main() {
  final copy = AppCopy.fallback;

  testWidgets('event card exposes single Register For semantics', (tester) async {
    var tapped = false;
    const title = 'Become an RJ';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventCard(
            copy: copy,
            event: const EventSummary(
              eventId: 1,
              title: title,
              status: 'open',
            ),
            bannerUrl: '',
            onRegister: () => tapped = true,
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(EventCard));
    final node = semantics.getSemanticsData();
    expect(node.label, 'Register For $title');
    expect(node.hasFlag(SemanticsFlag.isButton), isTrue);

    await tester.tap(find.byType(EventCard));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('closed registration card is not a button', (tester) async {
    const title = 'Past Workshop';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EventCard(
            copy: copy,
            event: const EventSummary(
              eventId: 2,
              title: title,
              status: 'closed',
            ),
            bannerUrl: '',
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(EventCard));
    final node = semantics.getSemanticsData();
    expect(node.label, 'Registration closed for $title');
    expect(node.hasFlag(SemanticsFlag.isButton), isFalse);
  });
}
