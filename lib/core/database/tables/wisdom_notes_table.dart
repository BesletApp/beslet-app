import 'package:drift/drift.dart';

class WisdomNotes extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get note => text()();
  TextColumn get createdAt => text()();
  @override Set<Column> get primaryKey => {id};
}
