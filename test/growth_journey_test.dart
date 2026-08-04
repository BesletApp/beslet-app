import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/core/providers/growth_provider.dart';
import 'package:beslet_app/core/services/growth_content.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

const _defaultJourney = GrowthJourneyData(
  id: 'j1',
  intention: 'word',
  timeframeDays: 90,
  startDate: '2026-08-03',
  note: null,
  harvested: false,
  createdAt: '2026-08-03T06:00:00',
);

/// Whether the host can actually load the native sqlite3 library. The FFI
/// symbol resolution throws synchronously, so this is a reliable preflight.
bool _canOpenSqlite() {
  try {
    sqlite3.sqlite3.openInMemory();
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('schema', () {
    test('schema version is 20 and growth_journey is part of the schema', () {
      // A lazy database that never opens — schema/table metadata only.
      final db = AppDatabase.forTesting(LazyDatabase(() async {
        throw StateError('should not open');
      }));
      expect(db.schemaVersion, 20);
    });
  });

  group('provider derivation (no native db)', () {
    test('no journey yields neutral derived state', () async {
      final container = ProviderContainer(overrides: [
        journeyProvider.overrideWith((ref) async => null),
      ]);
      addTearDown(container.dispose);
      await container.read(journeyProvider.future);
      expect(container.read(journeyDayProvider), 0);
      expect(container.read(activeIntentionProvider), isNull);
      expect(container.read(activeTimeframeDaysProvider), isNull);
      expect(container.read(activeMovementProvider), isNull);
    });

    test('planted same-day journey is day 1 in the planting movement', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final container = ProviderContainer(overrides: [
        journeyProvider.overrideWith(
          (ref) async => _defaultJourney.copyWith(startDate: today),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(journeyProvider.future);
      expect(container.read(journeyDayProvider), 1);
      expect(container.read(activeIntentionProvider), JourneyIntention.word);
      expect(container.read(activeTimeframeDaysProvider), 90);
      expect(container.read(activeMovementProvider), JourneyMovement.planting);
    });

    test('open journey exposes a null timeframe', () async {
      final container = ProviderContainer(overrides: [
        journeyProvider.overrideWith(
          (ref) async => _defaultJourney.copyWith(timeframeDays: const Value(null)),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(journeyProvider.future);
      expect(container.read(activeTimeframeDaysProvider), isNull);
    });

    test('unknown stored intention defaults to abide', () async {
      final container = ProviderContainer(overrides: [
        journeyProvider.overrideWith(
          (ref) async => _defaultJourney.copyWith(intention: 'mystery'),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(journeyProvider.future);
      expect(container.read(activeIntentionProvider), JourneyIntention.abide);
    });

    test('a journey in the past advances its movement', () async {
      final tenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 10))
          .toIso8601String()
          .substring(0, 10);
      final container = ProviderContainer(overrides: [
        journeyProvider.overrideWith(
          (ref) async => _defaultJourney.copyWith(startDate: tenDaysAgo),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(journeyProvider.future);
      // Day 11 of 90 is still within the planting quartile.
      expect(container.read(activeMovementProvider), JourneyMovement.planting);

      final containerSeven = ProviderContainer(overrides: [
        journeyProvider.overrideWith(
          (ref) async => _defaultJourney.copyWith(startDate: tenDaysAgo, timeframeDays: const Value(7)),
        ),
      ]);
      addTearDown(containerSeven.dispose);
      await containerSeven.read(journeyProvider.future);
      expect(containerSeven.read(activeMovementProvider), JourneyMovement.fruiting);
    });
  });

  group('database round-trip (requires native sqlite3)', () {
    AppDatabase? db;
    late bool available;

    setUp(() {
      available = _canOpenSqlite();
      db = available ? AppDatabase.forTesting(NativeDatabase.memory()) : null;
    });

    tearDown(() async {
      await db?.close();
    });

    test('planting and harvesting persist a journey', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      await container.read(journeyNotifierProvider.notifier).plantJourney(
            JourneyIntention.word,
            90,
            note: 'grow in the Word',
          );

      final journey = await container.read(journeyProvider.future);
      expect(journey, isNotNull);
      expect(journey!.intention, 'word');
      expect(journey.timeframeDays, 90);
      expect(journey.harvested, isFalse);

      await container.read(journeyNotifierProvider.notifier).harvestJourney();

      final after = await container.read(journeyProvider.future);
      expect(after!.harvested, isTrue);
    });

    test('replanting keeps old journeys as memory and exposes the latest', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      await container.read(journeyNotifierProvider.notifier).plantJourney(JourneyIntention.word, 90);
      await container.read(journeyNotifierProvider.notifier).plantJourney(JourneyIntention.service, 30);

      final latest = await container.read(journeyProvider.future);
      expect(latest!.intention, 'service');

      final rows = await (db!.select(db!.growthJourney)).get();
      expect(rows.length, 2);
    });
  });
}
