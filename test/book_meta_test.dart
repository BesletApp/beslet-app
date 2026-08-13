import 'package:beslet_app/core/ai/study/book_meta.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

void main() {
  group('StudyCanon (shipped assets)', () {
    final canon = loadTestCanon();

    test('matches ScriptureService.bookMap exactly', () {
      expect(canon.books.length, ScriptureService.bookMap.length);
      for (final book in ScriptureService.bookMap.values) {
        final c = canon.bookFor(book.id);
        expect(c, isNotNull, reason: 'missing ${book.id}');
        expect(c!.chapters, book.chapters, reason: book.id);
        expect(c.nameEn, book.nameEn, reason: book.id);
        expect(c.nameAm, book.nameAm, reason: book.id);
        expect(c.sectionId, book.sectionId, reason: book.id);
      }
    });

    test('every book has verse counts for every chapter in both languages', () {
      for (final book in canon.books.values) {
        for (final isAm in [false, true]) {
          for (var ch = 1; ch <= book.chapters; ch++) {
            final count = canon.verseCount(book.id, ch, isAmharic: isAm);
            expect(count, isNotNull,
                reason: '${book.id} $ch (${isAm ? 'am' : 'en'})');
            expect(count!, greaterThanOrEqualTo(1),
                reason: '${book.id} $ch (${isAm ? 'am' : 'en'})');
          }
        }
      }
    });

    test('known verse counts match the real text', () {
      expect(canon.verseCount('genesis', 1, isAmharic: false), 31);
      expect(canon.verseCount('psalms', 23, isAmharic: false), 6);
      expect(canon.verseCount('psalms', 150, isAmharic: false), 6);
      expect(canon.verseCount('john', 3, isAmharic: false), 36);
    });

    test('verseCount is null for missing books and out-of-range chapters', () {
      expect(canon.verseCount('nope', 1, isAmharic: false), isNull);
      expect(canon.verseCount('psalms', 0, isAmharic: false), isNull);
      expect(canon.verseCount('psalms', 151, isAmharic: false), isNull);
    });
  });

  group('StudyCanon.validReference', () {
    final canon = loadTestCanon();

    bool ok({
      required String bookId,
      required int chapter,
      required int startVerse,
      required int endVerse,
      bool isAm = false,
    }) =>
        canon.validReference(
          bookId: bookId,
          chapter: chapter,
          startVerse: startVerse,
          endVerse: endVerse,
          isAmharic: isAm,
        );

    test('accepts real passages', () {
      expect(ok(bookId: 'john', chapter: 3, startVerse: 16, endVerse: 16), isTrue);
      expect(ok(bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 6), isTrue);
    });

    test('rejects passages that do not exist', () {
      expect(ok(bookId: 'john', chapter: 3, startVerse: 37, endVerse: 37), isFalse);
      expect(ok(bookId: 'psalms', chapter: 150, startVerse: 7, endVerse: 7), isFalse);
      expect(ok(bookId: 'nope', chapter: 1, startVerse: 1, endVerse: 1), isFalse);
      expect(ok(bookId: 'psalms', chapter: 0, startVerse: 1, endVerse: 1), isFalse);
      expect(ok(bookId: 'psalms', chapter: 151, startVerse: 1, endVerse: 1), isFalse);
    });

    test('rejects inverted and empty ranges', () {
      expect(ok(bookId: 'psalms', chapter: 23, startVerse: 4, endVerse: 3), isFalse);
      expect(ok(bookId: 'psalms', chapter: 23, startVerse: 0, endVerse: 1), isFalse);
    });

    test('is language-aware where the versifications differ', () {
      expect(ok(bookId: 'genesis', chapter: 14, startVerse: 24, endVerse: 24), isTrue);
      expect(
        ok(
          bookId: 'genesis',
          chapter: 14,
          startVerse: 24,
          endVerse: 24,
          isAm: true,
        ),
        isFalse,
        reason: 'Amharic Genesis 14 ends at verse 23',
      );
    });
  });

  group('StudyCanon.fromJsonString fail-closed', () {
    String books() => '{"version":1,"books":[]}';
    String counts() =>
        '{"version":1,"languages":{"en":{},"am":{}}}';

    test('rejects a wrong book_meta version', () {
      expect(
        () => StudyCanon.fromJsonString('{"version":2,"books":[]}', counts()),
        throwsFormatException,
      );
    });

    test('rejects a wrong counts version', () {
      expect(
        () => StudyCanon.fromJsonString(books(),
            '{"version":2,"languages":{"en":{},"am":{}}}'),
        throwsFormatException,
      );
    });
  });

  group('StudyCanon.resolveBookId (USFM and name aliases)', () {
    final canon = loadTestCanon();

    test('canonical ids resolve to themselves', () {
      for (final id in canon.books.keys) {
        expect(canon.resolveBookId(id), id, reason: id);
      }
    });

    test('USFM codes resolve to their canonical book', () {
      expect(canon.resolveBookId('GEN'), 'genesis');
      expect(canon.resolveBookId('JHN'), 'john');
      expect(canon.resolveBookId('ROM'), 'romans');
      expect(canon.resolveBookId('1CO'), '1corinthians');
      expect(canon.resolveBookId('2CO'), '2corinthians');
      expect(canon.resolveBookId('PS'), 'psalms');
      expect(canon.resolveBookId('PSA'), 'psalms');
      expect(canon.resolveBookId('MAT'), 'matthew');
      expect(canon.resolveBookId('1SA'), '1samuel');
      expect(canon.resolveBookId('1TH'), '1thessalonians');
      expect(canon.resolveBookId('1PE'), '1peter');
      expect(canon.resolveBookId('1JN'), '1john');
      expect(canon.resolveBookId('REV'), 'revelation');
    });

    test('names and abbreviations in any case or punctuation resolve', () {
      expect(canon.resolveBookId('John'), 'john');
      expect(canon.resolveBookId('1 Sam'), '1samuel');
      expect(canon.resolveBookId('1st Peter'), '1peter');
      expect(canon.resolveBookId('Song of Songs'), 'songofsongs');
      expect(canon.resolveBookId('Song of Solomon'), 'songofsongs');
      expect(canon.resolveBookId('  Romans  '), 'romans');
      expect(canon.resolveBookId('1st Corinthians'), '1corinthians');
      expect(canon.resolveBookId('second Peter'), '2peter');
    });

    test('unknown tokens resolve to null', () {
      expect(canon.resolveBookId('Harambe'), isNull);
      expect(canon.resolveBookId(''), isNull);
      expect(canon.resolveBookId(null), isNull);
      expect(canon.resolveBookId('  '), isNull);
      expect(canon.resolveBookId('LOST'), isNull);
    });
  });
}
