import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';

final todayFamilyProvider = FutureProvider<FamilyTimeLog?>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now().toIso8601String().substring(0, 10);
  final logs = await (db.select(db.familyTimeLogs)..where((t) => t.date.equals(today))).get();
  return logs.isNotEmpty ? logs.first : null;
});

final weeklyFamilyHoursProvider = FutureProvider<double>((ref) async {
  final db = ref.watch(databaseProvider);
  final today = DateTime.now();
  final weekAgo = today.subtract(const Duration(days: 6)).toIso8601String().substring(0, 10);
  final logs = await db.select(db.familyTimeLogs).get();
  return logs.where((l) => l.date.compareTo(weekAgo) >= 0).fold<double>(0, (sum, l) => sum + l.hours);
});

class FamilyNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> logTime(double hours, {String? note}) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await (db.select(db.familyTimeLogs)..where((t) => t.date.equals(today))).get();
    if (existing.isNotEmpty) {
      await (db.update(db.familyTimeLogs)..where((t) => t.date.equals(today)))
          .write(FamilyTimeLogsCompanion(hours: Value(hours), note: Value(note)));
    } else {
      await db.into(db.familyTimeLogs).insert(FamilyTimeLogsCompanion.insert(
        id: const Uuid().v4(), date: today, hours: hours, note: Value<String?>(note), createdAt: DateTime.now().toIso8601String(),
      ));
    }
    ref.invalidate(todayFamilyProvider);
    ref.invalidate(weeklyFamilyHoursProvider);
    ref.invalidate(trackingDataProvider);
  }
}

final familyNotifierProvider = AsyncNotifierProvider<FamilyNotifier, void>(FamilyNotifier.new);
