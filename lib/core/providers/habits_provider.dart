import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final allHabitsProvider = FutureProvider<List<Habit>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.habits).get();
});

final todayCompletionsProvider = FutureProvider<Set<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final completions = await (db.select(db.completions)..where((t) => t.date.equals(today))).get();
  return completions.map((c) => c.habitId).toSet();
});

final weeklyHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final weekAgo = today.subtract(const Duration(days: 6));
  final weekAgoStr = weekAgo.toIso8601String().substring(0, 10);
  final allComps = await db.select(db.completions).get();
  final weekComps = allComps.where((c) => c.date.compareTo(weekAgoStr) >= 0).toList();
  final byDate = <String, int>{};
  for (final c in weekComps) {
    byDate[c.date] = (byDate[c.date] ?? 0) + 1;
  }
  final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final results = <Map<String, dynamic>>[];
  for (int i = 6; i >= 0; i--) {
    final day = today.subtract(Duration(days: i));
    final dayStr = day.toIso8601String().substring(0, 10);
    results.add({'date': dayStr, 'count': byDate[dayStr] ?? 0, 'dayName': dayNames[day.weekday % 7]});
  }
  return results;
});

final habitsWithCompletionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final db = ref.watch(databaseProvider);
  final habits = await db.select(db.habits).get();
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final todayComps = await (db.select(db.completions)..where((t) => t.date.equals(today))).get();
  final completedIds = todayComps.map((c) => c.habitId).toSet();
  return habits.map((h) => {'habit': h, 'completed': completedIds.contains(h.id)}).toList();
});

class HabitsNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> addHabit(String name, String category, String icon) async {
    final db = ref.read(databaseProvider);
    await db.into(db.habits).insert(HabitsCompanion.insert(
      id: const Uuid().v4(), name: name, category: category, frequency: 'daily', icon: icon,
      createdAt: DateTime.now().toIso8601String(),
    ));
    ref.invalidate(allHabitsProvider);
    ref.invalidate(habitsWithCompletionsProvider);
    ref.invalidate(trackingDataProvider);
  }

  Future<void> toggleCompletion(String habitId) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.completions)
      ..where((t) => t.habitId.equals(habitId))
      ..where((t) => t.date.equals(today))).get();
    if (existing.isNotEmpty) {
      await (db.delete(db.completions)
        ..where((t) => t.habitId.equals(habitId))
        ..where((t) => t.date.equals(today))).go();
    } else {
      await db.into(db.completions).insert(CompletionsCompanion.insert(habitId: habitId, date: today));
    }
    ref.invalidate(todayCompletionsProvider);
    ref.invalidate(habitsWithCompletionsProvider);
    ref.invalidate(weeklyHistoryProvider);
    ref.invalidate(trackingDataProvider);
  }

  Future<void> deleteHabit(String habitId) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.completions)..where((t) => t.habitId.equals(habitId))).go();
    await (db.delete(db.habits)..where((t) => t.id.equals(habitId))).go();
    ref.invalidate(allHabitsProvider);
    ref.invalidate(todayCompletionsProvider);
    ref.invalidate(habitsWithCompletionsProvider);
    ref.invalidate(weeklyHistoryProvider);
    ref.invalidate(trackingDataProvider);
  }
}

final habitsNotifierProvider = AsyncNotifierProvider<HabitsNotifier, void>(HabitsNotifier.new);
