import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/xp_service.dart';
import 'database_provider.dart';

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

final weeklyPillarCompletionsProvider =
    FutureProvider<Map<String, List<bool>>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final weekStrs =
      List.generate(7, (i) => _dateStr(now.subtract(Duration(days: 6 - i))));

  final prayers = await db.select(db.prayerLogs).get();
  final bibles = await db.select(db.bibleReads).get();
  final skills = await db.select(db.skillSessions).get();
  final fellowships = await db.select(db.fellowshipLogs).get();
  final allTodos = await db.select(db.todoItems).get();

  final prayerDates = prayers.map((l) => l.date).toSet();
  final bibleDates = bibles.map((l) => l.date).toSet();
  final skillDates = skills.map((l) => l.date).toSet();
  final fellowshipDates = fellowships.map((l) => l.date).toSet();
  final todoByDate = <String, int>{};
  for (final t in allTodos) {
    if (t.isCompleted && !t.isSkipped) {
      todoByDate.update(t.date, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  return {
    'prayer': weekStrs.map((d) => prayerDates.contains(d)).toList(),
    'bible': weekStrs.map((d) => bibleDates.contains(d)).toList(),
    'skills': weekStrs.map((d) => skillDates.contains(d)).toList(),
    'fellowship': weekStrs.map((d) => fellowshipDates.contains(d)).toList(),
    'tasks': weekStrs.map((d) => (todoByDate[d] ?? 0) > 0).toList(),
  };
});

int _bestStreak(List<String> sortedUnique) {
  if (sortedUnique.isEmpty) return 0;
  int max = 0, run = 0;
  DateTime? prev;
  for (final ds in sortedUnique) {
    final d = DateTime.parse(ds);
    if (prev != null && d.difference(prev).inDays == 1) {
      run++;
    } else {
      run = 1;
    }
    if (run > max) max = run;
    prev = d;
  }
  return max;
}

final overallBestStreakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final allCompletions = await db.select(db.completions).get();
  final dates = allCompletions.map((c) => c.date).toSet().toList()..sort();
  return _bestStreak(dates);
});

final sanctityScoreProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = _dateStr(DateTime.now());

  final prayers =
      await (db.select(db.prayerLogs)..where((t) => t.date.equals(today)))
          .get();
  final bibles =
      await (db.select(db.bibleReads)..where((t) => t.date.equals(today)))
          .get();
  final skills =
      await (db.select(db.skillSessions)..where((t) => t.date.equals(today)))
          .get();
  final fellowships = await (db.select(db.fellowshipLogs)
        ..where((t) => t.date.equals(today)))
      .get();
  final todayTodos = await (db.select(db.todoItems)..where((t) => t.date.equals(today))).get();
  final hasTodos = todayTodos.any((t) => t.isCompleted);

  const weights = {'prayer': 0.25, 'bible': 0.25, 'skills': 0.20, 'fellowship': 0.15, 'tasks': 0.15};
  double score = 0;
  if (prayers.isNotEmpty) score += weights['prayer']!;
  if (bibles.isNotEmpty) score += weights['bible']!;
  if (skills.isNotEmpty) score += weights['skills']!;
  if (fellowships.isNotEmpty) score += weights['fellowship']!;
  if (hasTodos) score += weights['tasks']!;
  return score;
});

final weeklyXpProvider = FutureProvider<List<double>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();

  final allPrayers = await db.select(db.prayerLogs).get();
  final allBibles = await db.select(db.bibleReads).get();
  final allSkills = await db.select(db.skillSessions).get();
  final allFellowships = await db.select(db.fellowshipLogs).get();
  final allTodos = await db.select(db.todoItems).get();

  final prayerDates = allPrayers.map((l) => l.date).toSet();
  final bibleDates = allBibles.map((l) => l.date).toSet();
  final skillMinByDate = <String, int>{};
  for (final s in allSkills) {
    skillMinByDate.update(s.date, (v) => v + s.minutes, ifAbsent: () => s.minutes);
  }
  final fellowshipDates = allFellowships.map((l) => l.date).toSet();
  final todoDoneByDate = <String, int>{};
  for (final t in allTodos) {
    if (t.isCompleted && !t.isSkipped) {
      todoDoneByDate.update(t.date, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  return List.generate(4, (i) {
    double xp = 0;
    for (int d = 0; d < 7; d++) {
      final day = _dateStr(now.subtract(Duration(days: (i * 7) + (6 - d))));
      if (prayerDates.contains(day)) xp += 15;
      if (bibleDates.contains(day)) xp += 20;
      if (skillMinByDate.containsKey(day)) xp += skillMinByDate[day]! * 5;
      if (fellowshipDates.contains(day)) xp += 10;
      final td = todoDoneByDate[day] ?? 0;
      if (td > 0) xp += td * XpService.todoComplete;
    }
    return xp;
  });
});

final dailyXpProvider = FutureProvider<List<double>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final weekStrs =
      List.generate(7, (i) => _dateStr(now.subtract(Duration(days: 6 - i))));

  final allPrayers = await db.select(db.prayerLogs).get();
  final allBibles = await db.select(db.bibleReads).get();
  final allSkills = await db.select(db.skillSessions).get();
  final allFellowships = await db.select(db.fellowshipLogs).get();
  final allTodos = await db.select(db.todoItems).get();

  final prayerDates = allPrayers.map((l) => l.date).toSet();
  final bibleDates = allBibles.map((l) => l.date).toSet();
  final skillMinByDate = <String, int>{};
  for (final s in allSkills) {
    skillMinByDate.update(s.date, (v) => v + s.minutes, ifAbsent: () => s.minutes);
  }
  final fellowshipDates = allFellowships.map((l) => l.date).toSet();
  final todoDoneByDate = <String, int>{};
  for (final t in allTodos) {
    if (t.isCompleted && !t.isSkipped) {
      todoDoneByDate.update(t.date, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  return weekStrs.map((day) {
    double xp = 0;
    if (prayerDates.contains(day)) xp += 15;
    if (bibleDates.contains(day)) xp += 20;
    if (skillMinByDate.containsKey(day)) xp += skillMinByDate[day]! * 5;
    if (fellowshipDates.contains(day)) xp += 10;
    final td = todoDoneByDate[day] ?? 0;
    if (td > 0) xp += td * XpService.todoComplete;
    return xp;
  }).toList();
});
