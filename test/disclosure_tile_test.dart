import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beslet_app/features/growth/widgets/disclosure_tile.dart';
import 'package:beslet_app/l10n/app_localizations.dart';

void main() {
  Widget wrap({bool initiallyOpen = false}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: DisclosureTile(
            icon: Icons.auto_awesome,
            title: 'Rhythm',
            trailing: const Text('1/5'),
            initiallyOpen: initiallyOpen,
            children: const [Text('the ring')],
          ),
        ),
      );

  AnimatedCrossFade fade(WidgetTester tester) =>
      tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade));

  testWidgets('rests collapsed by default', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 300));
    expect(fade(tester).crossFadeState, CrossFadeState.showFirst);
  });

  testWidgets('opens on tap', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Rhythm'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fade(tester).crossFadeState, CrossFadeState.showSecond);
  });

  testWidgets('initiallyOpen reveals its children on first paint', (tester) async {
    await tester.pumpWidget(wrap(initiallyOpen: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(fade(tester).crossFadeState, CrossFadeState.showSecond);
    expect(find.text('the ring'), findsOneWidget);
  });
}
