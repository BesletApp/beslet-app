import 'package:drift/drift.dart';

class BibleBookCache extends Table {
  TextColumn get bookId => text()();
  TextColumn get jsonData => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {bookId};
}
