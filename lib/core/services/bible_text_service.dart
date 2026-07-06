import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'scripture_service.dart';
import 'amharic_bible_service.dart';

class BibleVerse {
  final int verse;
  final String text;
  const BibleVerse({required this.verse, required this.text});
}

class BibleTextService {
  static Future<List<BibleVerse>> fetchChapter(String bookId, int chapter, {required bool isAmharic}) async {
    final cached = await _tryCache(bookId, chapter, isAmharic);
    if (cached != null) return cached;
    try {
      final verses = isAmharic ? await _fetchAmharic(bookId, chapter) : await _fetchEnglish(bookId, chapter);
      if (verses.isNotEmpty) _writeCache(bookId, chapter, isAmharic, verses);
      return verses;
    } catch (_) {
      return [];
    }
  }

  static Future<List<BibleVerse>?> tryCache(String bookId, int chapter, {required bool isAmharic}) =>
      _tryCache(bookId, chapter, isAmharic);

  static Future<void> cacheChapter(String bookId, int chapter, {required bool isAmharic}) async {
    final verses = isAmharic ? await _fetchAmharic(bookId, chapter) : await _fetchEnglish(bookId, chapter);
    if (verses.isNotEmpty) _writeCache(bookId, chapter, isAmharic, verses);
  }

  static Future<List<BibleVerse>?> _tryCache(String bookId, int chapter, bool isAmharic) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${bookId}_$chapter${isAmharic ? '_am' : ''}.json');
      if (!file.existsSync()) return null;
      final data = jsonDecode(await file.readAsString()) as List;
      return data.map((v) => BibleVerse(verse: v['verse'] as int, text: v['text'] as String)).toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _writeCache(String bookId, int chapter, bool isAmharic, List<BibleVerse> verses) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${bookId}_$chapter${isAmharic ? '_am' : ''}.json');
      final data = verses.map((v) => {'verse': v.verse, 'text': v.text}).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  static Future<Directory> _cacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/bible_text_cache');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<List<BibleVerse>> _fetchEnglish(String bookId, int chapter) async {
    final bookName = ScriptureService.bookMap[bookId]?.nameEn ?? bookId;
    final url = 'https://bible-api.com/${Uri.encodeComponent(bookName)}+$chapter?translation=web';
    final response = await http
        .get(Uri.parse(url), headers: {'User-Agent': 'BesletApp/1.0'})
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body);
    final verses = data['verses'] as List<dynamic>;
    return verses.map((v) => BibleVerse(verse: v['verse'] as int, text: (v['text'] as String).trim())).toList();
  }

  static Future<List<BibleVerse>> _fetchAmharic(String bookId, int chapter) async {
    final amVerses = await AmharicBibleService.fetchChapter(bookId, chapter);
    return amVerses.map((v) => BibleVerse(verse: v.number, text: v.text.trim())).toList();
  }
}
