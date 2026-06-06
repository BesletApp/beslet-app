class PillarStats {
  final int spiritualDays;
  final int skillMinutes;
  final int fellowshipLogs;
  final int familyMinutes;
  const PillarStats({this.spiritualDays=0,this.skillMinutes=0,this.fellowshipLogs=0,this.familyMinutes=0});
}

class UserProfile {
  final String displayName;
  final DateTime joinedAt;
  final String preferredLanguage;
  final int currentStreak;
  final int totalDaysActive;
  final int currentDay;
  final int currentPhase;
  final int level;
  final String growthLevel;
  final int xp;
  final PillarStats pillars;
  const UserProfile({
    required this.displayName,required this.joinedAt,required this.preferredLanguage,
    required this.currentStreak,required this.totalDaysActive,required this.currentDay,
    required this.currentPhase,required this.level,required this.growthLevel,required this.xp,required this.pillars,
  });
}

abstract class StreakCalculator {
  int calculate(List<String> dates);
}

class DefaultStreakCalculator implements StreakCalculator {
  int calculate(List<String> dates) {
    if (dates.isEmpty) return 0;
    final sorted = dates.toSet().toList()..sort();
    final today = DateTime.now();
    final todayStr = _fmt(today);
    int streak = 0;
    var check = today;
    if (!sorted.contains(todayStr)) check = check.subtract(const Duration(days: 1));
    while (sorted.contains(_fmt(check))) { streak++; check = check.subtract(const Duration(days: 1)); }
    return streak;
  }
  String _fmt(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}
