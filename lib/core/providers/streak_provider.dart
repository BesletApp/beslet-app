import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final streakStateProvider = FutureProvider<StreakState>((ref) async {
  final db = ref.watch(databaseProvider);
  final state = await StreakService.checkAndUpdate(db);
  if (state.isBroken) {
    // Arm the gentle fresh-start message once per broken day: a comeback
    // can be a hard dialogue, so Beslet speaks "new mercies" — never guilt.
    try {
      final prefs = await SharedPreferences.getInstance();
      final already = prefs.getString('freshStartArmedFor') == state.brokenDate;
      if (!already) {
        await prefs.setString('freshStartArmedFor', state.brokenDate ?? '');
        await NotificationService.scheduleFreshStart();
      }
    } catch (_) {}
  }
  return state;
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
