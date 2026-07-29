import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final allSkillsProvider = FutureProvider<List<Skill>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.skills).get();
});

final todaySkillMinutesProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final sessions = await (db.select(db.skillSessions)..where((t) => t.date.equals(today))).get();
  int total = 0;
  for (final s in sessions) { total += s.minutes; }
  return total;
});

class SkillsNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> addSkill(String name, String category, String icon, {int targetMinutes = 30}) async {
    final db = ref.read(databaseProvider);
    await db.into(db.skills).insert(SkillsCompanion.insert(
      id: const Uuid().v4(), name: name, category: category, icon: icon,
      targetMinutes: Value(targetMinutes),
      createdAt: DateTime.now().toIso8601String(),
    ));
    ref.invalidate(allSkillsProvider);
    ref.invalidate(trackingDataProvider);
  }

  Future<void> logSession(String skillId, int minutes) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await db.into(db.skillSessions).insert(SkillSessionsCompanion.insert(
      skillId: skillId, date: today, minutes: minutes,
    ));
    ref.invalidate(allSkillsProvider);
    ref.invalidate(todaySkillMinutesProvider);
    ref.invalidate(trackingDataProvider);
  }

  Future<void> deleteSkill(String skillId) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.skillSessions)..where((t) => t.skillId.equals(skillId))).go();
    await (db.delete(db.skills)..where((t) => t.id.equals(skillId))).go();
    ref.invalidate(allSkillsProvider);
    ref.invalidate(trackingDataProvider);
  }
}

final skillsNotifierProvider = AsyncNotifierProvider<SkillsNotifier, void>(SkillsNotifier.new);
