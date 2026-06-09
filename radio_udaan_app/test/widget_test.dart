import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:radio_udaan_app/app.dart';

void main() {
  testWidgets('shows bootstrap loading', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: RadioUdaanApp()),
    );
    expect(find.text('Loading Radio Udaan'), findsOneWidget);
  });
}
