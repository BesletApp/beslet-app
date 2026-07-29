import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../services/scripture_service.dart';
import 'database_provider.dart';
import 'tracking_provider.dart';
import 'streak_provider.dart';

final bibleBooksProvider = FutureProvider<Map<String, BibleBook>>((ref) async {
  final bookMap = <String, BibleBook>{};
  for (final b in ScriptureService.allBooks) {
    bookMap[b.id] = b;
  }
  return bookMap;
});

final recentSessionsProvider = FutureProvider<List<BibleSession>>((ref) async {
  final db = ref.watch(databaseProvider);
  return (db.select(db.bibleSessions)
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
    ..limit(50)
  ).get();
});

final bookCompletionProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final sessions = await db.select(db.bibleSessions).get();
  final total = <String, int>{};
  for (final s in sessions) {
    total.update(s.bookId, (v) => v + (s.chapterEnd - s.chapterStart + 1), ifAbsent: () => s.chapterEnd - s.chapterStart + 1);
  }
  return total;
});

final bibleChaptersReadProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final sessions = await db.select(db.bibleSessions).get();
  return sessions.fold<int>(0, (sum, s) => sum + (s.chapterEnd - s.chapterStart + 1));
});

final bibleBooksCompletedProvider = FutureProvider<List<String>>((ref) async {
  final bookMap = await ref.watch(bibleBooksProvider.future);
  final chapterCounts = await ref.watch(bookCompletionProvider.future);
  return bookMap.values.where((b) => (chapterCounts[b.id] ?? 0) >= b.chapters).map((b) => b.id).toList();
});

final bibleCoverageProvider = FutureProvider<({double otPercent, double ntPercent, double totalPercent})>((ref) async {
  final chapterCounts = await ref.watch(bookCompletionProvider.future);
  final otBooks = ScriptureService.otBooks;
  final ntBooks = ScriptureService.ntBooks;
  int otTotal = 0, otRead = 0, ntTotal = 0, ntRead = 0;
  for (final b in otBooks) {
    otTotal += b.chapters;
    otRead += (chapterCounts[b.id] ?? 0).clamp(0, b.chapters);
  }
  for (final b in ntBooks) {
    ntTotal += b.chapters;
    ntRead += (chapterCounts[b.id] ?? 0).clamp(0, b.chapters);
  }
  final totalChapters = otTotal + ntTotal;
  final totalRead = otRead + ntRead;
  return (
    otPercent: otTotal > 0 ? otRead / otTotal : 0.0,
    ntPercent: ntTotal > 0 ? ntRead / ntTotal : 0.0,
    totalPercent: totalChapters > 0 ? totalRead / totalChapters : 0.0,
  );
});

final bibleCurrentBookProvider = FutureProvider<({String bookId, int chapter})?>((ref) async {
  final db = ref.watch(databaseProvider);
  final last = await (db.select(db.bibleSessions)
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)])
    ..limit(1)
  ).get();
  if (last.isEmpty) return null;
  return (bookId: last.first.bookId, chapter: last.first.chapterEnd);
});

class BibleSessionNotifier extends AsyncNotifier<void> {
  @override FutureOr<void> build() {}

  Future<void> logSession({
    required String bookId,
    required int chapterStart,
    required int chapterEnd,
    int durationMinutes = 0,
    String? reflection,
    bool isPlanReading = false,
    String? planDay,
  }) async {
    final db = ref.read(databaseProvider);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final now = DateTime.now().toIso8601String();

    await db.into(db.bibleSessions).insert(BibleSessionsCompanion.insert(
      id: const Uuid().v4(),
      date: today,
      bookId: bookId,
      chapterStart: chapterStart,
      chapterEnd: chapterEnd,
      durationMinutes: Value(durationMinutes),
      reflection: Value<String?>(reflection),
      isPlanReading: Value(isPlanReading),
      planDay: Value<String?>(planDay),
      createdAt: now,
    ));

    final existingRead = await (db.select(db.bibleReads)..where((t) => t.date.equals(today))).get();
    if (existingRead.isEmpty) {
      await db.into(db.bibleReads).insert(BibleReadsCompanion.insert(
        date: today,
        reference: '$bookId $chapterStart',
        note: Value<String?>(null),
        durationMinutes: const Value(10),
      ));
    }

    ref.invalidate(recentSessionsProvider);
    ref.invalidate(bookCompletionProvider);
    ref.invalidate(bibleChaptersReadProvider);
    ref.invalidate(bibleBooksCompletedProvider);
    ref.invalidate(bibleCoverageProvider);
    ref.invalidate(bibleCurrentBookProvider);
    ref.invalidate(trackingDataProvider);
    ref.invalidate(streakStateProvider);
    ref.invalidate(streakLogsProvider);
    ref.invalidate(streakWeekDataProvider);
  }
}

final bibleSessionNotifierProvider = AsyncNotifierProvider<BibleSessionNotifier, void>(BibleSessionNotifier.new);
