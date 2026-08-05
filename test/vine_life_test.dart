import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/core/providers/vine_life_provider.dart';
import 'package:beslet_app/core/services/scene_event_bus.dart';

bool _canOpenSqlite() {
  try {
    sqlite3.sqlite3.openInMemory();
    return true;
  } catch (_) {
    return false;
  }
}

VineDayData _day(
  String date, {
  DateTime? prayer,
  DateTime? reading,
  DateTime? fellowship,
  DateTime? visit,
  int moments = 0,
}) {
  return VineDayData(
    date: date,
    prayerAt: prayer?.toIso8601String(),
    readingAt: reading?.toIso8601String(),
    fellowshipAt: fellowship?.toIso8601String(),
    lastVisitAt: visit?.toIso8601String(),
    momentsPlayed: moments,
  );
}

void main() {
  final now = DateTime(2026, 8, 5, 12);
  final d = DateTime.now();
  final todayKey =
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  group('VineLifeState.compute — continuous decay', () {

    test('a fresh prayer holds the vine at full water', () {
      final s = VineLifeState.compute(
        rows: [_day('2026-08-05', prayer: now)],
        now: now,
        todayReadingMinutes: 0,
        todayHabitsDone: 0,
      );
      expect(s.water, closeTo(1.0, 0.001));
    });

    test('water fades across a missed day but never snaps to zero', () {
      final s = VineLifeState.compute(
        rows: [_day('2026-08-03', prayer: DateTime(2026, 8, 3, 12))],
        now: now,
        todayReadingMinutes: 0,
        todayHabitsDone: 0,
      );
      // Two full days after watering: gentle half-life decay (~19% left at 20h
      // half-life, 48h elapsed).
      expect(s.water, lessThan(1.0));
      expect(s.water, greaterThan(0.0));
      expect(s.water, closeTo(0.19, 0.05));
    });

    test('the Word lights leaves from both freshness and today\'s minutes', () {
      final fresh = VineLifeState.compute(
        rows: [_day('2026-08-05', reading: now)],
        now: now,
        todayReadingMinutes: 0,
        todayHabitsDone: 0,
      );
      final banked = VineLifeState.compute(
        rows: [_day('2026-08-05', reading: now)],
        now: now,
        todayReadingMinutes: 20,
        todayHabitsDone: 0,
      );
      expect(fresh.light, greaterThan(0.6));
      expect(banked.light, greaterThan(fresh.light));
      expect(banked.light, lessThanOrEqualTo(1.0));
    });

    test('a quiet day rests at zero, never negative', () {
      final s = VineLifeState.compute(
        rows: const [],
        now: now,
        todayReadingMinutes: 0,
        todayHabitsDone: 0,
      );
      expect(s.water, 0.0);
      expect(s.light, 0.0);
      expect(s.warmth, 0.0);
      expect(s.diligence, 0.0);
      expect(s.daysMissed, 0);
    });

    test('absence is remembered as days since the last visit', () {
      final s = VineLifeState.compute(
        rows: [_day('2026-08-02', visit: DateTime(2026, 8, 2, 9))],
        now: now,
        todayReadingMinutes: 0,
        todayHabitsDone: 0,
      );
      expect(s.daysMissed, 3);
      expect(s.hoursAway, greaterThan(72));
    });

    test('the latest event across days wins for each reservoir', () {
      final s = VineLifeState.compute(
        rows: [
          _day('2026-08-04', prayer: DateTime(2026, 8, 4, 20)),
          _day('2026-08-05', prayer: now),
        ],
        now: now,
        todayReadingMinutes: 0,
        todayHabitsDone: 0,
      );
      expect(s.water, closeTo(1.0, 0.001));
    });

    test('diligence reflects today\'s habits and fades by day\'s end', () {
      final morning = VineLifeState.compute(
        rows: const [],
        now: DateTime(2026, 8, 5, 8),
        todayReadingMinutes: 0,
        todayHabitsDone: 4,
      );
      final night = VineLifeState.compute(
        rows: const [],
        now: DateTime(2026, 8, 5, 23),
        todayReadingMinutes: 0,
        todayHabitsDone: 4,
      );
      expect(morning.diligence, closeTo(0.81, 0.02));
      expect(night.diligence, lessThan(morning.diligence));
      expect(night.diligence, greaterThan(0.3));
    });
  });

  group('vine life round-trip (requires native sqlite3)', () {
    AppDatabase? db;
    late bool available;

    setUp(() {
      available = _canOpenSqlite();
      db = available ? AppDatabase.forTesting(NativeDatabase.memory()) : null;
    });

    tearDown(() async {
      await db?.close();
    });

    test('events persist timestamps and vineLifeProvider reads them', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      final bus = SceneEventBus();
      bus.onPersist = container.read(vineLifeWriterProvider).recordEvent;

      bus.emit(SceneEventType.water);
      bus.emit(SceneEventType.leafLight);
      bus.emit(SceneEventType.branchGrow);

      final state = await container.read(vineLifeProvider.future);
      expect(state.water, closeTo(1.0, 0.001));
      expect(state.light, greaterThan(0.6));
      expect(state.warmth, closeTo(1.0, 0.001));

      final row =
          (await (db!.select(db!.vineDay)..where((t) => t.date.equals(todayKey))).getSingleOrNull())!;
      expect(row.prayerAt, isA<String>());
      expect(row.readingAt, isA<String>());
      expect(row.fellowshipAt, isA<String>());
    });

    test('touchLastVisit stamps presence and drives daysMissed', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      await container.read(vineLifeWriterProvider).touchLastVisit(at: DateTime(2026, 8, 5, 12));
      final fresh = await container.read(vineLifeProvider.future);
      expect(fresh.daysMissed, 0);

      await container.read(vineLifeWriterProvider).touchLastVisit(at: DateTime(2026, 8, 2, 9));
      final away = await container.read(vineLifeProvider.future);
      expect(away.daysMissed, greaterThan(0));
    });

    test('recordMoment counts transcendence moments for the day', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      final writer = container.read(vineLifeWriterProvider);
      await writer.recordMoment();
      await writer.recordMoment();

      final row =
          (await (db!.select(db!.vineDay)..where((t) => t.date.equals(todayKey))).getSingleOrNull())!;
      expect(row.momentsPlayed, 2);
    });
  });
}

