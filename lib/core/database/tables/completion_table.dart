import 'package:drift/drift.dart';
import 'habit_table.dart';

class Completions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get habitId => text().references(Habits, #id)();
  TextColumn get date => text()();
  Set<Column> get uniqueKey => {habitId, date};
}
