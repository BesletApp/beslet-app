import 'package:drift/drift.dart';

class FellowshipLogs extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get contactName => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
