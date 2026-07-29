import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class StreakState {
  final int currentStreak;
  final int bestStreak;
  final int freezeTokens;
  final bool isAtRisk;
  final bool isBroken;
  final String? brokenDate;
  final bool isSabbathToday;
  final List<bool> weekDays;

  StreakState({
    required this.currentStreak,
    required this.bestStreak,
    required this.freezeTokens,
    required this.isAtRisk,
    required this.isBroken,
    this.brokenDate,
    this.isSabbathToday = false,
    required this.weekDays,
  });
}

class StreakService {
  static Future<bool> didAnchorOnDate(AppDatabase db, String date) async {
    final prayers = await (db.select(db.prayerLogs)..where((t) => t.date.equals(date))).get();
    if (prayers.isNotEmpty) return true;
    final reads = await (db.select(db.bibleReads)..where((t) => t.date.equals(date))).get();
    return reads.isNotEmpty;
  }

  static Future<StreakState> checkAndUpdate(AppDatabase db) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final todayAnchor = await didAnchorOnDate(db, today);

    final users = await db.select(db.users).get();
    final sabbathDay = users.isNotEmpty ? users.first.sabbathDay : -1;
    final isSabbath = sabbathDay >= 0 && DateTime.now().weekday == sabbathDay;

    final freezeRows = await db.select(db.streakFrozen).get();
    StreakFrozenData freeze;
    if (freezeRows.isEmpty) {
      final id = const Uuid().v4();
      await db.into(db.streakFrozen).insert(StreakFrozenCompanion.insert(
        id: id, count: 0, bestStreak: 0, freezesEarned: 0,
      ));
      freeze = await (db.select(db.streakFrozen)..where((t) => t.id.equals(id))).getSingle();
    } else {
      freeze = freezeRows.first;
    }

    final allLogs = await (db.select(db.streakLog)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).get();

    final todayLog = allLogs.where((l) => l.date == today).toList();

    if (todayAnchor && todayLog.isEmpty) {
      await db.into(db.streakLog).insert(StreakLogCompanion.insert(
        id: const Uuid().v4(), date: today, counted: true, freezeUsed: false,
        anchorType: 'prayer_bible', createdAt: DateTime.now().toIso8601String(),
      ));
      if (freeze.brokenDate != null) {
        await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
            .write(const StreakFrozenCompanion(brokenDate: Value(null)));
      }
    } else if (!todayAnchor && todayLog.isEmpty) {
      if (isSabbath) {
        // Sabbath grace — auto-freeze without consuming a token
        await db.into(db.streakLog).insert(StreakLogCompanion.insert(
          id: const Uuid().v4(), date: today, counted: true, freezeUsed: true,
          anchorType: 'sabbath', createdAt: DateTime.now().toIso8601String(),
        ));
      } else {
        final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
        final yesterdayCounted = allLogs.any((l) => l.date == yesterday && (l.counted || l.freezeUsed));

        if (yesterdayCounted && freeze.count > 0) {
          await db.into(db.streakLog).insert(StreakLogCompanion.insert(
            id: const Uuid().v4(), date: today, counted: true, freezeUsed: true,
            anchorType: 'freeze', createdAt: DateTime.now().toIso8601String(),
          ));
          await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
              .write(StreakFrozenCompanion(count: Value(freeze.count - 1)));
        } else if (yesterdayCounted && freeze.count <= 0) {
          await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
              .write(StreakFrozenCompanion(brokenDate: Value(today)));
        }
      }
    }

    final refreshedLogs = await (db.select(db.streakLog)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).get();

    int currentStreak = 0;
    for (int i = 0; i < refreshedLogs.length; i++) {
      if (refreshedLogs[i].counted || refreshedLogs[i].freezeUsed) {
        currentStreak++;
      } else {
        break;
      }
    }

    if (currentStreak > freeze.bestStreak) {
      await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
          .write(StreakFrozenCompanion(bestStreak: Value(currentStreak)));
    }

    if (currentStreak >= 90 && freeze.freezesEarned < 5) {
      await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
          .write(StreakFrozenCompanion(count: Value(freeze.count + 3), freezesEarned: Value(5)));
    } else if (currentStreak >= 50 && freeze.freezesEarned < 4) {
      await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
          .write(StreakFrozenCompanion(count: Value(freeze.count + 2), freezesEarned: Value(4)));
    } else if (currentStreak >= 30 && freeze.freezesEarned < 3) {
      await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
          .write(StreakFrozenCompanion(count: Value(freeze.count + 2), freezesEarned: Value(3)));
    } else if (currentStreak >= 14 && freeze.freezesEarned < 2) {
      await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
          .write(StreakFrozenCompanion(count: Value(freeze.count + 1), freezesEarned: Value(2)));
    } else if (currentStreak >= 7 && freeze.freezesEarned < 1) {
      await (db.update(db.streakFrozen)..where((t) => t.id.equals(freeze.id)))
          .write(StreakFrozenCompanion(count: Value(freeze.count + 1), freezesEarned: Value(1)));
    }

    final finalFreeze = await (db.select(db.streakFrozen)).getSingle();
    final finalLogs = await (db.select(db.streakLog)
      ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
    ).get();

    final weekDays = <bool>[];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i)).toIso8601String().substring(0, 10);
      weekDays.add(finalLogs.any((l) => l.date == day && (l.counted || l.freezeUsed)));
    }

    return StreakState(
      currentStreak: currentStreak,
      bestStreak: finalFreeze.bestStreak,
      freezeTokens: finalFreeze.count,
      isAtRisk: !todayAnchor && !isSabbath,
      isBroken: finalFreeze.brokenDate != null,
      brokenDate: finalFreeze.brokenDate,
      isSabbathToday: isSabbath,
      weekDays: weekDays,
    );
  }

  static Color growthColor(int streak) {
    if (streak >= 90) return const Color(0xFF4CAF50);
    if (streak >= 30) return const Color(0xFF66BB6A);
    if (streak >= 14) return const Color(0xFF81C784);
    if (streak >= 7) return const Color(0xFFA5D6A7);
    return const Color(0xFFC8E6C9);
  }

  static String growthEmoji(int streak) {
    if (streak >= 90) return '🌳';
    if (streak >= 30) return '🌿';
    if (streak >= 14) return '🌱';
    if (streak >= 7) return '🌰';
    return '🌱';
  }

  static int calculateStreak(List<String> dates) {
    if (dates.isEmpty) return 0;
    final uniqueDates = dates.toSet().toList()..sort();
    final today = DateTime.now();
    final todayStr = _dateToString(today);
    int streak = 0;
    DateTime checkDate = today;
    if (!uniqueDates.contains(todayStr)) checkDate = today.subtract(const Duration(days: 1));
    while (uniqueDates.contains(_dateToString(checkDate))) { streak++; checkDate = checkDate.subtract(const Duration(days: 1)); }
    return streak;
  }

  static List<bool> getWeekData(List<String> dates) {
    final today = DateTime.now();
    return List.generate(7, (i) => dates.contains(_dateToString(today.subtract(Duration(days: 6 - i)))));
  }

  static String _dateToString(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
