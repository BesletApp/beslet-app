import 'package:drift/drift.dart';

/// One row per calendar day — the living garden's memory. The discipline logs
/// elsewhere only know *which* day something happened; this table remembers
/// *when*, so the vine can keep living (and gently fading) even between
/// visits. A memory, never a score.
class VineDay extends Table {
  /// Calendar day, YYYY-MM-DD.
  TextColumn get date => text()();

  /// The moment the user prayed — water for the vine.
  TextColumn get prayerAt => text().nullable()();

  /// The moment the user last opened the Word — light for the leaves.
  TextColumn get readingAt => text().nullable()();

  /// The moment the user reached out in fellowship — warmth for the branches.
  TextColumn get fellowshipAt => text().nullable()();

  /// The last time the Growth Zone was opened. Presence, not merit — this is
  /// what lets the garden feel missing the user and rejoice on return.
  TextColumn get lastVisitAt => text().nullable()();

  /// How many transcendence moments were played that day.
  IntColumn get momentsPlayed => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {date};
}
