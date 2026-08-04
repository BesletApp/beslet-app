import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../services/growth_streams.dart';
import 'database_provider.dart';
import 'fellowship_provider.dart';
import 'habits_provider.dart';
import 'prayer_provider.dart';
import 'soul_log_provider.dart';
import 'streak_provider.dart';
import 'tracking_provider.dart';

/// Whether the user spent time in the Word today (a gentle memory, never a
/// score — a quiet day is simply not counted).
final todayReadingProvider = FutureProvider<ReadingSession?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final rows = await (db.select(db.readingSessions)
    ..where((t) => t.date.equals(today))).get();
  return rows.isEmpty ? null : rows.first;
});

class ReadingNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> logReading({int minutes = 1, String? bookId, int? chapter}) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.readingSessions)
      ..where((t) => t.date.equals(today))).get();
    if (existing.isNotEmpty) {
      await (db.update(db.readingSessions)..where((t) => t.date.equals(today)))
          .write(ReadingSessionsCompanion(
        minutes: Value(existing.first.minutes + minutes),
      ));
    } else {
      await db.into(db.readingSessions).insert(ReadingSessionsCompanion.insert(
        id: const Uuid().v4(),
        date: today,
        minutes: Value<int>(minutes),
        bookId: Value<String?>(bookId),
        chapter: Value<int?>(chapter),
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
    ref.invalidate(todayReadingProvider);
    ref.invalidate(weekLivingProvider);
  }
}

final readingNotifierProvider =
    AsyncNotifierProvider<ReadingNotifier, void>(ReadingNotifier.new);

/// The day's rhythm: 5 steps — Word, Prayer, Habits, Skills, Fellowship.
final todayRhythmProvider = Provider<({int done, int total})>((ref) {
  final read = ref.watch(todayReadingProvider).valueOrNull != null;
  final prayed = ref.watch(todayPrayerLogProvider).valueOrNull != null;
  final habits = ref.watch(todayCompletionsProvider).valueOrNull?.isNotEmpty == true;
  final skills = (ref.watch(trackingDataProvider).valueOrNull?.skillsMinutes ?? 0) > 0;
  final connected = ref.watch(todayFellowshipProvider).valueOrNull != null;
  final done = [read, prayed, habits, skills, connected].where((d) => d).length;
  return (done: done, total: 5);
});

/// Seven-day composite living-day intensity (0-5 disciplines per day).
final weekLivingProvider = FutureProvider<List<int>>((ref) async {
  ref.watch(trackingDataProvider);
  ref.watch(todayCompletionsProvider);
  ref.watch(todayReadingProvider);
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final weekAgo = today.subtract(const Duration(days: 6)).toIso8601String().substring(0, 10);

  final readDates = (await db.select(db.readingSessions).get())
      .where((r) => r.date.compareTo(weekAgo) >= 0)
      .map((r) => r.date)
      .toSet();
  final prayerDates = (await db.select(db.prayerLogs).get())
      .where((r) => r.date.compareTo(weekAgo) >= 0)
      .map((r) => r.date)
      .toSet();
  final habitDates = (await db.select(db.completions).get())
      .where((r) => r.date.compareTo(weekAgo) >= 0)
      .map((r) => r.date)
      .toSet();
  final skillDates = (await db.select(db.skillSessions).get())
      .where((r) => r.date.compareTo(weekAgo) >= 0)
      .map((r) => r.date)
      .toSet();
  final fellowDates = (await db.select(db.fellowshipLogs).get())
      .where((r) => r.date.compareTo(weekAgo) >= 0)
      .map((r) => r.date)
      .toSet();

  final result = <int>[];
  for (var i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i)).toIso8601String().substring(0, 10);
    var count = 0;
    if (readDates.contains(day)) count++;
    if (prayerDates.contains(day)) count++;
    if (habitDates.contains(day)) count++;
    if (skillDates.contains(day)) count++;
    if (fellowDates.contains(day)) count++;
    result.add(count);
  }
  return result;
});

/// Today's living vitality for the vine — prayer waters, the Word lights the
/// leaves, fellowship opens the branches, consistency ripens the fruit.
final growthVitalityProvider = Provider<GrowthVitality>((ref) {
  final prayed = ref.watch(todayPrayerLogProvider).valueOrNull != null;
  final read = ref.watch(todayReadingProvider).valueOrNull != null;
  final connected = ref.watch(todayFellowshipProvider).valueOrNull != null;
  final habitsDone = ref.watch(todayCompletionsProvider).valueOrNull?.length ?? 0;
  final bestStreak = ref.watch(streakStateProvider).valueOrNull?.bestStreak ?? 0;
  final mood = ref.watch(todaySoulLogProvider).valueOrNull?.mood;
  return GrowthVitality.compute(
    prayed: prayed,
    read: read,
    connected: connected,
    habitsDone: habitsDone,
    bestStreak: bestStreak,
    mood: mood,
  );
});
