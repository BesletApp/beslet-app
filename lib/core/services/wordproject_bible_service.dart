import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Thrown when a recorded-audio download fails for a network/IO reason
/// (timeout, unreachable host, etc.) — as opposed to a plain "no such file"
/// 404, which is reported by returning `null` from [getAudio].
class WordProjectAudioDownloadException implements Exception {
  final String message;
  const WordProjectAudioDownloadException(this.message);

  @override
  String toString() => 'WordProjectAudioDownloadException: $message';
}

/// Builds the recorded-audio URL for the WordProject audio backend.
///
/// The backend is split across two hosts and language codes:
///  * Amharic narration is served from `wordproaudio.net` under code `17`.
///  * English narration (KJV) is served from `kjv.wordfree.net` under code `1`.
/// The old `01` code used for English returns 404 for every chapter and must
/// not be used.
String wordprojectAudioUrl({
  required int wordprojectId,
  required int chapter,
  required String languageCode,
}) {
  if (languageCode == '1' || languageCode == '01') {
    return 'https://kjv.wordfree.net/bibles/app/audio/1/$wordprojectId/$chapter.mp3';
  }
  return 'https://www.wordproaudio.net/bibles/app/audio/$languageCode/$wordprojectId/$chapter.mp3';
}

class WordProjectBibleService {
  static Future<File?> getAudio(int wordprojectId, int chapter,
      {String languageCode = '17'}) async {
    final cached =
        await _getCached(wordprojectId, chapter, languageCode: languageCode);
    if (cached != null) return cached;

    return await _download(wordprojectId, chapter, languageCode: languageCode);
  }

  /// Downloads the chapter audio. Returns `null` when the backend has no file
  /// for this chapter (HTTP 404). Throws [WordProjectAudioDownloadException]
  /// when the download itself fails (network/timeout), so callers can tell the
  /// two cases apart instead of swallowing both silently.
  static Future<File?> _download(int wordprojectId, int chapter,
      {String languageCode = '17'}) async {
    final url = wordprojectAudioUrl(
      wordprojectId: wordprojectId,
      chapter: chapter,
      languageCode: languageCode,
    );
    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) return null;

      final dir = await _cacheDir();
      final file =
          File('${dir.path}/${languageCode}_${wordprojectId}_$chapter.mp3');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      throw WordProjectAudioDownloadException('$e');
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
}
