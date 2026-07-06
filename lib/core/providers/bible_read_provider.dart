import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';
import 'streak_provider.dart';

final todayBibleReadProvider = FutureProvider<BibleRead?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final reads = await (db.select(db.bibleReads)..where((t) => t.date.equals(today))).get();
  return reads.isNotEmpty ? reads.first : null;
});

final bibleStreakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final cutoff = DateTime.now().subtract(const Duration(days: 365)).toIso8601String().substring(0, 10);
  final reads = await db.select(db.bibleReads).get();
  final dates = reads.where((r) => r.date.compareTo(cutoff) >= 0).map((r) => r.date).toSet().toList()..sort();
  int streak = 0;
  final now = DateTime.now();
  for (int i = dates.length - 1; i >= 0; i--) {
    final expected = now.subtract(Duration(days: streak)).toIso8601String().substring(0, 10);
    if (dates[i] == expected) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

final bibleReadDaysProvider = FutureProvider<Set<int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final prefix = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final reads = await db.select(db.bibleReads).get();
  return reads
    .where((r) => r.date.startsWith(prefix))
    .map((r) => int.tryParse(r.date.split('-')[2]) ?? 0)
    .toSet();
});

class BibleNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> markAsRead(String reference, {String? note}) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.bibleReads)..where((t) => t.date.equals(today))).get();
    if (existing.isEmpty) {
      await db.into(db.bibleReads).insert(BibleReadsCompanion.insert(
        date: today,
        reference: reference,
        note: Value(note),
        durationMinutes: const Value(10),
      ));
    }
    ref.invalidate(todayBibleReadProvider);
    ref.invalidate(bibleStreakProvider);
    ref.invalidate(bibleReadDaysProvider);
    ref.invalidate(trackingDataProvider);
    ref.invalidate(streakStateProvider);
    ref.invalidate(streakLogsProvider);
    ref.invalidate(streakWeekDataProvider);
  }
}

final bibleNotifierProvider = AsyncNotifierProvider<BibleNotifier, void>(BibleNotifier.new);
