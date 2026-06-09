class StreakService {
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
