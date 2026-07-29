import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/scripture_service.dart';
import 'bible_read_provider.dart';

const _fontSizeKey = 'reading_font_size';
const _lineSpacingKey = 'reading_line_spacing';
const _lastBookKey = 'last_read_book_id';
const _lastChapterKey = 'last_read_chapter';
const _lastLangKey = 'last_read_language';

final fontSizeProvider = StateProvider<double>((ref) => 15.0);

final lineSpacingProvider = StateProvider<double>((ref) => 1.6);

final lastReadBookIdProvider = StateProvider<String?>((ref) => null);

final lastReadChapterProvider = StateProvider<int?>((ref) => null);

final lastReadLanguageProvider = StateProvider<String?>((ref) => null);

class KeptVerse {
  final String bookId;
  final int chapter;
  final int verse;
  final String text;
  final int timestamp;
  final bool isAm;

  KeptVerse({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.timestamp,
    required this.isAm,
  });

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'chapter': chapter,
    'verse': verse,
    'text': text,
    'timestamp': timestamp,
    'isAm': isAm,
  };

  factory KeptVerse.fromJson(Map<String, dynamic> j) => KeptVerse(
    bookId: j['bookId'] as String,
    chapter: j['chapter'] as int,
    verse: j['verse'] as int,
    text: j['text'] as String,
    timestamp: j['timestamp'] as int,
    isAm: j['isAm'] as bool,
  );
}

const _keptVerseKey = 'kept_verse';
const _allKeptVersesKey = 'all_kept_verses';

final keptVerseProvider = StateProvider<KeptVerse?>((ref) => null);
final allKeptVersesProvider = StateProvider<List<KeptVerse>>((ref) => []);

class ReadingPreferences {
  static Future<void> loadFontSize(ProviderRef ref) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getDouble(_fontSizeKey) ?? 15.0;
    ref.read(fontSizeProvider.notifier).state = saved;
    final spacing = prefs.getDouble(_lineSpacingKey) ?? 1.6;
    ref.read(lineSpacingProvider.notifier).state = spacing;
  }

  static Future<void> saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, size);
  }

  static Future<void> saveLineSpacing(double spacing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineSpacingKey, spacing);
  }

  static Future<void> saveLastRead(String bookId, int chapter, String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBookKey, bookId);
    await prefs.setInt(_lastChapterKey, chapter);
    await prefs.setString(_lastLangKey, language);
  }

  static Future<({String? bookId, int? chapter, String? language})> loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final bookId = prefs.getString(_lastBookKey);
    final chapter = prefs.getInt(_lastChapterKey);
    final language = prefs.getString(_lastLangKey);
    return (bookId: bookId, chapter: chapter, language: language);
  }

  static Future<void> saveKeptVerse(KeptVerse v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keptVerseKey, jsonEncode(v.toJson()));
  }

  static Future<KeptVerse?> loadKeptVerse() async {
    final prefs = await SharedPreferences.getInstance();
    final j = prefs.getString(_keptVerseKey);
    if (j == null) return null;
    return KeptVerse.fromJson(jsonDecode(j) as Map<String, dynamic>);
  }

  static Future<void> saveJournalText(String verseId, String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('journal_$verseId', text);
  }

  static Future<String?> loadJournalText(String verseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('journal_$verseId');
  }

  static Future<List<KeptVerse>> loadAllKeptVerses() async {
    final prefs = await SharedPreferences.getInstance();
    final j = prefs.getString(_allKeptVersesKey);
    if (j == null) return [];
    final list = jsonDecode(j) as List;
    return list.map((e) => KeptVerse.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> saveAllKeptVerses(List<KeptVerse> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_allKeptVersesKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static void appendKeptVerse(List<KeptVerse> list, KeptVerse v) {
    list.removeWhere((e) => e.bookId == v.bookId && e.chapter == v.chapter && e.verse == v.verse);
    list.insert(0, v);
    if (list.length > 20) list.removeLast();
  }
}

final todaySuggestionProvider = FutureProvider<({String bookId, int chapter})?>((ref) async {
  final todayReads = await ref.watch(todayBibleReadProvider.future);
  if (todayReads.isNotEmpty) return null;

  final last = await ReadingPreferences.loadLastRead();
  if (last.bookId != null && last.chapter != null) {
    final book = ScriptureService.bookMap[last.bookId!];
    if (book != null) {
      if (last.chapter! < book.chapters) {
        return (bookId: last.bookId!, chapter: last.chapter! + 1);
      }
      final allBooks = ScriptureService.allBooks;
      final idx = allBooks.indexWhere((b) => b.id == last.bookId);
      if (idx >= 0 && idx + 1 < allBooks.length) {
        return (bookId: allBooks[idx + 1].id, chapter: 1);
      }
    }
  }
  return (bookId: 'genesis', chapter: 1);
});
