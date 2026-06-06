import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BesletApp());
    expect(find.text('ብስለት'), findsNothing);
  });
}
