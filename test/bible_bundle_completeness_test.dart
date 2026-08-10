import 'dart:convert';
import 'dart:io';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repoRoot = Directory.current.path;

  test('bible_en.gzip covers every book and chapter (1189)', () {
    final json = _loadBundle('$repoRoot/assets/data/bible_en.gzip');
    var expected = 0;
    for (final book in ScriptureService.allBooks) {
      for (var c = 1; c <= book.chapters; c++) {
        expected++;
        expect(json.containsKey('${book.id}_$c'), isTrue,
            reason: 'EN missing ${book.id}_$c');
        final verses = json['${book.id}_$c'] as List;
        expect(verses, isNotEmpty, reason: 'EN empty ${book.id}_$c');
      }
    }
    expect(json.length, expected);
  });

  test('bible_am.gzip covers every book and chapter (1189)', () {
    final json = _loadBundle('$repoRoot/assets/data/bible_am.gzip');
    var expected = 0;
    for (final book in ScriptureService.allBooks) {
      for (var c = 1; c <= book.chapters; c++) {
        expected++;
        expect(json.containsKey('${book.id}_$c'), isTrue,
            reason: 'AM missing ${book.id}_$c');
        final verses = json['${book.id}_$c'] as List;
        expect(verses, isNotEmpty, reason: 'AM empty ${book.id}_$c');
      }
    }
    expect(json.length, expected);
  });

  test('previously-missing Amharic chapters are present with verse text', () {
    final json = _loadBundle('$repoRoot/assets/data/bible_am.gzip');
    const gapChapters = {
      'matthew_5': 48,
      'luke_24': 53,
      'john_6': 71,
      'john_11': 57,
      'philippians_2': 30,
      'philippians_3': 21,
      'philippians_4': 23,
      'jude_1': 25,
      'revelation_14': 20,
      'revelation_21': 27,
    };
    for (final entry in gapChapters.entries) {
      final verses = json[entry.key] as List?;
      expect(verses, isNotNull, reason: 'AM still missing ${entry.key}');
      expect(verses, hasLength(entry.value),
          reason: '${entry.key} verse count');
      expect((verses as List).first['text'], isNotEmpty,
          reason: '${entry.key} verse 1 empty');
    }
  });
}

Map<String, dynamic> _loadBundle(String path) {
  final bytes = gzip.decode(File(path).readAsBytesSync());
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}
