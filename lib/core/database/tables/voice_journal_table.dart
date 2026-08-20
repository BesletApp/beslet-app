import 'package:drift/drift.dart';

class VoiceJournal extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get locale => text()();
  TextColumn get rawTranscript => text()();
  TextColumn get organizedContent => text().nullable()();
  TextColumn get status => text()();
  TextColumn get errorReason => text().nullable()();
  BoolColumn get savedToJournal => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  @override Set<Column> get primaryKey => {id};
}