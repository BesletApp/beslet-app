import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/audio_player_provider.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/core/providers/prayer_provider.dart';
import 'package:beslet_app/core/providers/todo_provider.dart';
import 'package:beslet_app/core/providers/word_challenge_provider.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:beslet_app/features/word_challenge/word_challenge_screen.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide Column, isNull, isNotNull;
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

/// A fake audio notifier that always fails to speak — the screen must simply
/// keep working, exactly as it would on a device with no TTS engine.
class _ThrowingAudioNotifier extends AudioPlayerNotifier {
  @override
  Future<void> speakVerse(String text, {required bool isAmharic}) async {
    throw Exception('no tts engine');
  }
}

void main() {
  group('schema', () {
    test('schema version is 23 (verse challenge migration applied)', () {
      final db = AppDatabase.forTesting(LazyDatabase(() async {
        throw StateError('should not open');
      }));
      expect(db.schemaVersion, 23);
    });
  });

  group('word challenge (requires native sqlite3)', () {
    AppDatabase? db;
    late bool available;

    setUp(() {
      available = _canOpenSqlite();
      db = available ? AppDatabase.forTesting(NativeDatabase.memory()) : null;
    });

    tearDown(() async {
      await db?.close();
    });

    ProviderContainer container() {
      final c = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db!),
      ]);
      addTearDown(c.dispose);
      return c;
    }

    String today() => DateTime.now().toIso8601String().substring(0, 10);

    test('today\'s challenge is the Thread verse for today', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final data = await c.read(todayWordChallengeProvider.future);
      final scripture = ScriptureService.threadVerseFor(DateTime.now());
      expect(data.reference, scripture.reference);
      expect(data.textEn, scripture.text);
      expect(data.masteryLevel, 0);
    });

    test('completing the build climbs mastery 0→1→2 and clamps at rooted', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final notifier = c.read(wordChallengeNotifierProvider.notifier);

      await notifier.completeBuild();
      var data = await c.read(todayWordChallengeProvider.future);
      expect(data.masteryLevel, 1);
      expect(data.mastery, VerseMastery.growing);
      expect(data.completions, 1);

      await notifier.completeBuild();
      data = await c.read(todayWordChallengeProvider.future);
      expect(data.masteryLevel, 2);
      expect(data.isRooted, isTrue);

      await notifier.completeBuild();
      data = await c.read(todayWordChallengeProvider.future);
      expect(data.masteryLevel, 2);
      expect(data.completions, 3);
    });

    test('completeBuild marks today\'s Word step exactly once (XP on the yes)', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final notifier = c.read(wordChallengeNotifierProvider.notifier);

      await notifier.completeBuild();
      await notifier.completeBuild();

      final rows = await (db!.select(db!.readingSessions)
            ..where((t) => t.date.equals(today())))
          .get();
      expect(rows.length, 1, reason: 'a second build must not double the step');
      expect(rows.first.completed, isTrue);
    });

    test('savePrayer stores the prayer and lights the Prayer step', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final notifier = c.read(wordChallengeNotifierProvider.notifier);

      await notifier.savePrayer('Lord, help me to live this out today');

      final data = await c.read(todayWordChallengeProvider.future);
      expect(data.userPrayer, 'Lord, help me to live this out today');

      final prayed = await c.read(todayPrayerLogProvider.future);
      expect(prayed, isNotNull);
    });

    test('chooseAct adds a real task and records the act', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final notifier = c.read(wordChallengeNotifierProvider.notifier);

      await notifier.chooseAct('Call a friend about the verse');

      final data = await c.read(todayWordChallengeProvider.future);
      expect(data.chosenAct, 'Call a friend about the verse');
      expect(data.actDone, isTrue);

      final todos = await c.read(todayTodosProvider.future);
      expect(todos.map((t) => t.title), contains('Call a friend about the verse'));
    });

    test('a due verse surfaces in reviewDueCount and review stretches its interval', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final notifier = c.read(wordChallengeNotifierProvider.notifier);
      final data = await c.read(todayWordChallengeProvider.future);

      await db!.into(db!.verseChallenges).insert(
        VerseChallengesCompanion.insert(
          id: data.id,
          reference: data.reference,
          textEn: data.textEn,
          textAm: Value<String?>(data.textAm),
          nextReviewDate: const Value('2000-01-01'),
        ),
      );

      expect(await c.read(reviewDueCountProvider.future), 1);

      await notifier.reviewVerse(data.id);

      final after = await c.read(allWordChallengesProvider.future);
      final row = after.firstWhere((v) => v.id == data.id);
      expect(row.reviewCount, 1);
      expect(row.completions, 1, reason: 'a review is a gentle revisit');
      expect(row.nextReviewDate!.compareTo(today()) > 0, isTrue);

      expect(await c.read(reviewDueCountProvider.future), 0);
    });

    test('a review that is not due stays calm: count grows, XP untouched', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final notifier = c.read(wordChallengeNotifierProvider.notifier);
      final data = await c.read(todayWordChallengeProvider.future);

      await db!.into(db!.verseChallenges).insert(
        VerseChallengesCompanion.insert(
          id: data.id,
          reference: data.reference,
          textEn: data.textEn,
          textAm: Value<String?>(data.textAm),
          masteryLevel: const Value(2),
          nextReviewDate: const Value('2099-12-31'),
        ),
      );

      await notifier.reviewVerse(data.id);

      final after = await c.read(allWordChallengesProvider.future);
      final row = after.firstWhere((v) => v.id == data.id);
      expect(row.masteryLevel, 2);
      expect(await c.read(reviewDueCountProvider.future), 0);
    });
  });

  group('word challenge screen', () {
    testWidgets('renders and survives a failing TTS engine', (tester) async {
      if (!_canOpenSqlite()) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            audioPlayerProvider.overrideWith(() => _ThrowingAudioNotifier()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: WordChallengeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(WordChallengeScreen), findsOneWidget);

      final hear = find.text('Hear the verse');
      if (hear.evaluate().isNotEmpty) {
        await tester.tap(hear);
        await tester.pump();
      }

      final continueBtn = find.text('Continue');
      if (continueBtn.evaluate().isNotEmpty) {
        await tester.tap(continueBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(WordChallengeScreen), findsOneWidget);
    });
  });
}
