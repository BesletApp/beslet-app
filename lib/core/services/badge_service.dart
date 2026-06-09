class BadgeService {
  static List<Map<String, dynamic>> checkBadges(int xp, int streak, int prayerMinutes, int bibleDays) {
    final earned = <Map<String, dynamic>>[];
    if (xp >= 10) earned.add(_badge('first_step', 'First Step', '🌱', 'Complete your first habit'));
    if (streak >= 7) earned.add(_badge('week_streak', 'Faithful Week', '🔥', '7-day streak'));
    if (streak >= 30) earned.add(_badge('month_streak', 'Discipline', '👑', '30-day streak'));
    if (prayerMinutes >= 100) earned.add(_badge('prayer_warrior', 'Prayer Warrior', '🙏', '100 prayer minutes'));
    if (bibleDays >= 7) earned.add(_badge('bible_week', 'Scripture Scholar', '📖', '7 days of Bible reading'));
    if (xp >= 600) earned.add(_badge('mature', 'Maturity', '✨', 'Reach Mature level'));
    if (xp >= 1000) earned.add(_badge('leader', 'Leader', '👑', 'Reach Leader level'));
    return earned;
  }
  static Map<String, dynamic> _badge(String id, String name, String icon, String desc) => {'id': id, 'name': name, 'icon': icon, 'description': desc};
}
