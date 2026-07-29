import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'database_provider.dart';

final allBibleReadsProvider = FutureProvider<List<BibleRead>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.select(db.bibleReads).get();
});

final totalReadingDaysProvider = FutureProvider<int>((ref) async {
  final reads = await ref.watch(allBibleReadsProvider.future);
  return reads.map((r) => r.date).toSet().length;
});

final readingDaysThisWeekProvider = FutureProvider<int>((ref) async {
  final reads = await ref.watch(allBibleReadsProvider.future);
  final now = DateTime.now();
  final weekday = now.weekday;
  final weekStart = now.subtract(Duration(days: weekday - 1));
  return reads
      .map((r) => DateTime.tryParse(r.date))
      .where((d) => d != null && !d.isBefore(weekStart))
      .map((d) => '${d!.year}-${d.month}-${d.day}')
      .toSet()
      .length;
});

final totalReadingMinutesProvider = FutureProvider<int>((ref) async {
  final reads = await ref.watch(allBibleReadsProvider.future);
  int sum = 0;
  for (final r in reads) { sum += r.durationMinutes; }
  return sum;
});
