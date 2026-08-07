import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

/// The soft groupings a room can live in. Not filters — just gentle neighbors
/// so the rooms sit together calmly.
class PrayerRoomGroup {
  static const String personal = 'personal';
  static const String intercession = 'intercession';
  static const String struggle = 'struggle';
  static const String family = 'family';
  static const List<String> all = [personal, intercession, struggle, family];
}

/// The rooms a first-time visitor finds already open: the three classic
/// postures of prayer, carried over from the old guided prompts.
const List<({String name, String group})> _seedRooms = [
  (name: 'Thank', group: PrayerRoomGroup.personal),
  (name: 'Ask', group: PrayerRoomGroup.personal),
  (name: 'Rest', group: PrayerRoomGroup.personal),
];

/// The user's rooms, kept in the order they arranged them. Seeded on first
/// sight so the room is never empty and a new visitor always has a place.
final prayerRoomsProvider = FutureProvider<List<PrayerRoom>>((ref) async {
  final db = ref.watch(databaseProvider);
  final existing = await (db.select(db.prayerRooms)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();
  if (existing.isNotEmpty) return existing;

  final now = DateTime.now().toIso8601String();
  for (var i = 0; i < _seedRooms.length; i++) {
    await db.into(db.prayerRooms).insert(PrayerRoomsCompanion.insert(
          id: const Uuid().v4(),
          name: _seedRooms[i].name,
          group: Value(_seedRooms[i].group),
          sortOrder: Value(i),
          createdAt: now,
        ));
  }
  return (db.select(db.prayerRooms)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
      .get();
});

class PrayerRoomNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> addRoom(String name, String group) async {
    final db = ref.read(databaseProvider);
    final rows = await db.select(db.prayerRooms).get();
    final nextOrder = rows.isEmpty
        ? 0
        : rows.map((r) => r.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
    await db.into(db.prayerRooms).insert(PrayerRoomsCompanion.insert(
          id: const Uuid().v4(),
          name: name.trim(),
          group: Value(group),
          sortOrder: Value(nextOrder),
          createdAt: DateTime.now().toIso8601String(),
        ));
    ref.invalidate(prayerRoomsProvider);
  }

  Future<void> renameRoom(String id, String name) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.prayerRooms)..where((t) => t.id.equals(id)))
        .write(PrayerRoomsCompanion(name: Value(name.trim())));
    ref.invalidate(prayerRoomsProvider);
  }

  Future<void> moveRoom(String id, String group) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.prayerRooms)..where((t) => t.id.equals(id)))
        .write(PrayerRoomsCompanion(group: Value(group)));
    ref.invalidate(prayerRoomsProvider);
  }

  Future<void> deleteRoom(String id) async {
    final db = ref.read(databaseProvider);
    await (db.delete(db.prayerRooms)..where((t) => t.id.equals(id))).go();
    ref.invalidate(prayerRoomsProvider);
  }

  /// Marks that the user stepped into this room — a warmth signal for the
  /// gentle dot on the tile. Presence, never a count.
  Future<void> touchRoom(String id) async {
    final db = ref.read(databaseProvider);
    await (db.update(db.prayerRooms)..where((t) => t.id.equals(id)))
        .write(PrayerRoomsCompanion(
            lastEnteredAt: Value(DateTime.now().toIso8601String())));
    ref.invalidate(prayerRoomsProvider);
  }
}

final prayerRoomNotifierProvider =
    AsyncNotifierProvider<PrayerRoomNotifier, void>(PrayerRoomNotifier.new);
