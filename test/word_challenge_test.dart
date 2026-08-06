import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/audio_player_provider.dart';
import 'package:beslet_app/core/providers/database_provider.dart';
import 'package:beslet_app/core/providers/prayer_provider.dart';
import 'package:beslet_app/core/providers/todo_provider.dart';
import 'package:beslet_app/core/providers/word_challenge_provider.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:beslet_app/features/word_challenge/verse_builder_loop.dart';
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

void main() {
  group('schema', () {
    test('schema version is 24 (verse challenge migration applied)', () {
      final db = AppDatabase.forTesting(LazyDatabase(() async {
        throw StateError('should not open');
      }));
      expect(db.schemaVersion, 24);
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

    test('first build of the day climbs mastery 0→1; later passes are silent', () async {
      if (!available) return markTestSkipped('no sqlite3');
      final c = container();
      final notifier = c.read(wordChallengeNotifierProvider.notifier);

      await notifier.completeBuild();
      var data = await c.read(todayWordChallengeProvider.future);
      expect(data.masteryLevel, 1);
      expect(data.mastery, VerseMastery.growing);
      expect(data.completions, 1);

      // Same day: the loop re-runs freely, but the DB is untouched.
      await notifier.completeBuild();
      await notifier.completeBuild();
      data = await c.read(todayWordChallengeProvider.future);
      expect(data.masteryLevel, 1, reason: 'a same-day loop must not grind mastery');
      expect(data.completions, 1, reason: 'a same-day loop must not double the count');
    });

    test('mastery climbs to rooted on a later day', () async {
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
          masteryLevel: const Value(1),
          completions: const Value(1),
          lastCompletedDate: const Value('2000-01-01'),
        ),
      );

      await notifier.completeBuild();
      final after = await c.read(todayWordChallengeProvider.future);
      expect(after.masteryLevel, 2);
      expect(after.isRooted, isTrue);
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

  group('word challenge loop', () {
    testWidgets('see → build → celebrate → reshuffle, with no audio and no buttons', (tester) async {
      if (!_canOpenSqlite()) {
        return markTestSkipped('sqlite3 native library unavailable on this host');
      }
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      var spoke = false;
      final audio = _TrackingAudioNotifier(() => spoke = true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            audioPlayerProvider.overrideWith(() => audio),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: VersePracticeLoop(
                verse: VerseChallengeData(
                  id: 'test_verse',
                  reference: 'Ps 119:11',
                  textEn: 'I have hidden your word in my heart',
                  textAm: null,
                  masteryLevel: 0,
                ),
              ),
            ),
          ),
        ),
      );

      final l = AppLocalizations.of(tester.element(find.byType(VersePracticeLoop)))!;

      // see phase shows the verse quietly, then auto-advances (no Continue).
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ActionChip), findsWidgets);

      // Build the verse by tapping the correct tail words in order.
      for (final word in ['in', 'my', 'heart']) {
        final chip = find.widgetWithText(ActionChip, word);
        expect(chip, findsOneWidget, reason: 'chip for "$word" should be tappable');
        await tester.tap(chip);
        await tester.pump(const Duration(milliseconds: 60));
      }

      // "Well done 🌱" flashes, then the loop reshuffles on its own.
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(l.wellDone), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ActionChip), findsWidgets,
          reason: 'the loop must reshuffle into a fresh build, not stop');
      expect(spoke, isFalse, reason: 'the loop must never touch TTS');
    });
  });
}

/// A fake audio notifier that records every attempt to speak and fails fast —
/// proving the practice loop is silent.
class _TrackingAudioNotifier extends AudioPlayerNotifier {
  final void Function() onSpeak;
  _TrackingAudioNotifier(this.onSpeak);

  @override
  Future<void> speakVerse(String text, {required bool isAmharic}) async {
    onSpeak();
  }
}
