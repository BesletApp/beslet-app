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
import 'tables/goal_table.dart';
import 'tables/todo_table.dart';
import 'tables/daily_reflection_table.dart';
import 'tables/streak_log_table.dart';
import 'tables/streak_freeze_table.dart';
import 'tables/soul_log_table.dart';
import 'tables/bible_sessions_table.dart';
import 'tables/reading_loops_table.dart';
import 'tables/wisdom_notes_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Users, Habits, Completions, PrayerLogs, BibleReads, Skills, SkillSessions, Reflections, Challenges, ChallengeParticipants, FellowshipLogs, FamilyTimeLogs, Goals, TodoItems, DailyReflections, StreakLog, StreakFrozen, SoulLog, BibleSessions, ReadingLoops, WisdomNotes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override int get schemaVersion => 14;

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
        if (from < 6) {
          await m.createTable(goals);
          await m.createTable(todoItems);
        }
        if (from < 7) {
          await m.createTable(dailyReflections);
        }
        if (from < 8) {
          await m.createTable(streakLog);
          await m.createTable(streakFrozen);
        }
        if (from < 9) {
          await m.createTable(bibleSessions);
          await customStatement('CREATE TABLE IF NOT EXISTS bible_book_cache (book_id TEXT PRIMARY KEY, json_data TEXT NOT NULL, cached_at TEXT NOT NULL)');
        }
        if (from < 10) {
          await customStatement('DROP TABLE IF EXISTS bible_book_cache');
        }
        if (from < 11) {
          await m.addColumn(users, users.sabbathDay);
        }
        if (from < 12) {
          await m.createTable(soulLog);
        }
        if (from < 13) {
          await m.createTable(readingLoops);
        }
        if (from < 14) {
          await m.addColumn(fellowshipLogs, fellowshipLogs.promptType);
          await m.createTable(wisdomNotes);
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
