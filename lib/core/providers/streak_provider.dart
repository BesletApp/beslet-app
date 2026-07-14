import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../services/streak_service.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final streakStateProvider = FutureProvider<StreakState>((ref) async {
  final db = ref.watch(databaseProvider);
  return StreakService.checkAndUpdate(db);
});

final streakLogsProvider = FutureProvider<List<StreakLogData>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.streakLog)
    ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
  ).get();
});

final streakWeekDataProvider = FutureProvider<List<bool>>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final logs = await db.select(db.streakLog).get();
  return List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i)).toIso8601String().substring(0, 10);
    return logs.any((l) => l.date == day && (l.counted || l.freezeUsed));
  });
});

class StreakNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> attemptRepair() async {
    ref.invalidate(streakStateProvider);
    ref.invalidate(trackingDataProvider);
  }
}

final streakNotifierProvider = AsyncNotifierProvider<StreakNotifier, void>(StreakNotifier.new);
