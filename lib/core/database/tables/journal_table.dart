import 'package:drift/drift.dart';

class JournalEntry extends Table {
  TextColumn get id => text()();
  TextColumn get date => text().unique()();
  TextColumn get content => text().nullable()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
