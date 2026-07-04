import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class TelegramBibleService {
  static const String _defaultBaseUrl = 'http://localhost:3000';
  static String _baseUrl = _defaultBaseUrl;

  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  static String get baseUrl => _baseUrl;

  static Future<File?> getAudio(String bookId, int chapter) async {
    final cached = await _getCached(bookId, chapter);
    if (cached != null) return cached;

    final file = await _download(bookId, chapter);
    return file;
  }

  static Future<File?> _download(String bookId, int chapter) async {
    try {
      final url = '$_baseUrl/audio/$bookId/$chapter';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode != 200) return null;

      final dir = await _cacheDir();
      final file = File('${dir.path}/${bookId}_$chapter.mp3');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<File?> _getCached(String bookId, int chapter) async {
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${bookId}_$chapter.mp3');
      if (await file.exists()) return file;
    } catch (_) {}
    return null;
  }

  static Future<Directory> _cacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/telegram_audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<void> clearCache() async {
    final dir = await _cacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create();
    }
  }

  static Future<Map<String, int>> getStatus() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'totalCachedChapters': data['totalCachedChapters'] ?? 0,
          'cachedBooks': data['cachedBooks'] ?? 0,
        };
      }
    } catch (_) {}
    return {};
  }
}
