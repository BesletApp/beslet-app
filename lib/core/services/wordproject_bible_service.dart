import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WordProjectBibleService {
  static const String _baseUrl =
      'https://www.wordproaudio.net/bibles/app/audio';

  static Future<int?> getAudioSize(int wordprojectId, int chapter,
      {String languageCode = '17'}) async {
    try {
      final url = '$_baseUrl/$languageCode/$wordprojectId/$chapter.mp3';
      final response =
          await http.head(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final length = response.headers['content-length'];
        if (length != null) return int.tryParse(length);
      }
    } catch (_) {}
    return null;
  }

  static Future<File?> getAudio(int wordprojectId, int chapter,
      {String languageCode = '17'}) async {
    final cached =
        await _getCached(wordprojectId, chapter, languageCode: languageCode);
    if (cached != null) return cached;

    return await _download(wordprojectId, chapter, languageCode: languageCode);
  }

  static Future<File?> _download(int wordprojectId, int chapter,
      {String languageCode = '17'}) async {
    try {
      final url = '$_baseUrl/$languageCode/$wordprojectId/$chapter.mp3';
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) return null;

      final dir = await _cacheDir();
      final file =
          File('${dir.path}/${languageCode}_${wordprojectId}_$chapter.mp3');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  static Future<File?> _getCached(int wordprojectId, int chapter,
      {String languageCode = '17'}) async {
    try {
      final dir = await _cacheDir();
      final file =
          File('${dir.path}/${languageCode}_${wordprojectId}_$chapter.mp3');
      if (await file.exists()) return file;
    } catch (_) {}
    return null;
  }

  static Future<Directory> _cacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/wordproject_audio');
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
}
