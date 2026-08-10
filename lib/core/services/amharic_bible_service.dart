import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'amharic_book_abbr.dart';
import 'scripture_service.dart';
import 'wordproject_amharic_parser.dart';

class AmharicVerse {
  final int number;
  final String text;
  const AmharicVerse({required this.number, required this.text});

  Map<String, dynamic> toJson() => {'verse': number, 'text': text};
  factory AmharicVerse.fromJson(Map<String, dynamic> json) =>
      AmharicVerse(number: json['verse'] as int, text: json['text'] as String);
}

class AmharicBibleService {
  static const _baseUrl = 'https://openamharicbible.vercel.app/api/am';

  static String? _getAbbr(String bookId) => amharicBookAbbr[bookId];

  static String _cacheKey(String bookId, int chapter) => 'am_${bookId}_$chapter';

  static Future<Directory> _cacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/amharic_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<List<AmharicVerse>> fetchChapter(String bookId, int chapter) async {
    final cache = await _tryCache(bookId, chapter);
    if (cache != null) return cache;

    var result = await _fetchFromApi(bookId, chapter);
    if (result.isEmpty) {
      result = await _fetchFromWordProject(bookId, chapter);
    }
    if (result.isNotEmpty) {
      await _saveCache(bookId, chapter, result);
    }
    return result;
  }

  static Future<List<AmharicVerse>> _fetchFromApi(String bookId, int chapter) async {
    final abbr = _getAbbr(bookId);
    if (abbr == null) return [];
    final url = '$_baseUrl/books/${Uri.encodeComponent(abbr)}/chapters/$chapter';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final verses = data['verses'] as List<dynamic>?;
      if (verses == null) return [];
      return verses.asMap().entries.map((entry) {
        return AmharicVerse(number: entry.key + 1, text: entry.value as String);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<AmharicVerse>> _fetchFromWordProject(
      String bookId, int chapter) async {
    final book = ScriptureService.bookMap[bookId];
    if (book == null) return [];
    final url =
        'https://www.wordproject.org/bibles/am/${book.wordprojectId}/$chapter.htm';
    try {
      final response = await http
          .get(Uri.parse(url), headers: {'User-Agent': 'BesletApp/1.0'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final verses =
          parseWordProjectAmharicChapter(utf8.decode(response.bodyBytes));
      return verses
          .map((v) => AmharicVerse(number: v.number, text: v.text))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<AmharicVerse>?> _tryCache(String bookId, int chapter) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${_cacheKey(bookId, chapter)}.json');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as List<dynamic>;
        return data.map((v) => AmharicVerse.fromJson(v as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return null;
  }

  static Future<void> _saveCache(String bookId, int chapter, List<AmharicVerse> verses) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${_cacheKey(bookId, chapter)}.json');
      await file.writeAsString(jsonEncode(verses.map((v) => v.toJson()).toList()));
    } catch (_) {}
  }
}
