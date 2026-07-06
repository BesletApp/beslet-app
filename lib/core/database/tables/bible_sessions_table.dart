import 'package:drift/drift.dart';

class BibleSessions extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get bookId => text()();
  IntColumn get chapterStart => integer()();
  IntColumn get chapterEnd => integer()();
  IntColumn get durationMinutes => integer().withDefault(const Constant(0))();
  TextColumn get reflection => text().nullable()();
  BoolColumn get isPlanReading => boolean().withDefault(const Constant(false))();
  TextColumn get planDay => text().nullable()();
  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
