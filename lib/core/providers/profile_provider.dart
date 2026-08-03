import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import 'user_provider.dart';
import 'tracking_provider.dart';
import 'database_provider.dart';
import '../services/summer_service.dart';

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final user = await ref.watch(userProvider.future);
  final track = await ref.watch(trackingDataProvider.future);

  final joinedAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
  final currentDay = (DateTime.now().difference(SummerService.summerStart).inDays)
      .clamp(0, 89) + 1;
  final currentPhase = currentDay <= 22 ? 1 : (currentDay <= 44 ? 2 : (currentDay <= 66 ? 3 : 4));

  final levelNames = ['Seed','Sprout','Branch','Tree','Fruitful'];
  final lvlIdx = track.level.clamp(0, 4);
  final growthLevel = levelNames[lvlIdx];

  final db = ref.watch(databaseProvider);
  final allSkills = await db.select(db.skillSessions).get();
  final skillMinutes = allSkills.fold(0, (int s, r) => s + r.minutes);

  final fellow = await db.select(db.fellowshipLogs).get();
  final todos = await db.select(db.todoItems).get();
  final todosCompleted = todos.where((t) => t.isCompleted).length;

  return UserProfile(
    displayName: user.name,
    joinedAt: joinedAt,
    preferredLanguage: user.lang,
    currentStreak: track.streak,
    currentDay: currentDay,
    currentPhase: currentPhase,
    level: track.level,
    growthLevel: growthLevel,
    xp: track.totalXp,
    totalXp: track.totalXp,
    badges: track.badges,
    pillars: PillarStats(
      skillMinutes: skillMinutes,
      fellowshipLogs: fellow.length,
      todosCompleted: todosCompleted,
    ),
  );
});
