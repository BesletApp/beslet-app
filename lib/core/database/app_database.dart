import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/wisdom_notes_table.dart';
import 'tables/audio_cache_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [WisdomNotes, AudioCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  @override int get schemaVersion => 17;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 17) {
          for (final table in [
            'users', 'habits', 'completions', 'prayer_logs',
            'bible_reads', 'skills', 'skill_sessions', 'reflections',
            'challenges', 'challenge_participants', 'fellowship_logs',
            'family_time_logs', 'goals', 'todo_items', 'daily_reflections',
            'streak_log', 'streak_frozen', 'soul_log', 'bible_sessions',
            'reading_loops', 'bible_book_cache',
          ]) {
            await customStatement('DROP TABLE IF EXISTS $table');
          }
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
