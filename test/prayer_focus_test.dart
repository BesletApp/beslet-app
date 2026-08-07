import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/features/spiritual/prayer_focus_screen.dart';
import 'package:beslet_app/features/spiritual/prayer_modes.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

bool _canOpenSqlite() {
  try {
    sqlite3.sqlite3.openInMemory();
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> _pumpFocus(WidgetTester tester, AppDatabase db, PrayerMode mode) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PrayerFocusScreen(mode: mode),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('prayer modes', () {
    test('the three postures are thanks, ask, rest', () {
      expect(prayerModes.map((m) => m.id), ['thanks', 'ask', 'rest']);
    });

    test('the daily verse rotates through each mode', () {
      final mode = prayerModes.first;
      final day0 = verseForMode(mode, DateTime(2025, 1, 1));
      final day1 = verseForMode(mode, DateTime(2025, 1, 2));
      expect(day0.reference, isNot(day1.reference));
      expect(mode.verses.map((v) => v.reference).toSet().length, mode.verses.length,
          reason: 'every verse in a mode is distinct');
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

  testWidgets('inner room: mode name, today\'s verse and topics are carried in',
      (tester) async {
    if (!_canOpenSqlite()) {
      return markTestSkipped('sqlite3 native library unavailable on this host');
    }
    SharedPreferences.setMockInitialValues({
      'prayer_topics': 'For my family\nFor my work',
    });
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final mode = prayerModes.first; // Thanks
    await _pumpFocus(tester, db, mode);

    final l = AppLocalizations.of(
        tester.element(find.byType(PrayerFocusScreen)))!;
    final verse = verseForMode(mode, DateTime.now());

    // Idle: a still, un-numbered presence.
    expect(find.text(l.modeThanks), findsOneWidget);
    expect(find.text(l.justBeStill), findsOneWidget);
    expect(find.text(verse.text), findsOneWidget);
    expect(find.text(verse.reference), findsOneWidget);
    expect(find.text('For my family\nFor my work'), findsOneWidget,
        reason: 'the topics written on the Prayer page are remembered here');
    expect(find.widgetWithText(ElevatedButton, l.beginPresence), findsOneWidget);

    // Begin starts presence.
    await tester.tap(find.widgetWithText(ElevatedButton, l.beginPresence));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.widgetWithText(ElevatedButton, l.stepAway), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, l.restNow), findsOneWidget);

    // Step away pauses; Return appears.
    await tester.tap(find.widgetWithText(ElevatedButton, l.stepAway));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.widgetWithText(ElevatedButton, l.returnHere), findsOneWidget);

    // Return resumes.
    await tester.tap(find.widgetWithText(ElevatedButton, l.returnHere));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.widgetWithText(ElevatedButton, l.stepAway), findsOneWidget);

    // Rest closes the room and records the felt time.
    await tester.tap(find.widgetWithText(OutlinedButton, l.restNow));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PrayerFocusScreen), findsNothing);

    final todays = await (db.select(db.prayerLogs)
          ..where((t) => t.date.equals(
              DateTime.now().toIso8601String().substring(0, 10))))
        .get();
    expect(todays, isNotEmpty, reason: 'resting logs a gentle record');
    expect(todays.first.minutes, greaterThan(0));
  });
}
