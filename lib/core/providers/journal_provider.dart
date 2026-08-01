import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final journalEntryProvider = FutureProvider<JournalEntryData?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final rows = await (db.select(db.journalEntry)..where((e) => e.date.equals(today))).get();
  return rows.isEmpty ? null : rows.first;
});

final journalHistoryProvider = FutureProvider<List<JournalEntryData>>((ref) async {
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.journalEntry)
    ..orderBy([(e) => OrderingTerm(expression: e.date, mode: OrderingMode.desc)])
  ).get();
  return rows.where((e) => e.content?.trim().isNotEmpty == true).toList();
});

class JournalNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> saveEntry(String content) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.journalEntry)..where((e) => e.date.equals(today))).get();
    if (existing.isEmpty) {
      await db.into(db.journalEntry).insert(JournalEntryCompanion.insert(
        id: const Uuid().v4(),
        date: today,
        content: Value(content.trim().isEmpty ? null : content.trim()),
        createdAt: DateTime.now().toIso8601String(),
      ));
    } else {
      await (db.update(db.journalEntry)..where((e) => e.date.equals(today))).write(
        JournalEntryCompanion(
          content: Value(content.trim().isEmpty ? null : content.trim()),
        ),
      );
    }
    ref.invalidate(journalEntryProvider);
    ref.invalidate(journalHistoryProvider);
  }
}

final journalNotifierProvider = AsyncNotifierProvider<JournalNotifier, void>(JournalNotifier.new);
