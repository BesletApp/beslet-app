import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get name => text().withDefault(const Constant('Friend'))();
  TextColumn get goals => text().withDefault(const Constant('[]'))();
  BoolColumn get onboarded => boolean().withDefault(const Constant(false))();
  TextColumn get lang => text().withDefault(const Constant('en'))();
  TextColumn get biblePlan => text().withDefault(const Constant('nt'))();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
