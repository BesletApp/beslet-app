import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'ebible_web_audio_files.dart';

/// Base URL for the Winfred Henson World English Bible (WEB) recording, which
/// is in the public domain and matches the app's English WEB text (it reads
/// "Yahweh" exactly as the bundled text does).
const String ebibleWebAudioBase = 'https://ebible.org/eng-web/audio';

/// Thrown when a WEB-audio download fails for a network/IO reason (timeout,
/// unreachable host, etc.) — as opposed to a plain "no such chapter" which is
/// reported by returning `null` from [getAudio].
class EbibleWebAudioDownloadException implements Exception {
  final String message;
  const EbibleWebAudioDownloadException(this.message);

  @override
  String toString() => 'EbibleWebAudioDownloadException: $message';
}

/// Builds the public-domain WEB audio URL for a chapter.
///
/// The [ebibleWebAudioFiles] map is generated from a crawl of eBible.org's
/// directory listings, so it is robust to the recording's inconsistent
/// per-book filename conventions. Returns `null` when the chapter is not in
/// the map (should never happen for the 66-book canon).
String? ebibleWebAudioUrl({required String bookId, required int chapter}) {
  final path = ebibleWebAudioFiles['${bookId}_$chapter'];
  if (path == null) return null;
  return '$ebibleWebAudioBase/$path';
}

/// Downloads public-domain WEB (World English Bible) chapter audio from
/// eBible.org. Returns `null` when the chapter has no recorded file (HTTP
/// 404). Throws [EbibleWebAudioDownloadException] when the download itself
/// fails, so callers can tell the two cases apart.
class EbibleWebAudioService {
  static Future<File?> getAudio(String bookId, int chapter) async {
    final cached =
        await _getCached(bookId, chapter);
    if (cached != null) return cached;

    return await _download(bookId, chapter);
  }

  static Future<File?> _download(String bookId, int chapter) async {
    final url = ebibleWebAudioUrl(bookId: bookId, chapter: chapter);
    if (url == null) return null;

    try {
      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 30),
          );

      if (response.statusCode != 200) return null;

      final dir = await _cacheDir();
      final file = File('${dir.path}/${bookId}_$chapter.mp3');
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e) {
      throw EbibleWebAudioDownloadException('$e');
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
    final dir = Directory('${appDir.path}/ebible_web_audio');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}