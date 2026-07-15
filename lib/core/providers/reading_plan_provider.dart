import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/plan_progress_service.dart';
import '../services/loop_service.dart';
import 'database_provider.dart';

final readingProgressProvider = FutureProvider<PlanProgress>((ref) async {
  final db = ref.read(databaseProvider);
  return await PlanProgressService.compute(db);
});

final activeLoopProvider = FutureProvider<ReadingLoop?>((ref) async {
  final db = ref.read(databaseProvider);
  return await LoopService.getActiveLoop(db);
});

final loopHistoryProvider = FutureProvider<List<ReadingLoop>>((ref) async {
  final db = ref.read(databaseProvider);
  return await LoopService.getLoopHistory(db);
});
