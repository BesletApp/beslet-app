import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BibleSeedService {
  static const _flagKey = 'bibleBundleSeeded_v1';
  static const enAsset = 'assets/data/bible_en.gzip';
  static const amAsset = 'assets/data/bible_am.gzip';
  static const _batchSize = 20;

  static Future<bool> isSeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_flagKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> seedIfNeeded({
    Future<ByteData> Function(String asset)? assetLoader,
    Future<Directory> Function()? cacheDirProvider,
  }) async {
    try {
      if (await isSeeded()) return;
      final load = assetLoader ?? _defaultLoad;
      final dirProvider = cacheDirProvider ?? _defaultCacheDir;
      final dir = await dirProvider();
      if (!dir.existsSync()) dir.createSync(recursive: true);
      var written = 0;
      for (final asset in [enAsset, amAsset]) {
        final isAm = asset == amAsset;
        final data = await load(asset);
        final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        final json = jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
        for (final entry in json.entries) {
          final suffix = isAm ? '_am' : '';
          final file = File('${dir.path}/${entry.key}$suffix.json');
          if (file.existsSync()) continue;
          await file.writeAsString(jsonEncode(entry.value));
          written++;
          if (written % _batchSize == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_flagKey, true);
    } catch (_) {}
  }

  static Future<ByteData> _defaultLoad(String asset) => rootBundle.load(asset);

  static Future<Directory> _defaultCacheDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/bible_text_cache');
  }
}
