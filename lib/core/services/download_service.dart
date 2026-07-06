import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadedChapter {
  final String bookId;
  final int chapter;
  final String bookName;

  const DownloadedChapter({
    required this.bookId,
    required this.chapter,
    required this.bookName,
  });

  Map<String, dynamic> toJson() => {
    'bookId': bookId,
    'chapter': chapter,
    'bookName': bookName,
  };

  factory DownloadedChapter.fromJson(Map<String, dynamic> json) =>
      DownloadedChapter(
        bookId: json['bookId'] as String,
        chapter: json['chapter'] as int,
        bookName: json['bookName'] as String,
      );
}

class DownloadService {
  static List<DownloadedChapter> _cache = [];
  static bool _loaded = false;

  static Future<Directory> _dir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/bible_downloads');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<String> _manifestPath() async {
    final d = await _dir();
    return '${d.path}/manifest.json';
  }

  static Future<List<DownloadedChapter>> getDownloads() async {
    if (!_loaded) await _load();
    return List.unmodifiable(_cache);
  }

  static Future<bool> isDownloaded(String bookId, int chapter) async {
    if (!_loaded) await _load();
    return _cache.any((d) => d.bookId == bookId && d.chapter == chapter);
  }

  static Future<void> addDownload(String bookId, int chapter, String bookName) async {
    if (await isDownloaded(bookId, chapter)) return;
    _cache.add(DownloadedChapter(bookId: bookId, chapter: chapter, bookName: bookName));
    await _save();
  }

  static Future<void> removeDownload(String bookId, int chapter) async {
    if (!_loaded) await _load();
    _cache.removeWhere((d) => d.bookId == bookId && d.chapter == chapter);
    await _save();
  }

  static Future<void> _load() async {
    try {
      final path = await _manifestPath();
      final file = File(path);
      if (!file.existsSync()) {
        _cache = [];
        _loaded = true;
        return;
      }
      final data = jsonDecode(await file.readAsString()) as List;
      _cache = data.map((e) => DownloadedChapter.fromJson(e as Map<String, dynamic>)).toList();
      _loaded = true;
    } catch (_) {
      _cache = [];
      _loaded = true;
    }
  }

  static Future<void> _save() async {
    try {
      final path = await _manifestPath();
      final data = _cache.map((d) => d.toJson()).toList();
      await File(path).writeAsString(jsonEncode(data));
    } catch (_) {}
  }
}
