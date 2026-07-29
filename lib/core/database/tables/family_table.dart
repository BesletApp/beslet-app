import 'package:drift/drift.dart';

class FamilyTimeLogs extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  RealColumn get hours => real()();
  TextColumn get note => text().nullable()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
