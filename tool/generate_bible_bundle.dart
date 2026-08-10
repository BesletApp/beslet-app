import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:beslet_app/core/services/amharic_book_abbr.dart';
import 'package:beslet_app/core/services/wordproject_amharic_parser.dart';

const int _maxConcurrent = 4;
const int _maxRetries = 6;
const String _enOutput = 'assets/data/bible_en.gzip';
const String _amOutput = 'assets/data/bible_am.gzip';

Future<void> main(List<String> args) async {
  final limitArg = args.isNotEmpty ? int.tryParse(args.first) : null;
  final outDir = Directory(File(_enOutput).parent.path);
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final enFile = File(_enOutput);
  final amFile = File(_amOutput);
  final chapters = <String, List<Map<String, dynamic>>>{
    ..._loadExisting(enFile).map((k, v) => MapEntry('en_$k', v)),
    ..._loadExisting(amFile).map((k, v) => MapEntry('am_$k', v)),
  };

  final pending = <String>[];
  for (final book in ScriptureService.allBooks) {
    for (var c = 1; c <= book.chapters; c++) {
      final key = '${book.id}_$c';
      if (!chapters.containsKey('en_$key')) pending.add('en_$key');
      if (!chapters.containsKey('am_$key')) pending.add('am_$key');
    }
  }
  stdout.writeln('Pending chapters: ${pending.length}');

  if (limitArg != null && limitArg > 0) {
    pending.removeRange(
        limitArg < pending.length ? limitArg : pending.length, pending.length);
  }

  var index = 0;
  while (index < pending.length) {
    final slice = pending.skip(index).take(_maxConcurrent).toList();
    await Future.wait(slice.map((key) => _fetchAndStore(key, chapters)));
    index += _maxConcurrent;
    _saveAll(chapters);
    stdout.writeln('Progress: ${chapters.length} stored');
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }

  stdout.writeln('Done. Chapters stored: ${chapters.length}');
  stdout.writeln('EN file: ${enFile.path} (${enFile.lengthSync()} bytes)');
  stdout.writeln('AM file: ${amFile.path} (${amFile.lengthSync()} bytes)');
}

Map<String, List<Map<String, dynamic>>> _loadExisting(File file) {
  if (!file.existsSync()) return {};
  try {
    final bytes = file.readAsBytesSync();
    final json = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
    return json.map((k, v) => MapEntry(
        k, (v as List).map((e) => (e as Map).cast<String, dynamic>()).toList()));
  } catch (_) {
    return {};
  }
}

void _saveAll(Map<String, List<Map<String, dynamic>>> chapters) {
  _writeGzip(File(_enOutput), chapters, prefix: 'en_');
  _writeGzip(File(_amOutput), chapters, prefix: 'am_');
}

void _writeGzip(File file, Map<String, List<Map<String, dynamic>>> chapters,
    {required String prefix}) {
  final payload = <String, dynamic>{};
  for (final entry in chapters.entries) {
    if (entry.key.startsWith(prefix)) {
      payload[entry.key.substring(prefix.length)] = entry.value;
    }
  }
  final bytes = gzip.encode(utf8.encode(jsonEncode(payload)));
  final tmp = File('${file.path}.tmp');
  tmp.writeAsBytesSync(bytes);
  tmp.renameSync(file.path);
}

Future<void> _fetchAndStore(String key,
    Map<String, List<Map<String, dynamic>>> out) async {
  if (out.containsKey(key)) return;
  final parts = key.split('_');
  final lang = parts.removeAt(0);
  final bookId = parts.join('_').replaceAll(RegExp(r'_\d+$'), '');
  final chapter = int.parse(parts.last);
  for (var attempt = 0; attempt < _maxRetries; attempt++) {
    try {
      final verses = lang == 'en'
          ? await _fetchEn(bookId, chapter)
          : await _fetchAm(bookId, chapter);
      if (verses.isNotEmpty) {
        out[key] = verses;
        stdout.writeln('OK $key (${verses.length})');
        return;
      }
      stdout.writeln('EMPTY $key (attempt ${attempt + 1})');
    } catch (e) {
      stdout.writeln('FAIL $key (attempt ${attempt + 1}): $e');
    }
    await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
  }
}

Future<List<Map<String, dynamic>>> _fetchEn(String bookId, int chapter) async {
  final book = ScriptureService.bookMap[bookId];
  if (book == null) return [];
  final bookName = book.nameEn;
  final url = 'https://bible-api.com/${Uri.encodeComponent(bookName)}+$chapter?translation=web';
  final response = await http
      .get(Uri.parse(url), headers: {'User-Agent': 'BesletApp/1.0'})
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body);
  final verses = data['verses'] as List<dynamic>;
  return verses
      .map((v) => {'verse': v['verse'] as int, 'text': (v['text'] as String).trim()})
      .toList();
}

Future<List<Map<String, dynamic>>> _fetchAm(String bookId, int chapter) async {
  final fromApi = await _fetchAmApi(bookId, chapter);
  if (fromApi.isNotEmpty) return fromApi;
  return _fetchAmWordProject(bookId, chapter);
}

Future<List<Map<String, dynamic>>> _fetchAmApi(String bookId, int chapter) async {
  final abbr = amharicBookAbbr[bookId];
  if (abbr == null) return [];
  final url =
      'https://openamharicbible.vercel.app/api/am/books/${Uri.encodeComponent(abbr)}/chapters/$chapter';
  final response = await http
      .get(Uri.parse(url))
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) return [];
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final verses = data['verses'] as List<dynamic>?;
  if (verses == null) return [];
  return verses.asMap().entries.map((e) {
    return {'verse': e.key + 1, 'text': (e.value as String).trim()};
  }).toList();
}

/// Fills Amharic chapters the openamharicbible API is missing by parsing the
/// chapter text from wordproject.org, which the API is itself derived from.
Future<List<Map<String, dynamic>>> _fetchAmWordProject(
    String bookId, int chapter) async {
  final book = ScriptureService.bookMap[bookId];
  if (book == null) return [];
  final url =
      'https://www.wordproject.org/bibles/am/${book.wordprojectId}/$chapter.htm';
  final response = await http
      .get(Uri.parse(url), headers: {'User-Agent': 'BesletApp/1.0'})
      .timeout(const Duration(seconds: 30));
  if (response.statusCode != 200) return [];
  final verses = parseWordProjectAmharicChapter(utf8.decode(response.bodyBytes));
  return verses
      .map((v) => {'verse': v.number, 'text': v.text})
      .toList();
}
