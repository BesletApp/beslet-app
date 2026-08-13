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

  /// Resolves a raw book token to the app's canonical book id, or null when it
  /// matches nothing. The AI commonly returns USFM codes (JHN, ROM, 1CO, PSA),
  /// abbreviations, or names in any case and punctuation; this funnels them all
  /// to the exact ids the canon knows so a cross-reference the reader can
  /// actually open is never dropped for spelling.
  String? resolveBookId(String? raw) {
    final token = _normalizeBookToken(raw);
    if (token == null) return null;
    if (books.containsKey(token)) return token;
    return _aliases[token];
  }

  /// Lowercases and strips punctuation, spaces, and common '1st/second' style
  /// prefixes so '1 Sam', '1st Peter', '1Sam', and '1samuel' all collide.
  static String? _normalizeBookToken(String? raw) {
    if (raw == null) return null;
    var t = raw.trim().toLowerCase();
    if (t.isEmpty) return null;
    t = t.replaceAll(RegExp(r"[.'\-–—():]"), '');
    t = t.replaceAll(RegExp(r'\s+'), '');
    if (t.startsWith('1st')) {
      t = '1${t.substring(3)}';
    } else if (t.startsWith('2nd')) {
      t = '2${t.substring(3)}';
    } else if (t.startsWith('3rd')) {
      t = '3${t.substring(3)}';
    } else if (t.startsWith('first')) {
      t = '1${t.substring(5)}';
    } else if (t.startsWith('second')) {
      t = '2${t.substring(6)}';
    } else if (t.startsWith('third')) {
      t = '3${t.substring(5)}';
    }
    return t.isEmpty ? null : t;
  }

  /// USFM abbreviations and common name variants, normalized to the flat
  /// lowercase form produced by [_normalizeBookToken]. Canonical ids resolve
  /// directly and are not listed.
  static const Map<String, String> _aliases = {
    'gen': 'genesis',
    'ge': 'genesis',
    'exo': 'exodus',
    'ex': 'exodus',
    'lev': 'leviticus',
    'lv': 'leviticus',
    'num': 'numbers',
    'nu': 'numbers',
    'nm': 'numbers',
    'deut': 'deuteronomy',
    'deu': 'deuteronomy',
    'dt': 'deuteronomy',
    'jos': 'joshua',
    'josh': 'joshua',
    'js': 'joshua',
    'jdg': 'judges',
    'judg': 'judges',
    'jgs': 'judges',
    'rut': 'ruth',
    'ru': 'ruth',
    '1sa': '1samuel',
    '1sam': '1samuel',
    '1sm': '1samuel',
    '2sa': '2samuel',
    '2sam': '2samuel',
    '2sm': '2samuel',
    '1ki': '1kings',
    '1kin': '1kings',
    '1kgs': '1kings',
    '1kg': '1kings',
    '2ki': '2kings',
    '2kin': '2kings',
    '2kgs': '2kings',
    '2kg': '2kings',
    '1chr': '1chronicles',
    '1ch': '1chronicles',
    '2chr': '2chronicles',
    '2ch': '2chronicles',
    'ezr': 'ezra',
    'ez': 'ezra',
    'neh': 'nehemiah',
    'est': 'esther',
    'esth': 'esther',
    'es': 'esther',
    'psa': 'psalms',
    'ps': 'psalms',
    'pss': 'psalms',
    'psl': 'psalms',
    'pslm': 'psalms',
    'psalm': 'psalms',
    'prv': 'proverbs',
    'prov': 'proverbs',
    'pro': 'proverbs',
    'qoh': 'ecclesiastes',
    'ecc': 'ecclesiastes',
    'eccl': 'ecclesiastes',
    'ecl': 'ecclesiastes',
    'sng': 'songofsongs',
    'sos': 'songofsongs',
    'song': 'songofsongs',
    'songofsolomon': 'songofsongs',
    'cant': 'songofsongs',
    'canticles': 'songofsongs',
    'isa': 'isaiah',
    'is': 'isaiah',
    'jer': 'jeremiah',
    'je': 'jeremiah',
    'jr': 'jeremiah',
    'lam': 'lamentations',
    'la': 'lamentations',
    'ezk': 'ezekiel',
    'ezek': 'ezekiel',
    'eze': 'ezekiel',
    'dan': 'daniel',
    'dn': 'daniel',
    'hos': 'hosea',
    'jl': 'joel',
    'jol': 'joel',
    'amo': 'amos',
    'oba': 'obadiah',
    'obd': 'obadiah',
    'abd': 'obadiah',
    'jon': 'jonah',
    'jnh': 'jonah',
    'mic': 'micah',
    'mich': 'micah',
    'nam': 'nahum',
    'na': 'nahum',
    'hab': 'habakkuk',
    'hb': 'habakkuk',
    'zep': 'zephaniah',
    'zeph': 'zephaniah',
    'hag': 'haggai',
    'hg': 'haggai',
    'zec': 'zechariah',
    'zech': 'zechariah',
    'mal': 'malachi',
    'mat': 'matthew',
    'matt': 'matthew',
    'mt': 'matthew',
    'mrk': 'mark',
    'mar': 'mark',
    'mk': 'mark',
    'luk': 'luke',
    'lk': 'luke',
    'jhn': 'john',
    'joh': 'john',
    'jn': 'john',
    'act': 'acts',
    'ac': 'acts',
    'rom': 'romans',
    'ro': 'romans',
    '1co': '1corinthians',
    '1cor': '1corinthians',
    '2co': '2corinthians',
    '2cor': '2corinthians',
    'gal': 'galatians',
    'ga': 'galatians',
    'eph': 'ephesians',
    'ep': 'ephesians',
    'phil': 'philippians',
    'php': 'philippians',
    'phi': 'philippians',
    'col': 'colossians',
    'cl': 'colossians',
    '1th': '1thessalonians',
    '1thes': '1thessalonians',
    '1thess': '1thessalonians',
    '2th': '2thessalonians',
    '2thes': '2thessalonians',
    '2thess': '2thessalonians',
    '1ti': '1timothy',
    '1tim': '1timothy',
    '1tm': '1timothy',
    '2ti': '2timothy',
    '2tim': '2timothy',
    '2tm': '2timothy',
    'tit': 'titus',
    'ti': 'titus',
    'phm': 'philemon',
    'phlm': 'philemon',
    'phile': 'philemon',
    'heb': 'hebrews',
    'jas': 'james',
    'jm': 'james',
    '1pe': '1peter',
    '1pet': '1peter',
    '1pt': '1peter',
    '2pe': '2peter',
    '2pet': '2peter',
    '2pt': '2peter',
    '1jn': '1john',
    '1joh': '1john',
    '2jn': '2john',
    '2joh': '2john',
    '3jn': '3john',
    '3joh': '3john',
    'jud': 'jude',
    'jd': 'jude',
    'rev': 'revelation',
    're': 'revelation',
    'revelations': 'revelation',
  };

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
