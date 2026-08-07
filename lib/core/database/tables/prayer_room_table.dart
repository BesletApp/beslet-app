import 'package:drift/drift.dart';

/// A named place in the user's prayer life — a room, never a metric. The user
/// turns from the noise of the day into a quiet space (Matthew 6:6), gives it
/// a name, and returns to it. `lastEnteredAt` is a warmth signal: presence,
/// not a score — it lights a gentle dot, never a count.
class PrayerRooms extends Table {
  TextColumn get id => text()();

  /// The room's name, as the user wrote it ("For my brother", "Morning rest").
  TextColumn get name => text()();

  /// Soft grouping so the rooms can sit together calmly.
  /// One of: personal | intercession | struggle | family.
  TextColumn get group => text().withDefault(const Constant('personal'))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get createdAt => text()();

  /// The last moment the user entered this room. Present, never counted.
  TextColumn get lastEnteredAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
