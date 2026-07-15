import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import '../database/app_database.dart';
import 'database_provider.dart';

final wisdomNotesProvider = FutureProvider<Map<String, String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final notes = await db.select(db.wisdomNotes).get();
  final map = <String, String>{};
  for (final n in notes) {
    map[n.bookId] = n.note;
  }
  return map;
});

final wisdomForBookProvider = FutureProvider.family<String?, String>((ref, bookId) async {
  final db = ref.watch(databaseProvider);
  final notes = await (db.select(db.wisdomNotes)..where((t) => t.bookId.equals(bookId))).get();
  return notes.isNotEmpty ? notes.first.note : null;
});

class WisdomNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> saveWisdom(String bookId, String note) async {
    final db = ref.read(databaseProvider);
    final existing = await (db.select(db.wisdomNotes)..where((t) => t.bookId.equals(bookId))).get();
    if (existing.isNotEmpty) {
      await (db.update(db.wisdomNotes)..where((t) => t.bookId.equals(bookId)))
          .write(WisdomNotesCompanion(note: Value(note)));
    } else {
      await db.into(db.wisdomNotes).insert(WisdomNotesCompanion.insert(
        id: const Uuid().v4(), bookId: bookId, note: note, createdAt: DateTime.now().toIso8601String(),
      ));
    }
    ref.invalidate(wisdomNotesProvider);
    ref.invalidate(wisdomForBookProvider(bookId));
  }
}

final wisdomNotifierProvider = AsyncNotifierProvider<WisdomNotifier, void>(WisdomNotifier.new);
