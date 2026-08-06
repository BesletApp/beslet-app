import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/daily_flow_provider.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/core/providers/growth_streams_provider.dart';
import 'package:beslet_app/core/providers/tracking_provider.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:beslet_app/core/services/xp_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

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

  group('spiritual flow (requires native sqlite3)', () {
    AppDatabase? db;
    late bool available;

    setUp(() {
      available = _canOpenSqlite();
      db = available ? AppDatabase.forTesting(NativeDatabase.memory()) : null;
    });

    tearDown(() async {
      await db?.close();
    });

    test('markCompleted records a completed reading for today and grants XP', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      expect(await container.read(todayReadingProvider.future), isNull);
      var tracking = await container.read(trackingDataProvider.future);
      expect(tracking.bibleDone, isFalse);
      expect(tracking.pillarsDone, 0);
      final xpBefore = tracking.totalXp;

      await container.read(readingNotifierProvider.notifier).markCompleted(bookId: 'john', chapter: 3);

      final rows = await db!.select(db!.readingSessions).get();
      expect(rows.length, 1);
      expect(rows.first.completed, isTrue);
      expect(rows.first.completedAt, isNotNull);
      expect(rows.first.bookId, 'john');
      expect(rows.first.chapter, 3);

      tracking = await container.read(trackingDataProvider.future);
      expect(tracking.bibleDone, isTrue);
      expect(tracking.pillarsDone, 1);
      expect(tracking.totalXp, xpBefore + XpService.readingComplete);
    });

    test('markCompleted is idempotent — XP is awarded only once per day', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(readingNotifierProvider.notifier);
      await notifier.markCompleted(bookId: 'psalms', chapter: 23);
      await notifier.markCompleted(bookId: 'psalms', chapter: 23);

      final rows = await db!.select(db!.readingSessions).get();
      expect(rows.length, 1);
      final tracking = await container.read(trackingDataProvider.future);
      expect(tracking.totalXp, XpService.readingComplete);
    });

    test('logReading keeps the chapter while accumulating minutes', () async {
      if (!available) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(readingNotifierProvider.notifier);
      await notifier.logReading(bookId: 'john', chapter: 1);
      await notifier.logReading(bookId: 'john', chapter: 1);
      await notifier.logReading(bookId: 'mark', chapter: 2);

      final rows = await db!.select(db!.readingSessions).get();
      expect(rows.length, 1);
      expect(rows.first.minutes, 3);
      expect(rows.first.bookId, 'mark');
      expect(rows.first.chapter, 2);
      expect(rows.first.completed, isFalse);
    });
  });

  group('DailyFlow derivation', () {
    Future<DailyFlow> flowFor({bool bible = false, bool prayer = false, bool act = false}) async {
      final container = ProviderContainer(overrides: [
        trackingDataProvider.overrideWith(
          (ref) async => TrackingData(
            totalXp: 0,
            level: 0,
            levelName: 'Seed',
            streak: 0,
            bestStreak: 0,
            freezeTokens: 0,
            streakAtRisk: false,
            prayerMinutes: 0,
            habitsDone: 0,
            skillsMinutes: 0,
            todosDone: 0,
            todosTotal: 0,
            badges: const [],
            levelProgress: 0,
            bibleDone: bible,
            prayerDone: prayer,
            actionDone: act,
            pillarsDone: [bible, prayer, act].where((b) => b).length,
          ),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(trackingDataProvider.future);
      return container.read(dailyFlowProvider);
    }

    test('steps unlock in order: Bible -> Prayer -> Act', () async {
      expect((await flowFor()).currentStep, 0);
      expect((await flowFor(bible: true)).currentStep, 1);
      expect((await flowFor(bible: true, prayer: true)).currentStep, 2);
      final all = await flowFor(bible: true, prayer: true, act: true);
      expect(all.currentStep, 3);
      expect(all.done, 3);
      expect(all.total, 3);
    });

    test('a single faithful act counts toward the flow', () async {
      final flow = await flowFor(act: true);
      expect(flow.actionDone, isTrue);
      expect(flow.done, 1);
      expect(flow.currentStep, 0);
    });
  });

  group('NT plan', () {
    test('ntPlanFor yields a real book and chapter within the NT range', () {
      final plan = ScriptureService.ntPlanFor(DateTime(2026, 8, 5));
      expect(plan, isNotNull);
      expect(ScriptureService.bookMap[plan!.bookId], isNotNull);
      expect(plan.chapter, greaterThanOrEqualTo(1));
      expect(plan.chapter, lessThanOrEqualTo(plan.book.chapters));
    });

    test('ntPlanFor is deterministic and advances by one chapter daily', () {
      final a = ScriptureService.ntPlanFor(DateTime(2026, 8, 5))!;
      final b = ScriptureService.ntPlanFor(DateTime(2026, 8, 6))!;
      final c = ScriptureService.ntPlanFor(DateTime(2026, 8, 5))!;
      expect(a.bookId, c.bookId);
      expect(a.chapter, c.chapter);
      if (a.bookId == b.bookId) {
        expect(b.chapter, a.chapter + 1);
      } else {
        final aIdx = ScriptureService.ntBooks.indexWhere((x) => x.id == a.bookId);
        final bIdx = ScriptureService.ntBooks.indexWhere((x) => x.id == b.bookId);
        expect(bIdx, aIdx + 1);
        expect(b.chapter, 1);
      }
    });
  });
}
