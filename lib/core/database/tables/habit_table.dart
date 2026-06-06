import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  TextColumn get frequency => text()();
  TextColumn get icon => text()();
  IntColumn get targetCount => integer().withDefault(const Constant(1))();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
