import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/app_database.dart';
import '../services/xp_service.dart';
import '../services/streak_service.dart';
import '../services/badge_service.dart';
import 'database_provider.dart';

class TrackingData {
  final int totalXp;
  final int level;
  final String levelName;
  final int streak;
  final int prayerMinutes;
  final int bibleDays;
  final int habitsDone;
  final int skillsMinutes;
  final List<Map<String, dynamic>> badges;
  final double levelProgress;

  TrackingData({
    required this.totalXp,
    required this.level,
    required this.levelName,
    required this.streak,
    required this.prayerMinutes,
    required this.bibleDays,
    required this.habitsDone,
    required this.skillsMinutes,
    required this.badges,
    required this.levelProgress,
  });
}

final trackingDataProvider = FutureProvider<TrackingData>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final startOfWeek = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)).toIso8601String().substring(0, 10);

  final allCompletions = await db.select(db.completions).get();
  final habitsDone = allCompletions.where((c) => c.date == today).length;
  final streakDates = allCompletions.map((c) => c.date).toSet().toList()..sort();
  final streak = StreakService.calculateStreak(streakDates);

  final allPrayerLogs = await db.select(db.prayerLogs).get();
  final prayerLogsThisWeek = allPrayerLogs.where((l) => l.date.compareTo(startOfWeek) >= 0);
  final prayerMinutes = prayerLogsThisWeek.fold(0, (int sum, l) => sum + l.minutes);
  final prayerDaysThisWeek = prayerLogsThisWeek.map((l) => l.date).toSet().length;

  final reads = await (db.select(db.bibleReads)..where((t) => t.date.equals(today))).get();
  final bibleDays = reads.length;

  final sessions = await (db.select(db.skillSessions)..where((t) => t.date.equals(today))).get();
  final skillsMinutes = sessions.fold(0, (int sum, s) => sum + s.minutes);

  final weekReflections = await (db.select(db.reflections)..where((t) => t.weekStart.equals(startOfWeek))).get();
  final reflectionDone = weekReflections.isNotEmpty ? 1 : 0;

  final totalXp = habitsDone * XpService.habitComplete +
      bibleDays * XpService.bibleRead +
      prayerDaysThisWeek * XpService.prayerComplete +
      skillsMinutes * XpService.skillSession +
      reflectionDone * XpService.reflectionComplete;

  final level = XpService.calculateLevel(totalXp);
  final levelName = XpService.getLevelName(level);
  final levelProgress = XpService.xpProgress(totalXp);

  final badges = BadgeService.checkBadges(totalXp, streak, prayerMinutes, bibleDays);

  return TrackingData(
    totalXp: totalXp,
    level: level,
    levelName: levelName,
    streak: streak,
    prayerMinutes: prayerMinutes,
    bibleDays: bibleDays,
    habitsDone: habitsDone,
    skillsMinutes: skillsMinutes,
    badges: badges,
    levelProgress: levelProgress,
  );
});

final reflectionProvider = FutureProvider<Reflection?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final startOfWeek = today.subtract(Duration(days: today.weekday - 1)).toIso8601String().substring(0, 10);
  final reflections = await (db.select(db.reflections)..where((t) => t.weekStart.equals(startOfWeek))).get();
  return reflections.isNotEmpty ? reflections.first : null;
});

class ReflectionNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> saveReflection({String? grew, String? slipped, String? nextFocus}) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1)).toIso8601String().substring(0, 10);
    final existing = await (db.select(db.reflections)..where((t) => t.weekStart.equals(weekStart))).get();
    if (existing.isNotEmpty) {
      await (db.update(db.reflections)..where((t) => t.weekStart.equals(weekStart))).write(
        ReflectionsCompanion(grew: Value(grew), slipped: Value(slipped), nextFocus: Value(nextFocus)),
      );
    } else {
      await db.into(db.reflections).insert(ReflectionsCompanion.insert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        weekStart: weekStart,
        grew: Value<String?>(grew),
        slipped: Value<String?>(slipped),
        nextFocus: Value<String?>(nextFocus),
        createdAt: DateTime.now().toIso8601String(),
      ));
    }
    ref.invalidate(reflectionProvider);
    ref.invalidate(trackingDataProvider);
  }
}

final reflectionNotifierProvider = AsyncNotifierProvider<ReflectionNotifier, void>(ReflectionNotifier.new);
