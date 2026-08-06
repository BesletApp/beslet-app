import 'package:drift/drift.dart';

/// One row per memorized verse. The Word Challenge's memory: how far a single
/// verse has taken root (NEW → GROWING → ROOTED) and when it next deserves a
/// gentle review. A memory, never a score.
class VerseChallenges extends Table {
  /// Stable id derived from the reference, e.g. `galatians_5_22_23`.
  TextColumn get id => text()();
  TextColumn get reference => text()();
  TextColumn get textEn => text()();
  TextColumn get textAm => text().nullable()();
  IntColumn get masteryLevel => integer().withDefault(const Constant(0))();
  IntColumn get completions => integer().withDefault(const Constant(0))();
  TextColumn get lastCompletedDate => text().nullable()();
  TextColumn get userPrayer => text().nullable()();
  /// The next day this verse should be gently revisited (YYYY-MM-DD).
  TextColumn get nextReviewDate => text().nullable()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  TextColumn get chosenAct => text().nullable()();
  BoolColumn get actDone => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}
