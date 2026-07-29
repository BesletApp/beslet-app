import 'package:drift/drift.dart';

class StreakLog extends Table {
  TextColumn get id => text()();
  TextColumn get date => text().unique()();
  BoolColumn get counted => boolean()();
  BoolColumn get freezeUsed => boolean()();
  TextColumn get anchorType => text()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
