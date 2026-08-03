import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/services/scripture_service.dart';

void main() {
  group('threadVerseFor', () {
    test('epoch day 0 maps to the first canon verse', () {
      final v = ScriptureService.threadVerseFor(DateTime(2025, 1, 1));
      expect(v.reference, 'Philippians 4:13');
    });

    test('consecutive days advance through the canon', () {
      final day0 = ScriptureService.threadVerseFor(DateTime(2025, 1, 1));
      final day1 = ScriptureService.threadVerseFor(DateTime(2025, 1, 2));
      expect(day1.reference, 'Psalm 23:1');
      expect(day1.reference, isNot(day0.reference));
    });

    test('wraps at the end of the 30-verse loop', () {
      final wrapped = ScriptureService.threadVerseFor(DateTime(2025, 1, 31));
      expect(wrapped.reference, 'Philippians 4:13');
    });

    test('maps a day before the epoch to the last verse', () {
      final v = ScriptureService.threadVerseFor(DateTime(2024, 12, 31));
      expect(v.reference, 'Revelation 21:4');
    });

    test('is negative-safe for a full loop before the epoch', () {
      final v = ScriptureService.threadVerseFor(DateTime(2024, 12, 2));
      expect(v.reference, 'Philippians 4:13');
    });

    test('every returned reference belongs to the canon list', () {
      final canon = ScriptureService.verses.map((s) => s.reference).toSet();
      for (var d = 0; d < 90; d++) {
        final ref = ScriptureService.threadVerseFor(DateTime(2025, 1, 1).add(Duration(days: d))).reference;
        expect(canon, contains(ref));
      }
    });
  });

  group('daily selector consistency', () {
    test('getDailyScripture agrees with threadVerseFor(now)', () {
      expect(
        ScriptureService.getDailyScripture().reference,
        ScriptureService.threadVerseFor(DateTime.now()).reference,
      );
    });
  });

  group('amharicReference', () {
    test('replaces an English book name with the Amharic name', () {
      expect(
        ScriptureService.amharicReference('Philippians 4:13'),
        'ፊልጵስዩስ 4:13',
      );
    });

    test('returns the input unchanged when no book matches', () {
      expect(ScriptureService.amharicReference('NotABook 1:2'), 'NotABook 1:2');
    });
  });

  group('referenceFor', () {
    test('formats an English reference', () {
      expect(
        ScriptureService.referenceFor('philippians', 4, 13, false),
        'Philippians 4:13',
      );
    });

    test('formats an Amharic reference', () {
      expect(
        ScriptureService.referenceFor('philippians', 4, 13, true),
        'ፊልጵስዩስ 4:13',
      );
    });

    test('falls back to the raw bookId for unknown books', () {
      expect(
        ScriptureService.referenceFor('unknown', 4, 13, false),
        'unknown 4:13',
      );
    });
  });

  group('parseReference', () {
    test('parses a chapter-only reference', () {
      final parsed = ScriptureService.parseReference('Philippians 4');
      expect(parsed, isNotNull);
      expect(parsed!.bookId, 'philippians');
      expect(parsed.chapter, 4);
    });

    test('returns null for a non-book prefix', () {
      expect(ScriptureService.parseReference('NotABook 1'), isNull);
    });
  });
}
