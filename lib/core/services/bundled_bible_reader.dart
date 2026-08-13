import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'bible_seed_service.dart';

/// A single authoritative source for verse text: the bundled bilingual Bible
/// (`assets/data/bible_am.gzip` = 1962 Amharic, `bible_en.gzip` = WEB) that
/// every reader (Bible screen, audio, search) uses. Daily-verse, prayer and
/// notification text is read from here so the app never shows a transcription
/// that differs from the Bible the reader displays.
///
/// Reading order mirrors the reader: it prefers the seeded per-chapter files in
/// `bible_text_cache`, and falls back to decoding the bundled gzip — done once
/// per language and kept in memory — so resolution is deterministic,
/// offline-safe, and never depends on the network fallback path.
class BundledBibleReader {
  BundledBibleReader._();

  static final BundledBibleReader instance = BundledBibleReader._();

  final Map<String, Map<String, dynamic>> _bundles = {'en': {}, 'am': {}};

  /// Optional seam for tests that run without Flutter asset plumbing.
  Future<List<int>> Function(String asset)? assetBytesLoader;

  /// The exact text of one verse from the bundled Bible. Returns null when the
  /// chapter or verse is absent so callers can route to a verified fallback.
  Future<String?> textFor(
    String bookId,
    int chapter,
    int verse, {
    required bool isAmharic,
  }) async {
    final rows = await chapterFor(bookId, chapter, isAmharic: isAmharic);
    if (rows == null) return null;
    for (final row in rows) {
      if (row['verse'] == verse) return row['text'] as String?;
    }
    return null;
  }

  /// The whole chapter as a list of `{verse, text}` rows, or null when absent.
  Future<List<Map<String, dynamic>>?> chapterFor(
    String bookId,
    int chapter, {
    required bool isAmharic,
  }) async {
    final seeded = await _trySeeded(bookId, chapter, isAmharic);
    if (seeded != null) return seeded;

    final lang = isAmharic ? 'am' : 'en';
    var bundle = _bundles[lang];
    if (bundle == null || bundle.isEmpty) {
      final decoded = await _decodeBundle(isAmharic: isAmharic);
      if (decoded == null) return null;
      _bundles[lang] = decoded;
      bundle = decoded;
    }
    final raw = bundle['${bookId}_$chapter'];
    if (raw is! List) return null;
    return List<Map<String, dynamic>>.of(raw.map((e) {
      final m = e as Map;
      return {'verse': m['verse'] as int, 'text': (m['text'] as String?) ?? ''};
    }));
  }

  Future<List<Map<String, dynamic>>?> _trySeeded(
    String bookId,
    int chapter,
    bool isAmharic,
  ) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/bible_text_cache/${bookId}_$chapter${isAmharic ? '_am' : ''}.json');
      if (!await file.exists()) return null;
      final data = jsonDecode(await file.readAsString()) as List;
      return data.map((v) {
        final m = v as Map;
        return {'verse': m['verse'] as int, 'text': (m['text'] as String?) ?? ''};
      }).toList();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _decodeBundle({required bool isAmharic}) async {
    final asset = isAmharic ? BibleSeedService.amAsset : BibleSeedService.enAsset;
    try {
      final List<int> bytes;
      final loader = assetBytesLoader;
      if (loader != null) {
        bytes = await loader(asset);
      } else {
        final source = await rootBundle.load(asset);
        bytes = source.buffer
            .asUint8List(source.offsetInBytes, source.lengthInBytes);
      }
      return jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Test hook: forget everything cached so a fresh bundle can load again.
  void resetForTest() {
    _bundles['en'] = {};
    _bundles['am'] = {};
  }
}