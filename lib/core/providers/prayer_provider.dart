import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';
import 'streak_provider.dart';

final todayPrayerLogProvider = FutureProvider<PrayerLog?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final logs = await (db.select(db.prayerLogs)..where((t) => t.date.equals(today))).get();
  return logs.isNotEmpty ? logs.first : null;
});

final prayerDaysThisWeekProvider = FutureProvider<List<bool>>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
  final weekStart = startOfWeek.toIso8601String().substring(0, 10);
  final logs = await db.select(db.prayerLogs).get();
  final prayedDates = logs.where((l) => l.date.compareTo(weekStart) >= 0).map((l) => l.date).toSet();
  final result = <bool>[];
  for (int i = 0; i < 7; i++) {
    final day = startOfWeek.add(Duration(days: i));
    final dayStr = day.toIso8601String().substring(0, 10);
    result.add(prayedDates.contains(dayStr));
  }
  return result;
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
        note: Value<String?>(note),
      ));
    }
    ref.invalidate(todayPrayerLogProvider);
    ref.invalidate(prayerDaysThisWeekProvider);
    ref.invalidate(trackingDataProvider);
    ref.invalidate(streakStateProvider);
    ref.invalidate(streakLogsProvider);
    ref.invalidate(streakWeekDataProvider);
  }
}

final prayerNotifierProvider = AsyncNotifierProvider<PrayerNotifier, void>(PrayerNotifier.new);
