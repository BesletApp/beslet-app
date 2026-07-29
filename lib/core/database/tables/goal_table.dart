import 'package:drift/drift.dart';

class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  TextColumn get periodStart => text()();
  BoolColumn get isAchieved => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
