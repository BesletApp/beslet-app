import 'package:drift/drift.dart';

/// The user's current journey — their own declared intention and timeframe.
/// A single active commitment; older rows are kept as journey memory, never
/// as a tracking record.
class GrowthJourney extends Table {
  TextColumn get id => text()();
  TextColumn get intention => text()();
  IntColumn get timeframeDays => integer().nullable()();
  TextColumn get startDate => text()();
  TextColumn get note => text().nullable()();
  BoolColumn get harvested => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text()();
  @override
  Set<Column> get primaryKey => {id};
}
