import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/user_table.dart';
import 'tables/habit_table.dart';
import 'tables/completion_table.dart';
import 'tables/prayer_table.dart';
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
import 'tables/audio_cache_table.dart';
import 'tables/journal_table.dart';
import 'tables/growth_journey_table.dart';
import 'tables/reading_session_table.dart';
import 'tables/vine_day_table.dart';
import 'tables/verse_challenge_table.dart';
import 'tables/ai_moment_table.dart';
import 'tables/voice_journal_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Users, Habits, Completions, PrayerLogs, Skills, SkillSessions, Reflections, Challenges, ChallengeParticipants, FellowshipLogs, FamilyTimeLogs, Goals, TodoItems, DailyReflections, StreakLog, StreakFrozen, SoulLog, AudioCache, JournalEntry, GrowthJourney, ReadingSessions, VineDay, VerseChallenges, AiMoments, VoiceJournal])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @visibleForTesting
  AppDatabase.forTesting(super.executor);
  @override int get schemaVersion => 29;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.createTable(fellowshipLogs);
          await m.createTable(familyTimeLogs);
        }
        if (from < 4) {
          await m.addColumn(users, users.biblePlan);
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
        if (from < 11) {
          await m.addColumn(users, users.sabbathDay);
        }
        if (from < 12) {
          await m.createTable(soulLog);
        }
        if (from < 14) {
          await m.addColumn(fellowshipLogs, fellowshipLogs.promptType);
        }
        if (from < 17) {
          await m.createTable(journalEntry);
        }
        if (from < 18) {
          await customStatement('DROP TABLE IF EXISTS bible_reads');
          await customStatement('DROP TABLE IF EXISTS bible_sessions');
          await customStatement('DROP TABLE IF EXISTS reading_loops');
          await customStatement('DROP TABLE IF EXISTS wisdom_notes');
          await customStatement('DROP TABLE IF EXISTS bible_book_cache');
          final audioCols = await customSelect('PRAGMA table_info(audio_cache)').get();
          if (audioCols.isEmpty) {
            await m.createTable(audioCache);
          } else {
            final names = audioCols.map((c) => c.data['name'] as String).toSet();
            if (names.contains('last_played_at')) {
              await customStatement('ALTER TABLE audio_cache DROP COLUMN last_played_at');
            }
            if (names.contains('play_count')) {
              await customStatement('ALTER TABLE audio_cache DROP COLUMN play_count');
            }
            if (names.contains('plan_relevant_until')) {
              await customStatement('ALTER TABLE audio_cache DROP COLUMN plan_relevant_until');
            }
          }
        }
        if (from < 19) {
          await m.createTable(growthJourney);
        }
        if (from < 20) {
          await m.createTable(readingSessions);
        }
        if (from < 21) {
          await m.createTable(vineDay);
        }
        if (from < 22) {
          await m.addColumn(readingSessions, readingSessions.completed);
          await m.addColumn(readingSessions, readingSessions.completedAt);
        }
        if (from < 23) {
          await m.createTable(verseChallenges);
        }
        if (from < 24) {
          await m.addColumn(users, users.keptWord);
          await m.addColumn(users, users.keptWordRef);
          await m.addColumn(users, users.avatarColor);
        }
        if (from < 26) {
          await customStatement('DROP TABLE IF EXISTS prayer_rooms');
        }
        if (from < 27) {
          await m.addColumn(users, users.gender);
          await m.addColumn(users, users.spiritualIntent);
        }
        if (from < 28) {
          await m.createTable(aiMoments);
        }
        if (from < 29) {
          await m.createTable(voiceJournal);
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
