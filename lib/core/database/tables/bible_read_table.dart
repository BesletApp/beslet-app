import 'package:drift/drift.dart';

class BibleReads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get reference => text()();
  TextColumn get note => text().nullable()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(10))();
}
