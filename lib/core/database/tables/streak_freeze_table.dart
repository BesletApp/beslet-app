import 'package:drift/drift.dart';

class StreakFrozen extends Table {
  TextColumn get id => text()();
  IntColumn get count => integer()();
  IntColumn get bestStreak => integer()();
  TextColumn get lastAnchorDate => text().nullable()();
  TextColumn get brokenDate => text().nullable()();
  IntColumn get freezesEarned => integer()();
  @override Set<Column> get primaryKey => {id};
}
