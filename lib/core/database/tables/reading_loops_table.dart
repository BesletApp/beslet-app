import 'package:drift/drift.dart';

class ReadingLoops extends Table {
  TextColumn get id => text()();
  TextColumn get planId => text()();
  IntColumn get duration => integer()();
  IntColumn get startChapter => integer()();
  TextColumn get startDate => text()();
  TextColumn get status => text()();
  IntColumn get loopNumber => integer()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
