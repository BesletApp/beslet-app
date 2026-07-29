import '../database/app_database.dart';
import 'scripture_service.dart';

class BookProgress {
  final BibleBook book;
  final int chaptersRead;
  final bool isComplete;
  BookProgress({required this.book, required this.chaptersRead, required this.isComplete});
}

class PlanProgress {
  final int totalChaptersRead;
  final int totalChaptersInBible;
  final double biblePercent;
  final List<BookProgress> otProgress;
  final List<BookProgress> ntProgress;
  final int otChaptersRead;
  final int otTotalChapters;
  final int ntChaptersRead;
  final int ntTotalChapters;
  final String? currentBookName;
  final int currentBookChapter;
  final int currentBookTotal;

  PlanProgress({
    required this.totalChaptersRead,
    required this.totalChaptersInBible,
    required this.biblePercent,
    required this.otProgress,
    required this.ntProgress,
    required this.otChaptersRead,
    required this.otTotalChapters,
    required this.ntChaptersRead,
    required this.ntTotalChapters,
    this.currentBookName,
    this.currentBookChapter = 0,
    this.currentBookTotal = 0,
  });
}

class PlanProgressService {
  static Future<PlanProgress> compute(AppDatabase db) async {
    final users = await db.select(db.users).get();
    final planId = users.isNotEmpty ? users.first.biblePlan : 'nt';
    final books = planId == 'ot' ? ScriptureService.otBooks : ScriptureService.ntBooks;

    final reads = await db.select(db.bibleReads).get();
    final sessions = await (db.select(db.bibleSessions)
      ..where((t) => t.isPlanReading.equals(true))
    ).get();

    final chapterSet = <String>{};
    for (final r in reads) {
      for (final b in ScriptureService.allBooks) {
        String? nameMatch;
        if (r.reference.startsWith(b.nameEn)) {
          nameMatch = b.nameEn;
        } else if (r.reference.startsWith(b.nameAm)) {
          nameMatch = b.nameAm;
        }
        if (nameMatch != null) {
          final rest = r.reference.substring(nameMatch.length).trim();
          final ch = int.tryParse(rest);
          if (ch != null) chapterSet.add('${b.id}:$ch');
          break;
        }
      }
    }
    for (final s in sessions) {
      final book = ScriptureService.bookMap[s.bookId];
      if (book != null) {
        for (int ch = s.chapterStart; ch <= s.chapterEnd; ch++) {
          chapterSet.add('${s.bookId}:$ch');
        }
      }
    }

    final otBooks = ScriptureService.otBooks;
    final ntBooks = ScriptureService.ntBooks;

    final allBibleBooks = ScriptureService.allBooks;
    final totalChaptersInBible = allBibleBooks.fold<int>(0, (s, b) => s + b.chapters);

    List<BookProgress> buildProgress(List<BibleBook> bookList) {
      return bookList.map((book) {
        int read = 0;
        for (int ch = 1; ch <= book.chapters; ch++) {
          if (chapterSet.contains('${book.id}:$ch')) read++;
        }
        return BookProgress(book: book, chaptersRead: read, isComplete: read >= book.chapters);
      }).toList();
    }

    final otProgress = buildProgress(otBooks);
    final ntProgress = buildProgress(ntBooks);

    final totalRead = chapterSet.length;
    final otRead = otProgress.fold<int>(0, (s, p) => s + p.chaptersRead);
    final ntRead = ntProgress.fold<int>(0, (s, p) => s + p.chaptersRead);
    final otTotal = otBooks.fold<int>(0, (s, b) => s + b.chapters);
    final ntTotal = ntBooks.fold<int>(0, (s, b) => s + b.chapters);

    String? currentBookName;
    int currentBookChapter = 0;
    int currentBookTotal = 0;
    for (final book in books) {
      if (currentBookName != null) break;
      for (int ch = 1; ch <= book.chapters; ch++) {
        if (!chapterSet.contains('${book.id}:$ch')) {
          currentBookName = book.nameEn;
          currentBookChapter = ch;
          currentBookTotal = book.chapters;
          break;
        }
      }
    }

    return PlanProgress(
      totalChaptersRead: totalRead,
      totalChaptersInBible: totalChaptersInBible,
      biblePercent: totalChaptersInBible > 0 ? totalRead / totalChaptersInBible : 0,
      otProgress: otProgress,
      ntProgress: ntProgress,
      otChaptersRead: otRead,
      otTotalChapters: otTotal,
      ntChaptersRead: ntRead,
      ntTotalChapters: ntTotal,
      currentBookName: currentBookName,
      currentBookChapter: currentBookChapter,
      currentBookTotal: currentBookTotal,
    );
  }
}
