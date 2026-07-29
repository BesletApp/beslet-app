import 'package:drift/drift.dart';

class PrayerLogs extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  IntColumn get minutes => integer()();
  TextColumn get note => text().nullable()();
  @override Set<Column> get primaryKey => {id};
}
