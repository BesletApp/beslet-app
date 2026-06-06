import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'user_provider.dart';
import 'tracking_provider.dart';
import 'database_provider.dart';

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final user = await ref.watch(userProvider.future);
  final track = await ref.watch(trackingDataProvider.future);
  final db = ref.watch(databaseProvider);

  final allBibleReads = await db.select(db.bibleReads).get();
  final totalDaysActive = allBibleReads.length;
  final currentDay = (totalDaysActive % 90).clamp(1, 90);
  final currentPhase = currentDay <= 30 ? 1 : (currentDay <= 60 ? 2 : 3);

  final levelNames = ['Seed','Sprout','Branch','Tree','Fruitful'];
  final lvlIdx = track.level.clamp(0, 4);
  final growthLevel = levelNames[lvlIdx];

  final allSkills = await db.select(db.skillSessions).get();
  final skillMinutes = allSkills.fold(0, (int s, r) => s + r.minutes);

  final fellow = await db.select(db.fellowshipLogs).get();
  final family = await db.select(db.familyTimeLogs).get();
  final familyMinutes = (family.fold(0.0, (double s, r) => s + r.hours) * 60).round();

  return UserProfile(
    displayName: user.name,
    joinedAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
    preferredLanguage: user.lang,
    currentStreak: track.streak,
    totalDaysActive: totalDaysActive,
    currentDay: currentDay,
    currentPhase: currentPhase,
    level: track.level,
    growthLevel: growthLevel,
    xp: track.totalXp,
    pillars: PillarStats(
      spiritualDays: totalDaysActive,
      skillMinutes: skillMinutes,
      fellowshipLogs: fellow.length,
      familyMinutes: familyMinutes,
    ),
  );
});
