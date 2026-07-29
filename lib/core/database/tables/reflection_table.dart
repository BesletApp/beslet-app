import 'package:drift/drift.dart';

class Reflections extends Table {
  TextColumn get id => text()();
  TextColumn get weekStart => text().unique()();
  TextColumn get grew => text().nullable()();
  TextColumn get slipped => text().nullable()();
  TextColumn get nextFocus => text().nullable()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
