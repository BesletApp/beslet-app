import 'package:drift/drift.dart';

/// A quiet record of the days the user spent in the Word. Feeds the Growth
/// Zone's "Word" step and the vine's leaf-glow — a memory, never a score.
class ReadingSessions extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  IntColumn get minutes => integer().withDefault(const Constant(0))();
  TextColumn get bookId => text().nullable()();
  IntColumn get chapter => integer().nullable()();
  TextColumn get createdAt => text()();
  @override
  Set<Column> get primaryKey => {id};
}
