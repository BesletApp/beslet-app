import 'package:drift/drift.dart';

class DailyReflections extends Table {
  TextColumn get id => text()();
  TextColumn get date => text().unique()();
  TextColumn get content => text()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
