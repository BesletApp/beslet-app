import 'package:drift/drift.dart';

class FellowshipLogs extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get contactName => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
  IntColumn get promptType => integer().withDefault(const Constant(-1))();
  @override Set<Column> get primaryKey => {id};
}
