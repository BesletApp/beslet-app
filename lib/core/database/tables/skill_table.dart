import 'package:drift/drift.dart';

class Skills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get icon => text()();
  IntColumn get targetMinutes => integer().withDefault(const Constant(30))();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}

class SkillSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get skillId => text().references(Skills, #id)();
  TextColumn get date => text()();
  IntColumn get minutes => integer()();
  TextColumn get note => text().nullable()();
}
