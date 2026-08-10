import 'package:drift/drift.dart';

/// One quiet moment shown to the user. Minimal and non-personal: which moment,
/// which mode, which engine, which day. Used only by the boundary gate to keep
/// dependence low — never read as text, never sent anywhere.
class AiMoments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get dayKey => text()(); // local yyyy-MM-dd
  TextColumn get type => text()(); // AiMomentType name
  TextColumn get mode => text()(); // AiMode name
  TextColumn get source => text()(); // AiSource name
  TextColumn get reference => text().nullable()();
  TextColumn get itemId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
}
