import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/features/spiritual/prayer_focus_screen.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

bool _canOpenSqlite() {
  try {
    sqlite3.sqlite3.openInMemory();
    return true;
  } catch (_) {
    return false;
  }
}

const _room = PrayerRoom(
  id: 'room-1',
  name: 'Quiet',
  group: 'personal',
  sortOrder: 0,
  createdAt: '2026-01-01T00:00:00',
  lastEnteredAt: null,
);

void main() {
  testWidgets('inner room: presence mode begins, steps away, returns, rests',
      (tester) async {
    if (!_canOpenSqlite()) {
      return markTestSkipped('sqlite3 native library unavailable on this host');
    }
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PrayerFocusScreen(room: _room),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l = AppLocalizations.of(
        tester.element(find.byType(PrayerFocusScreen)))!;

    // Idle: the room holds a still, un-numbered presence.
    expect(find.text(_room.name), findsOneWidget);
    expect(find.text(l.justBeStill), findsOneWidget);
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