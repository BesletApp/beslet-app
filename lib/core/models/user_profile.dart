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
