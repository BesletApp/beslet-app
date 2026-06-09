import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/user_table.dart';
import 'tables/habit_table.dart';
import 'tables/completion_table.dart';
import 'tables/prayer_table.dart';
import 'tables/bible_read_table.dart';
import 'tables/skill_table.dart';
import 'tables/reflection_table.dart';
import 'tables/challenge_table.dart';
import 'tables/fellowship_table.dart';
import 'tables/family_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Users, Habits, Completions, PrayerLogs, BibleReads, Skills, SkillSessions, Reflections, Challenges, ChallengeParticipants, FellowshipLogs, FamilyTimeLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(fellowshipLogs);
          await m.createTable(familyTimeLogs);
        }
        if (from < 3) {
          await m.addColumn(bibleReads, bibleReads.note);
        }
        if (from < 4) {
          await m.addColumn(users, users.biblePlan);
        }
        if (from < 5) {
          await m.addColumn(bibleReads, bibleReads.durationMinutes);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'beslet.sqlite'));
    return NativeDatabase(file);
  });
}
