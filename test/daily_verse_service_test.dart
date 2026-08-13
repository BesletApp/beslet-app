import 'dart:convert';
import 'dart:io';

import 'package:beslet_app/core/services/bundled_bible_reader.dart';
import 'package:beslet_app/core/services/daily_verse_service.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guard rail: every Daily Verse reference must resolve to EXACTLY the text of
/// the bundled Bible — the same 1962 Amharic / WEB English the reader shows.
/// If this fails it means a canon reference drifted from the authoritative
/// text or the bundle changed, and the app would be about to show a paraphrase.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repoRoot = Directory.current.path;

  late Map<String, dynamic> en;
  late Map<String, dynamic> am;

  setUpAll(() {
    en = _loadBundle('$repoRoot/assets/data/bible_en.gzip');
    am = _loadBundle('$repoRoot/assets/data/bible_am.gzip');
    BundledBibleReader.instance.assetBytesLoader = (asset) async {
      final path = asset == 'assets/data/bible_am.gzip'
          ? '$repoRoot/assets/data/bible_am.gzip'
          : '$repoRoot/assets/data/bible_en.gzip';
      return File(path).readAsBytes();
    };
  });

  group('daily verse fidelity to the bundled Bible', () {
    for (final ref in ScriptureService.verses.map((s) => s.reference)) {
      test('$ref resolves to the exact bundle text', () async {
        final resolved = await DailyVerseService.resolveReference(ref);
        expect(resolved.reference, ref);

        final range = ScriptureService.referenceRange(ref)!;
        final enText = (en['${range.bookId}_${range.chapter}'] as List)
            .where((v) => range.verses.contains((v as Map)['verse']))
            .map((v) => ((v as Map)['text'] as String).trim())
            .join(' ');
        final amText = (am['${range.bookId}_${range.chapter}'] as List)
            .where((v) => range.verses.contains((v as Map)['verse']))
            .map((v) => ((v as Map)['text'] as String).trim())
            .join(' ');

        expect(resolved.text, enText, reason: 'English text for $ref');
        expect(resolved.textAm, amText, reason: 'Amharic text for $ref');
      });
    }
  });

  group('daily selector', () {
    test('epoch day 0 resolves to Philippians 4:13 from the bundle', () async {
      final resolved = await DailyVerseService.resolveDay(DateTime(2025, 1, 1));
      expect(resolved.reference, 'Philippians 4:13');
      expect(resolved.text, isNotEmpty);
      expect(resolved.textAm, isNotEmpty);
    });

    test('a missing verse falls back to empty text, never a paraphrase',
        () async {
      final resolved =
          await DailyVerseService.resolveReference('Genesis 1:66');
      expect(resolved.reference, 'Genesis 1:66');
      expect(resolved.text, isEmpty);
    });
  });
}

Map<String, dynamic> _loadBundle(String path) {
  final bytes = gzip.decode(File(path).readAsBytesSync());
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}