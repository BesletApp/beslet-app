import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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

  static const Map<String, String> _bookAbbr = {
    'genesis': '\u12d8\u134d', 'exodus': '\u12d8\u1338', 'leviticus': '\u12d8\u120c',
    'numbers': '\u12d8\u128d', 'deuteronomy': '\u12d8\u12f3', 'joshua': '\u1218.\u12a2\u12eb',
    'judges': '\u1218.\u1218\u1223', 'ruth': '\u1218.\u1229\u1275', '1samuel': '\u1218.\u1233\u1219\u0031',
    '2samuel': '\u1218.\u1233\u1219\u0032', '1kings': '\u1218.\u1290\u1308\u0031', '2kings': '\u1218.\u1290\u1308\u0032',
    '1chronicles': '\u1218.\u12dc\u1293\u0031', '2chronicles': '\u1218.\u12dc\u1293\u0032',
    'ezra': '\u1218.\u12d5\u12dd', 'nehemiah': '\u1218.\u1290\u1205', 'esther': '\u1218.\u12a0\u1235',
    'job': '\u1218.\u12a2\u12ee', 'psalms': '\u1218.\u12f3', 'proverbs': '\u1218.\u121d\u1233',
    'ecclesiastes': '\u1218.\u1218\u12ad', 'songofsongs': '\u1218\u1283.\u1218\u1283.\u12d8\u1230',
    'isaiah': '\u1275\u1295.\u12a2\u1233', 'jeremiah': '\u1275\u1295.\u12a4\u122d',
    'lamentations': '\u1230\u1246.\u12a4\u122d', 'ezekiel': '\u1275.\u1215\u12dd',
    'daniel': '\u1275.\u12f3\u1295', 'hosea': '\u1275.\u1206\u1234', 'joel': '\u1275.\u12a2\u12ee',
    'amos': '\u1275.\u12a0\u121e', 'obadiah': '\u1275.\u12a0\u1265', 'jonah': '\u1275.\u12ee\u1293',
    'micah': '\u1275.\u121a\u12ad', 'nahum': '\u1275.\u1293\u1206', 'habakkuk': '\u1275.\u12d5\u1295\u1263',
    'zephaniah': '\u1275.\u1236\u134e', 'haggai': '\u1275.\u1210\u130c', 'zechariah': '\u1275.\u12d8\u12ab\u122d',
    'malachi': '\u1275.\u121a\u120d', 'matthew': '\u121b\u1274', 'mark': '\u121b\u122d',
    'luke': '\u1209\u1243', 'john': '\u12ee\u1210', 'acts': '\u1210\u12cb',
    'romans': '\u122e\u121c', '1corinthians': '1 \u1246\u122e', '2corinthians': '2 \u1246\u122e',
    'galatians': '\u1308\u120b', 'ephesians': '\u12a4\u134c\u1236',
    'philippians': '\u134a\u120d', 'colossians': '\u1246\u120b',
    '1thessalonians': '1\u1270\u1230', '2thessalonians': '2\u1270\u1230',
    '1timothy': '1\u1322\u121e', '2timothy': '2\u1322\u121e', 'titus': '\u1272\u1276',
    'philemon': '\u134a\u120d', 'hebrews': '\u12d5\u1265', 'james': '\u12eb\u12d5',
    '1peter': '1\u1334\u1325', '2peter': '2\u1334\u1325', '1john': '1\u12ee\u1210',
    '2john': '2\u12ee\u1210', '3john': '3\u12ee\u1210', 'jude': '\u12ed\u1211',
    'revelation': '\u12ee\u122b\u12a5',
  };

  static String? _getAbbr(String bookId) => _bookAbbr[bookId];

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

    final abbr = _getAbbr(bookId);
    if (abbr == null) return [];
    final url = '$_baseUrl/books/${Uri.encodeComponent(abbr)}/chapters/$chapter';
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final verses = data['verses'] as List<dynamic>?;
      if (verses == null) return [];
      final result = verses.asMap().entries.map((entry) {
        return AmharicVerse(number: entry.key + 1, text: entry.value as String);
      }).toList();
      await _saveCache(bookId, chapter, result);
      return result;
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
