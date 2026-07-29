import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import 'scripture_service.dart';

class LoopService {
  static Future<ReadingLoop?> getActiveLoop(AppDatabase db) async {
    final loops = await (db.select(db.readingLoops)
      ..where((t) => t.status.equals('active'))
      ..orderBy([(t) => OrderingTerm(expression: t.loopNumber, mode: OrderingMode.desc)])
    ).get();
    return loops.isNotEmpty ? loops.first : null;
  }

  static Future<List<ReadingLoop>> getLoopHistory(AppDatabase db) async {
    return await (db.select(db.readingLoops)
      ..orderBy([(t) => OrderingTerm(expression: t.loopNumber, mode: OrderingMode.desc)])
    ).get();
  }

  static Future<int> getNextUnreadChapter(AppDatabase db, String planId) async {
    final chapterSet = await _readChapterSet(db, planId);
    final books = planId == 'ot' ? ScriptureService.otBooks : ScriptureService.ntBooks;
    final totalChapters = books.fold<int>(0, (s, b) => s + b.chapters);

    int globalIdx = 0;
    for (final book in books) {
      for (int ch = 1; ch <= book.chapters; ch++) {
        if (!chapterSet.contains('${book.id}:$ch')) return globalIdx;
        globalIdx++;
      }
    }
    return totalChapters;
  }

  static Future<ReadingLoop> createFirstLoop(AppDatabase db, String planId) async {
    final existing = await getActiveLoop(db);
    if (existing != null) return existing;

    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String().substring(0, 10);
    await db.into(db.readingLoops).insert(ReadingLoopsCompanion.insert(
      id: id, planId: planId, duration: 90,
      startChapter: 0, startDate: now,
      status: 'active', loopNumber: 1,
      createdAt: now,
    ));
    return await (db.select(db.readingLoops)..where((t) => t.id.equals(id))).getSingle();
  }

  static Future<ReadingLoop> getOrCreateFirstLoop(AppDatabase db, String planId) async {
    final active = await getActiveLoop(db);
    if (active != null) return active;
    return await createFirstLoop(db, planId);
  }

  static Future<ReadingLoop> createNextLoop(AppDatabase db, String planId, int duration) async {
    final oldLoops = await (db.select(db.readingLoops)
      ..where((t) => t.status.equals('active'))
    ).get();
    for (final l in oldLoops) {
      await db.update(db.readingLoops).replace(l.copyWith(status: 'completed'));
    }

    final startCh = await getNextUnreadChapter(db, planId);
    final books = planId == 'ot' ? ScriptureService.otBooks : ScriptureService.ntBooks;
    final totalChapters = books.fold<int>(0, (s, b) => s + b.chapters);

    return await _createLoop(db, planId, duration, startCh >= totalChapters ? 0 : startCh);
  }

  static Future<ReadingLoop> _createLoop(AppDatabase db, String planId, int duration, int startChapter) async {
    final id = const Uuid().v4();
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final allLoops = await db.select(db.readingLoops).get();
    final loopNum = allLoops.isEmpty ? 1 : allLoops.map((l) => l.loopNumber).reduce((a, b) => a > b ? a : b) + 1;
    await db.into(db.readingLoops).insert(ReadingLoopsCompanion.insert(
      id: id, planId: planId, duration: duration,
      startChapter: startChapter, startDate: now,
      status: 'active', loopNumber: loopNum,
      createdAt: now,
    ));
    return await (db.select(db.readingLoops)..where((t) => t.id.equals(id))).getSingle();
  }

  static Future<Set<String>> _readChapterSet(AppDatabase db, String planId) async {
    final reads = await db.select(db.bibleReads).get();
    final sessions = await (db.select(db.bibleSessions)
      ..where((t) => t.isPlanReading.equals(true))
    ).get();

    final set = <String>{};
    final books = planId == 'ot' ? ScriptureService.otBooks : ScriptureService.ntBooks;
    for (final r in reads) {
      for (final b in books) {
        String? nameMatch;
        if (r.reference.startsWith(b.nameEn)) {
          nameMatch = b.nameEn;
        } else if (r.reference.startsWith(b.nameAm)) {
          nameMatch = b.nameAm;
        }
        if (nameMatch != null) {
          final rest = r.reference.substring(nameMatch.length).trim();
          final ch = int.tryParse(rest);
          if (ch != null) set.add('${b.id}:$ch');
          break;
        }
      }
    }
    for (final s in sessions) {
      for (int ch = s.chapterStart; ch <= s.chapterEnd; ch++) {
        set.add('${s.bookId}:$ch');
      }
    }
    return set;
  }
}
