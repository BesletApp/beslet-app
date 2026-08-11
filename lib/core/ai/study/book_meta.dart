import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// The deterministic canonical layer: the book list and the exact verse count
/// of every chapter, in both languages the app ships. Everything else —
/// the validator, the bank, the in-sheet passage viewer — reads the canon from
/// here so that a reference the reader cannot actually open is never shown.
///
/// The assets are generated from the app's own data (`book_meta.json` from
/// `ScriptureService.bookMap`, `chapter_verse_counts.json` from the bundled
/// English and Amharic texts), so the canon always agrees with what the
/// reader can see. Verse counts are language-aware: the Ethiopian and
/// Western versifications differ in places, and a cross-reference must open
/// in the reader's own Bible.

/// One book of the canon, language-independent.
class CanonBook {
  final String id;
  final String nameEn;
  final String nameAm;
  final int chapters;
  final String sectionId;
  final int wordprojectId;

  const CanonBook({
    required this.id,
    required this.nameEn,
    required this.nameAm,
    required this.chapters,
    required this.sectionId,
    required this.wordprojectId,
  });
}

/// The canonical book list + per-chapter verse counts. Loaded once from the
/// bundle and shared; built from `assets/data/book_meta.json` and
/// `assets/data/chapter_verse_counts.json`.
class StudyCanon {
  static const int expectedVersion = 1;

  final int version;
  final Map<String, CanonBook> books;
  final Map<String, List<int>> verseCountsEn;
  final Map<String, List<int>> verseCountsAm;

  const StudyCanon({
    required this.version,
    required this.books,
    required this.verseCountsEn,
    required this.verseCountsAm,
  });

  /// Loads the bundled canon. Throws if an asset is missing, malformed, or
  /// carries an unexpected version — the app fails closed rather than
  /// validating references against unknown data.
  static Future<StudyCanon> load() async {
    final bookRaw = await rootBundle.loadString('assets/data/book_meta.json');
    final countsRaw =
        await rootBundle.loadString('assets/data/chapter_verse_counts.json');
    return StudyCanon.fromJsonString(bookRaw, countsRaw);
  }

  static StudyCanon fromJsonString(String bookMetaRaw, String countsRaw) {
    final booksJson = jsonDecode(bookMetaRaw) as Map<String, dynamic>;
    if (booksJson['version'] != expectedVersion) {
      throw FormatException('unexpected book_meta version');
    }
    final books = <String, CanonBook>{};
    for (final raw in booksJson['books'] as List<dynamic>) {
      final b = raw as Map<String, dynamic>;
      books[b['id'] as String] = CanonBook(
        id: b['id'] as String,
        nameEn: b['nameEn'] as String,
        nameAm: b['nameAm'] as String,
        chapters: b['chapters'] as int,
        sectionId: b['sectionId'] as String,
        wordprojectId: b['wordprojectId'] as int,
      );
    }

    final countsJson = jsonDecode(countsRaw) as Map<String, dynamic>;
    if (countsJson['version'] != expectedVersion) {
      throw FormatException('unexpected chapter_verse_counts version');
    }
    Map<String, List<int>> parseLanguage(dynamic lang) {
      final out = <String, List<int>>{};
      (lang as Map<String, dynamic>).forEach((bookId, counts) {
        out[bookId] = (counts as List<dynamic>).cast<int>();
      });
      return out;
    }

    final languages = countsJson['languages'] as Map<String, dynamic>;
    final verseCountsEn = parseLanguage(languages['en']);
    final verseCountsAm = parseLanguage(languages['am']);

    // Fail closed on an inconsistent canon: every book must have a count for
    // every chapter, in both languages, and every chapter must have verses.
    for (final book in books.values) {
      for (final counts in [verseCountsEn, verseCountsAm]) {
        final list = counts[book.id];
        if (list == null || list.length != book.chapters) {
          throw FormatException('incomplete verse counts for ${book.id}');
        }
        if (list.any((n) => n < 1)) {
          throw FormatException('empty chapter in ${book.id}');
        }
      }
    }

    return StudyCanon(
      version: booksJson['version'] as int,
      books: books,
      verseCountsEn: verseCountsEn,
      verseCountsAm: verseCountsAm,
    );
  }

  CanonBook? bookFor(String bookId) => books[bookId];

  /// How many verses a chapter holds in the reader's language, or null when
  /// the book or chapter does not exist.
  int? verseCount(String bookId, int chapter,
      {required bool isAmharic}) {
    final list = (isAmharic ? verseCountsAm : verseCountsEn)[bookId];
    if (list == null) return null;
    if (chapter < 1 || chapter > list.length) return null;
    return list[chapter - 1];
  }

  /// Whether a passage actually exists in the reader's language. Both bounds
  /// are checked against the canon, so a citation that cannot be opened is
  /// never accepted.
  bool validReference({
    required String bookId,
    required int chapter,
    required int startVerse,
    required int endVerse,
    required bool isAmharic,
  }) {
    final book = books[bookId];
    if (book == null) return false;
    if (chapter < 1 || chapter > book.chapters) return false;
    if (startVerse < 1 || endVerse < startVerse) return false;
    final count = verseCount(bookId, chapter, isAmharic: isAmharic);
    if (count == null || endVerse > count) return false;
    return true;
  }
}
