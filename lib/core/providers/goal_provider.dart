import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

String _periodStart(String type) {
  final now = DateTime.now();
  switch (type) {
    case 'weekly':
      final monday = now.subtract(Duration(days: now.weekday - 1));
      return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
    case 'monthly':
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    case 'yearly':
      return '${now.year}-01-01';
    default:
      return now.toIso8601String().substring(0, 10);
  }
}

final currentPeriodGoalsProvider = FutureProvider.family<List<Goal>, String>((ref, type) async {
  final db = ref.watch(databaseProvider);
  final periodStart = _periodStart(type);
  final all = await (db.select(db.goals)
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
  ).get();
  return all.where((g) => g.type == type && g.periodStart == periodStart).toList();
});

final pastGoalsProvider = FutureProvider.family<List<Goal>, String>((ref, type) async {
  final db = ref.watch(databaseProvider);
  final currentStart = _periodStart(type);
  final all = await (db.select(db.goals)
    ..orderBy([(t) => OrderingTerm(expression: t.periodStart, mode: OrderingMode.desc)])
  ).get();
  return all.where((g) => g.type == type && g.periodStart != currentStart).toList();
});

final pastPeriodStartsProvider = FutureProvider.family<List<String>, String>((ref, type) async {
  final db = ref.watch(databaseProvider);
  final currentStart = _periodStart(type);
  final all = await db.select(db.goals).get();
  final starts = all.where((g) => g.type == type && g.periodStart != currentStart).map((g) => g.periodStart).toSet().toList();
  starts.sort((a, b) => b.compareTo(a));
  return starts;
});

class GoalNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> addGoal(String title, String type) async {
    final db = ref.read(databaseProvider);
    final periodStart = _periodStart(type);
    await db.into(db.goals).insert(GoalsCompanion.insert(
      id: const Uuid().v4(),
      title: title,
      type: type,
      periodStart: periodStart,
      createdAt: DateTime.now().toIso8601String(),
    ));
    ref.invalidate(currentPeriodGoalsProvider);
    ref.invalidate(pastGoalsProvider);
    ref.invalidate(pastPeriodStartsProvider);
  }

  Future<void> toggleAchieved(String id) async {
    final db = ref.read(databaseProvider);
    final goal = await (db.select(db.goals)..where((t) => t.id.equals(id))).getSingle();
    await (db.update(db.goals)..where((t) => t.id.equals(id))).write(GoalsCompanion(
      isAchieved: Value(!goal.isAchieved),
    ));
    ref.invalidate(currentPeriodGoalsProvider);
    ref.invalidate(pastGoalsProvider);
  }

  Future<void> deleteGoal(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.goals)..where((t) => t.id.equals(id))).go();
    ref.invalidate(currentPeriodGoalsProvider);
    ref.invalidate(pastGoalsProvider);
    ref.invalidate(pastPeriodStartsProvider);
  }
}

final goalNotifierProvider = AsyncNotifierProvider<GoalNotifier, void>(GoalNotifier.new);
