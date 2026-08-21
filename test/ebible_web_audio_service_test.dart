import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/services/ebible_web_audio_service.dart';
import 'package:beslet_app/core/services/ebible_web_audio_files.dart';

const _expectedChapters = <String, int>{
  'genesis': 50, 'exodus': 40, 'leviticus': 27, 'numbers': 36,
  'deuteronomy': 34, 'joshua': 24, 'judges': 21, 'ruth': 4,
  '1samuel': 31, '2samuel': 24, '1kings': 22, '2kings': 25,
  '1chronicles': 29, '2chronicles': 36, 'ezra': 10, 'nehemiah': 13,
  'esther': 10, 'job': 42, 'psalms': 150, 'proverbs': 31,
  'ecclesiastes': 12, 'songofsongs': 8, 'isaiah': 66, 'jeremiah': 52,
  'lamentations': 5, 'ezekiel': 48, 'daniel': 12, 'hosea': 14,
  'joel': 3, 'amos': 9, 'obadiah': 1, 'jonah': 4,
  'micah': 7, 'nahum': 3, 'habakkuk': 3, 'zephaniah': 3,
  'haggai': 2, 'zechariah': 14, 'malachi': 4, 'matthew': 28,
  'mark': 16, 'luke': 24, 'john': 21, 'acts': 28,
  'romans': 16, '1corinthians': 16, '2corinthians': 13, 'galatians': 6,
  'ephesians': 6, 'philippians': 4, 'colossians': 4,
  '1thessalonians': 5, '2thessalonians': 3, '1timothy': 6,
  '2timothy': 4, 'titus': 3, 'philemon': 1, 'hebrews': 13,
  'james': 5, '1peter': 5, '2peter': 3, '1john': 5,
  '2john': 1, '3john': 1, 'jude': 1, 'revelation': 22,
};

void main() {
  group('ebibleWebAudioUrl', () {
    test('covers every book and chapter of the 66-book canon', () {
      var total = 0;
      _expectedChapters.forEach((bookId, chapters) {
        for (var ch = 1; ch <= chapters; ch++) {
          final url = ebibleWebAudioUrl(bookId: bookId, chapter: ch);
          expect(url, isNotNull,
              reason: '$bookId $ch should have a WEB audio URL');
          expect(url, startsWith('https://ebible.org/eng-web/audio/'),
              reason: '$bookId $ch');
          total++;
        }
      });
      expect(total, 1189);
    });

    test('returns null for a chapter outside the canon', () {
      expect(ebibleWebAudioUrl(bookId: 'revelation', chapter: 23), isNull);
      expect(ebibleWebAudioUrl(bookId: 'psalms', chapter: 151), isNull);
      expect(ebibleWebAudioUrl(bookId: 'notabook', chapter: 1), isNull);
    });

    test('no duplicate file references across the canon', () {
      final seen = <String>{};
      final dups = <String>{};
      _expectedChapters.forEach((bookId, chapters) {
        for (var ch = 1; ch <= chapters; ch++) {
          final url = ebibleWebAudioUrl(bookId: bookId, chapter: ch)!;
          if (!seen.add(url)) dups.add(url);
        }
      });
      expect(dups, isEmpty);
    });

    test('spot-check exact filenames for the classic WEB recording', () {
      expect(ebibleWebAudioUrl(bookId: 'genesis', chapter: 1),
          'https://ebible.org/eng-web/audio/01_Genesis/01_01_Genesis_Chapter_One.mp3');
      expect(ebibleWebAudioUrl(bookId: 'psalms', chapter: 91),
          'https://ebible.org/eng-web/audio/19_Psalms/0569%20Psalms-Ninety%20One.mp3');
      expect(ebibleWebAudioUrl(bookId: 'john', chapter: 21),
          'https://ebible.org/eng-web/audio/43_John/1017%20John-Chapter%20Twenty%20One.mp3');
      expect(ebibleWebAudioUrl(bookId: '1samuel', chapter: 1),
          'https://ebible.org/eng-web/audio/09_First_Samuel/09_37_First_Samuel_Chapter_One.mp3');
    });
  });

  group('ebibleWebAudioFiles', () {
    test('map contains exactly the 66-book canon keys', () {
      var count = 0;
      _expectedChapters.forEach((bookId, chapters) {
        for (var ch = 1; ch <= chapters; ch++) {
          expect(ebibleWebAudioFiles['${bookId}_$ch'], isNotNull,
              reason: '${bookId}_$ch');
          count++;
        }
      });
      expect(count, ebibleWebAudioFiles.length);
    });
  });
}