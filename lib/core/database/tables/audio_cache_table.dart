import 'package:drift/drift.dart';

class AudioCache extends Table {
  TextColumn get id => text()();

  TextColumn get bookId => text()();
  IntColumn get chapter => integer()();
  TextColumn get language => text()();

  TextColumn get localPath => text()();
  IntColumn get sizeBytes => integer()();

  DateTimeColumn get downloadedAt => dateTime()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get playCount => integer().withDefault(Constant(0))();

  BoolColumn get isPinned => boolean().withDefault(Constant(false))();

  DateTimeColumn get planRelevantUntil => dateTime().nullable()();

  TextColumn get status => text()(); // downloading | ready | failed

  @override
  Set<Column> get primaryKey => {id};


}
