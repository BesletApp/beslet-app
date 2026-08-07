import 'package:beslet_app/core/providers/daily_flow_provider.dart';
import 'package:beslet_app/core/providers/scripture_provider.dart';
import 'package:beslet_app/features/spiritual/prayer_modes.dart';
import 'package:beslet_app/features/spiritual/widgets/prayer_guide_card.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prayer modes', () {
    test('the four postures are repent, thanks, ask, rest', () {
      expect(prayerModes.map((m) => m.id), ['repent', 'thanks', 'ask', 'rest']);
    });

    test('the daily verse rotates through each mode', () {
      for (final mode in prayerModes) {
        final day0 = verseForMode(mode, DateTime(2025, 1, 1));
        final day1 = verseForMode(mode, DateTime(2025, 1, 2));
        expect(day0.reference, isNot(day1.reference),
            reason: '${mode.id} rotates day to day');
        expect(mode.verses.map((v) => v.reference).toSet().length,
            mode.verses.length,
            reason: 'every verse in ${mode.id} is distinct');
      }
    });

    test('every mode verse carries English and Amharic text', () {
      for (final mode in prayerModes) {
        for (final v in mode.verses) {
          expect(v.text, isNotEmpty, reason: '${v.reference} English text');
          expect(v.textAm, isNotEmpty, reason: '${v.reference} Amharic text');
        }
      }
    });
  });

  group('PrayerGuideCard', () {
    const flow = DailyFlow(
      bibleDone: false,
      prayerDone: false,
      actionDone: false,
      done: 0,
      total: 3,
      currentStep: 0,
    );
    const plan = TodayReadingPlan(
      bookId: 'mat',
      chapter: 1,
      labelEn: 'Matthew 1',
      labelAm: 'ማቴዎስ 1',
    );

    Future<void> pumpGuide(WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyFlowProvider.overrideWithValue(flow),
            todayBiblePlanProvider.overrideWithValue(plan),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: PrayerGuideCard(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('opens as a guide: postures, guides and the day\'s reading',
        (tester) async {
      await pumpGuide(tester);
      final l = AppLocalizations.of(
          tester.element(find.byType(PrayerGuideCard)))!;

      expect(find.text(l.waysToPray), findsOneWidget);
      expect(find.text('${l.prayWhatYouRead} — Matthew 1'), findsOneWidget);
      expect(find.text('✨ ${l.beginWithWord}'), findsOneWidget);

      // Collapsed postures already show their quiet one-line guide.
      for (final mode in prayerModes) {
        expect(find.text(modeLabel(l, mode)), findsOneWidget);
        expect(find.text(modeGuide(l, mode)), findsOneWidget);
      }
      expect(find.text(l.prayerWords), findsOneWidget);
    });

    testWidgets('expanding a posture reveals today\'s rotating verse',
        (tester) async {
      await pumpGuide(tester);
      final l = AppLocalizations.of(
          tester.element(find.byType(PrayerGuideCard)))!;

      final mode = prayerModes.first; // Repent
      final verse = verseForMode(mode, DateTime.now());
      expect(find.text(verse.text), findsNothing,
          reason: 'the verse stays hidden until the posture opens');

      await tester.tap(find.text(modeLabel(l, mode)));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(verse.text), findsOneWidget);
      expect(find.text(verse.reference), findsOneWidget);
    });

    testWidgets('expanding prayer words shows the words Jesus gave',
        (tester) async {
      await pumpGuide(tester);
      final l = AppLocalizations.of(
          tester.element(find.byType(PrayerGuideCard)))!;

      expect(find.text(l.lordsPrayer), findsNothing);
      await tester.tap(find.text(l.prayerWords));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(l.lordsPrayer), findsOneWidget);
      expect(find.text(l.lordHaveMercy), findsOneWidget);
    });
  });
}
