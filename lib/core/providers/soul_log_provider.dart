import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final todaySoulLogProvider = FutureProvider<SoulLogData?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final logs = await (db.select(db.soulLog)..where((t) => t.date.equals(today))).get();
  return logs.isNotEmpty ? logs.first : null;
});

final allSoulLogsProvider = FutureProvider<List<SoulLogData>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.soulLog)
    ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)])
  ).get();
});

class SoulLogNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> logCheckIn(int mood, {String? note}) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.soulLog)..where((t) => t.date.equals(today))).get();
    if (existing.isNotEmpty) {
      await (db.update(db.soulLog)..where((t) => t.date.equals(today)))
          .write(SoulLogCompanion(mood: Value(mood), note: Value<String?>(note)));
    } else {
      await db.into(db.soulLog).insert(SoulLogCompanion.insert(
        id: const Uuid().v4(), date: today, mood: mood,
        createdAt: DateTime.now().toIso8601String(),
        note: Value<String?>(note),
      ));
    }
    ref.invalidate(todaySoulLogProvider);
    ref.invalidate(allSoulLogsProvider);
  }
}

final soulLogNotifierProvider = AsyncNotifierProvider<SoulLogNotifier, void>(SoulLogNotifier.new);
