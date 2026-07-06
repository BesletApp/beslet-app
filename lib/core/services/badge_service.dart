class BadgeService {
  static List<Map<String, dynamic>> checkBadges(int xp, int streak, int prayerMinutes, int bibleDays, {int todosCompleted = 0, int unifiedStreak = 0}) {
    final earned = <Map<String, dynamic>>[];
    if (xp >= 10) earned.add(_badge('first_step', 'First Step', '🌱', 'Complete your first habit'));
    if (streak >= 7) earned.add(_badge('week_streak', 'Faithful Week', '🔥', '7-day streak'));
    if (streak >= 30) earned.add(_badge('month_streak', 'Discipline', '👑', '30-day streak'));
    if (prayerMinutes >= 100) earned.add(_badge('prayer_warrior', 'Prayer Warrior', '🙏', '100 prayer minutes'));
    if (bibleDays >= 7) earned.add(_badge('bible_week', 'Scripture Scholar', '📖', '7 days of Bible reading'));
    if (xp >= 600) earned.add(_badge('mature', 'Maturity', '✨', 'Reach Mature level'));
    if (xp >= 1000) earned.add(_badge('leader', 'Leader', '👑', 'Reach Leader level'));
    if (todosCompleted >= 1) earned.add(_badge('first_task', 'First Task', '✅', 'Complete your first task'));
    if (todosCompleted >= 30) earned.add(_badge('planner', 'Planner', '📋', 'Complete 30 tasks'));
    if (todosCompleted >= 100) earned.add(_badge('finisher', 'Finisher', '🏆', 'Complete 100 tasks'));
    if (unifiedStreak >= 14) earned.add(_badge('fortnight_faithful', 'Fortnight Faithful', '🕊️', '14-day prayer/Bible streak — "Draw near to God" (James 4:8)'));
    if (unifiedStreak >= 50) earned.add(_badge('jubilee', 'Jubilee', '🎉', '50-day streak — "Proclaim liberty" (Leviticus 25:10)'));
    if (unifiedStreak >= 90) earned.add(_badge('ninety_strong', 'Ninety Strong', '💪', '90-day streak — "Be strong in the Lord" (Ephesians 6:10)'));
    if (unifiedStreak >= 180) earned.add(_badge('half_year', 'Half-Year', '🌟', '180-day streak — "Let your light shine" (Matthew 5:16)'));
    if (unifiedStreak >= 365) earned.add(_badge('year_of_faith', 'Year of Faith', '🏅', '365-day streak — "Faithful until death" (Revelation 2:10)'));
    return earned;
  }
  static Map<String, dynamic> _badge(String id, String name, String icon, String desc) => {'id': id, 'name': name, 'icon': icon, 'description': desc};
}
