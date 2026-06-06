import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final todayPrayerLogProvider = FutureProvider<PrayerLog?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final logs = await (db.select(db.prayerLogs)..where((t) => t.date.equals(today))).get();
  return logs.isNotEmpty ? logs.first : null;
});

final prayerMinutesThisWeekProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final weekStart = startOfWeek.toIso8601String().substring(0, 10);
  final logs = await db.select(db.prayerLogs).get();
  return logs.where((l) => l.date.compareTo(weekStart) >= 0).fold<int>(0, (sum, l) => sum + l.minutes);
});

final prayerStreakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 365)).toIso8601String().substring(0, 10);
  final logs = await db.select(db.prayerLogs).get();
  final dates = logs.where((l) => l.date.compareTo(cutoff) >= 0).map((l) => l.date).toSet().toList()..sort();
  int streak = 0;
  final now = DateTime.now();
  for (int i = dates.length - 1; i >= 0; i--) {
    final expected = now.subtract(Duration(days: streak)).toIso8601String().substring(0, 10);
    if (dates[i] == expected) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

class PrayerNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> logPrayer(int minutes, {String? note}) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.prayerLogs)..where((t) => t.date.equals(today))).get();
    if (existing.isNotEmpty) {
      await (db.update(db.prayerLogs)..where((t) => t.date.equals(today)))
          .write(PrayerLogsCompanion(minutes: Value(minutes)));
    } else {
      await db.into(db.prayerLogs).insert(PrayerLogsCompanion.insert(
        id: const Uuid().v4(), date: today, minutes: minutes,
      ));
    }
    ref.invalidate(todayPrayerLogProvider);
    ref.invalidate(prayerMinutesThisWeekProvider);
    ref.invalidate(prayerStreakProvider);
    ref.invalidate(trackingDataProvider);
  }
}

final prayerNotifierProvider = AsyncNotifierProvider<PrayerNotifier, void>(PrayerNotifier.new);

final prayerWeeklyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final weekAgo = today.subtract(const Duration(days: 6));
  final weekAgoStr = weekAgo.toIso8601String().substring(0, 10);
  final allLogs = await db.select(db.prayerLogs).get();
  final weekLogs = allLogs.where((l) => l.date.compareTo(weekAgoStr) >= 0).toList();
  final byDate = <String, int>{};
  for (final l in weekLogs) {
    byDate[l.date] = (byDate[l.date] ?? 0) + l.minutes;
  }
  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final results = <Map<String, dynamic>>[];
  for (int i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final dayStr = day.toIso8601String().substring(0, 10);
    results.add({
      'prayerMinutes': byDate[dayStr] ?? 0,
      'dayName': dayNames[day.weekday - 1],
      'date': dayStr,
    });
  }
  return results;
});
