import 'package:drift/drift.dart';

class SoulLog extends Table {
  TextColumn get id => text()();
  TextColumn get date => text().unique()();
  IntColumn get mood => integer()(); // 1-5
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
