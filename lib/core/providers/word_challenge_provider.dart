import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../services/scene_event_bus.dart';
import '../services/scripture_service.dart';
import 'daily_flow_provider.dart';
import 'database_provider.dart';
import 'growth_streams_provider.dart';
import 'prayer_provider.dart';
import 'scripture_provider.dart';
import 'todo_provider.dart';
import 'tracking_provider.dart';

/// How far a verse has taken root. A gentle ladder, never a score: a quiet
/// day simply doesn't climb.
enum VerseMastery { new_, growing, rooted }

/// One verse in the Word Challenge. Either loaded from the Drift store or the
/// day's Thread verse with its starting values.
class VerseChallengeData {
  final String id;
  final String reference;
  final String textEn;
  final String? textAm;
  final int masteryLevel;
  final int completions;
  final String? lastCompletedDate;
  final String? userPrayer;
  final String? nextReviewDate;
  final int reviewCount;
  final String? chosenAct;
  final bool actDone;

  const VerseChallengeData({
    required this.id,
    required this.reference,
    required this.textEn,
    this.textAm,
    this.masteryLevel = 0,
    this.completions = 0,
    this.lastCompletedDate,
    this.userPrayer,
    this.nextReviewDate,
    this.reviewCount = 0,
    this.chosenAct,
    this.actDone = false,
  });

  VerseMastery get mastery => switch (masteryLevel) {
        0 => VerseMastery.new_,
        1 => VerseMastery.growing,
        _ => VerseMastery.rooted,
      };

  bool get isRooted => masteryLevel >= 2;

  /// True when this verse was completed (or re-completed) on the given day.
  bool wasCompletedOn(String date) => lastCompletedDate == date;

  factory VerseChallengeData.fromRow(VerseChallenge row) => VerseChallengeData(
        id: row.id,
        reference: row.reference,
        textEn: row.textEn,
        textAm: row.textAm,
        masteryLevel: row.masteryLevel,
        completions: row.completions,
        lastCompletedDate: row.lastCompletedDate,
        userPrayer: row.userPrayer,
        nextReviewDate: row.nextReviewDate,
        reviewCount: row.reviewCount,
        chosenAct: row.chosenAct,
        actDone: row.actDone,
      );

  factory VerseChallengeData.fromScripture(Scripture s) => VerseChallengeData(
        id: _verseId(s),
        reference: s.reference,
        textEn: s.text,
        textAm: s.textAm,
      );
}

String _verseId(Scripture s) => s.reference
    .toLowerCase()
    .replaceAll(RegExp('[^a-z0-9]+'), '_')
    .replaceAll(RegExp('^_+|_+\$'), '');

String _dateOnly(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Spaced repetition: after each completion the next gentle review is a few
/// days further out, so a rooted verse is revisited — never nagged.
const List<int> _reviewIntervals = [1, 3, 7, 30];

/// Today's verse and its journey so far.
final todayWordChallengeProvider = FutureProvider<VerseChallengeData>((ref) async {
  final scripture = ScriptureService.threadVerseFor(DateTime.now());
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.verseChallenges)
        ..where((t) => t.id.equals(_verseId(scripture))))
      .get();
  if (rows.isNotEmpty) return VerseChallengeData.fromRow(rows.first);
  return VerseChallengeData.fromScripture(scripture);
});

/// Every verse the user has touched, most recently completed first.
final allWordChallengesProvider = FutureProvider<List<VerseChallengeData>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await db.select(db.verseChallenges).get();
  final list = rows.map(VerseChallengeData.fromRow).toList()
    ..sort((a, b) => (b.lastCompletedDate ?? '').compareTo(a.lastCompletedDate ?? ''));
  return list;
});

/// Verses quietly due for a review today (nextReviewDate has arrived).
final reviewDueCountProvider = FutureProvider<int>((ref) async {
  final today = _dateOnly(DateTime.now());
  final all = await ref.watch(allWordChallengesProvider.future);
  return all.where((c) => c.nextReviewDate != null && c.nextReviewDate!.compareTo(today) <= 0).length;
});

/// How many verses have fully taken root (ROOTED).
final rootedVerseCountProvider = FutureProvider<int>((ref) async {
  final all = await ref.watch(allWordChallengesProvider.future);
  return all.where((c) => c.isRooted).length;
});

/// Drives the Word Challenge. `completeBuild` also marks the day's Word step
/// (awarding the reading XP exactly once), `savePrayer` lights the Prayer
/// step, and `chooseAct` adds a real task so the Act step lights too.
class WordChallengeNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> completeBuild() async {
    final db = ref.read(databaseProvider);
    final scripture = ScriptureService.threadVerseFor(DateTime.now());
    final id = _verseId(scripture);
    final today = _dateOnly(DateTime.now());
    final now = DateTime.now();

    final existing = await (db.select(db.verseChallenges)
          ..where((t) => t.id.equals(id)))
        .get();
    final prevMastery = existing.isEmpty ? 0 : existing.first.masteryLevel;
    final nextMastery = (prevMastery + 1).clamp(0, 2);
    final intervalIndex =
        (existing.isEmpty ? 0 : existing.first.reviewCount).clamp(0, _reviewIntervals.length - 1);
    final nextReview = _dateOnly(now.add(Duration(days: _reviewIntervals[intervalIndex])));

    if (existing.isNotEmpty) {
      await (db.update(db.verseChallenges)..where((t) => t.id.equals(id))).write(
        VerseChallengesCompanion(
          masteryLevel: Value(nextMastery),
          completions: Value(existing.first.completions + 1),
          lastCompletedDate: Value(today),
          nextReviewDate: Value(nextReview),
          reviewCount: Value(existing.first.reviewCount + 1),
        ),
      );
    } else {
      await db.into(db.verseChallenges).insert(
        VerseChallengesCompanion.insert(
          id: id,
          reference: scripture.reference,
          textEn: scripture.text,
          textAm: Value<String?>(scripture.textAm),
          masteryLevel: Value(nextMastery),
          completions: const Value(1),
          lastCompletedDate: Value(today),
          nextReviewDate: Value(nextReview),
          reviewCount: const Value(1),
        ),
      );
    }

    // The Word step: mark today's reading complete (XP is granted once, here).
    var bookId = ScriptureService.parseReference(scripture.reference)?.bookId;
    var chapter = ScriptureService.parseReference(scripture.reference)?.chapter;
    if (bookId == null) {
      final plan = ref.read(todayBiblePlanProvider);
      bookId = plan.bookId;
      chapter = plan.chapter;
    }
    await ref.read(readingNotifierProvider.notifier).markCompleted(bookId: bookId, chapter: chapter);

    final bus = ref.read(sceneEventBusProvider);
    bus.emit(SceneEventType.fruitPop);
    if (nextMastery >= 2 && prevMastery < 2) {
      bus.emit(SceneEventType.bloom);
    }
    _invalidate();
  }

  Future<void> savePrayer(String prayer) async {
    final db = ref.read(databaseProvider);
    final scripture = ScriptureService.threadVerseFor(DateTime.now());
    final id = _verseId(scripture);
    final existing = await (db.select(db.verseChallenges)
          ..where((t) => t.id.equals(id)))
        .get();
    if (existing.isNotEmpty) {
      await (db.update(db.verseChallenges)..where((t) => t.id.equals(id)))
          .write(VerseChallengesCompanion(userPrayer: Value(prayer)));
    } else {
      await db.into(db.verseChallenges).insert(
        VerseChallengesCompanion.insert(
          id: id,
          reference: scripture.reference,
          textEn: scripture.text,
          textAm: Value<String?>(scripture.textAm),
          userPrayer: Value(prayer),
        ),
      );
    }
    await ref.read(prayerNotifierProvider.notifier).logPrayer(1, note: prayer);
    _invalidate();
  }

  Future<void> chooseAct(String act) async {
    final db = ref.read(databaseProvider);
    final scripture = ScriptureService.threadVerseFor(DateTime.now());
    final id = _verseId(scripture);
    final existing = await (db.select(db.verseChallenges)
          ..where((t) => t.id.equals(id)))
        .get();
    if (existing.isNotEmpty) {
      await (db.update(db.verseChallenges)..where((t) => t.id.equals(id)))
          .write(VerseChallengesCompanion(
        chosenAct: Value(act),
        actDone: const Value(true),
      ));
    } else {
      await db.into(db.verseChallenges).insert(
        VerseChallengesCompanion.insert(
          id: id,
          reference: scripture.reference,
          textEn: scripture.text,
          textAm: Value<String?>(scripture.textAm),
          chosenAct: Value(act),
          actDone: const Value(true),
        ),
      );
    }
    await ref.read(todoNotifierProvider.notifier).addTodo(act);
    _invalidate();
  }

  /// A gentle revisit of a previously completed verse: the interval stretches
  /// and the count grows, but no pillar or XP is touched — it is review, not
  /// a new day.
  Future<void> reviewVerse(String id) async {
    final db = ref.read(databaseProvider);
    final existing = await (db.select(db.verseChallenges)
          ..where((t) => t.id.equals(id)))
        .get();
    if (existing.isEmpty) return;
    final intervalIndex =
        existing.first.reviewCount.clamp(0, _reviewIntervals.length - 1);
    final nextReview = _dateOnly(DateTime.now().add(Duration(days: _reviewIntervals[intervalIndex])));
    await (db.update(db.verseChallenges)..where((t) => t.id.equals(id))).write(
      VerseChallengesCompanion(
        reviewCount: Value(existing.first.reviewCount + 1),
        nextReviewDate: Value(nextReview),
        completions: Value(existing.first.completions + 1),
      ),
    );
    _invalidate();
  }

  void _invalidate() {
    ref.invalidate(allWordChallengesProvider);
    ref.invalidate(todayWordChallengeProvider);
    ref.invalidate(reviewDueCountProvider);
    ref.invalidate(rootedVerseCountProvider);
    ref.invalidate(trackingDataProvider);
    ref.invalidate(dailyFlowProvider);
    ref.invalidate(todayReadingProvider);
  }
}

final wordChallengeNotifierProvider =
    AsyncNotifierProvider<WordChallengeNotifier, void>(WordChallengeNotifier.new);
