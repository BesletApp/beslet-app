import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final todayFellowshipProvider = FutureProvider<FellowshipLog?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final logs = await (db.select(db.fellowshipLogs)..where((t) => t.date.equals(today))).get();
  return logs.isNotEmpty ? logs.first : null;
});

final weeklyFellowshipCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final weekAgo = today.subtract(const Duration(days: 6)).toIso8601String().substring(0, 10);
  final logs = await db.select(db.fellowshipLogs).get();
  return logs.where((l) => l.date.compareTo(weekAgo) >= 0).length;
});

class FellowshipNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> logConnection({String? contactName, String? note}) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.fellowshipLogs)..where((t) => t.date.equals(today))).get();
    if (existing.isNotEmpty) {
      await (db.update(db.fellowshipLogs)..where((t) => t.date.equals(today)))
          .write(FellowshipLogsCompanion(contactName: Value(contactName), note: Value(note)));
    } else {
      await db.into(db.fellowshipLogs).insert(FellowshipLogsCompanion.insert(
        id: const Uuid().v4(), date: today, contactName: Value<String?>(contactName), note: Value<String?>(note), createdAt: DateTime.now().toIso8601String(),
      ));
    }
    ref.invalidate(todayFellowshipProvider);
    ref.invalidate(weeklyFellowshipCountProvider);
    ref.invalidate(trackingDataProvider);
  }

  Future<void> removeToday() async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await (db.delete(db.fellowshipLogs)..where((t) => t.date.equals(today))).go();
    ref.invalidate(todayFellowshipProvider);
    ref.invalidate(weeklyFellowshipCountProvider);
    ref.invalidate(trackingDataProvider);
  }
}

final fellowshipNotifierProvider = AsyncNotifierProvider<FellowshipNotifier, void>(FellowshipNotifier.new);
