import 'package:drift/drift.dart';

class TodoItems extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get date => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get completedAt => text().nullable()();
  BoolColumn get isSkipped => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
