import 'package:drift/drift.dart';

class AudioCache extends Table {
  TextColumn get id => text()();

  TextColumn get bookId => text()();
  IntColumn get chapter => integer()();
  TextColumn get language => text()();

  TextColumn get localPath => text()();
  IntColumn get sizeBytes => integer()();

  DateTimeColumn get downloadedAt => dateTime()();

  BoolColumn get isPinned => boolean().withDefault(Constant(false))();

  TextColumn get status => text()(); // downloading | ready | failed

  @override
  Set<Column> get primaryKey => {id};


}
