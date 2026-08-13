import 'dart:io';

import 'package:beslet_app/core/ai/study/study_intro.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

void main() {
  group('StudyIntroLibrary (shipped asset)', () {
    late StudyIntroLibrary library;

    setUpAll(() {
      final raw = File('assets/data/study_intros.json').readAsStringSync();
      library = StudyIntroLibrary.fromJsonString(raw);
    });

    test('passes full content validation (fail-closed gate)', () {
      final issues = library.validate(canon: loadTestCanon());
      expect(issues, isEmpty,
          reason: 'the shipped intro library must be canon-clean:\n${issues.join('\n')}');
    });

    test('covers every book of the canon and nothing else', () {
      final canon = loadTestCanon();
      expect(library.intros.length, canon.books.length,
          reason:
              'expected one intro per canon book, got ${canon.books.length} canon books and ${library.intros.length} intros');
      for (final id in canon.books.keys) {
        expect(library.introFor(id), isNotNull,
            reason: 'missing intro for $id');
      }
      for (final id in library.intros.keys) {
        expect(canon.books.containsKey(id), isTrue,
            reason: 'intro $id is not a canon book');
      }
    });

    test('every intro is bilingual, genre-typed, and genre-known', () {
      expect(library.intros, isNotEmpty);
      for (final intro in library.intros.values) {
        expect(intro.genre, isNotNull,
            reason: 'intro ${intro.id} has an unknown genre');
        expect(intro.genre, isA<StudyGenre>());
        expect(intro.backgroundEn.trim(), isNotEmpty,
            reason: 'intro ${intro.id} needs English background');
        expect(intro.backgroundAm.trim(), isNotEmpty,
            reason: 'intro ${intro.id} needs Amharic background');
        expect(intro.flowEn.trim(), isNotEmpty,
            reason: 'intro ${intro.id} needs English flow');
        expect(intro.flowAm.trim(), isNotEmpty,
            reason: 'intro ${intro.id} needs Amharic flow');
        expect(intro.keyThemesEn.trim(), isNotEmpty,
            reason: 'intro ${intro.id} needs English key themes');
        expect(intro.keyThemesAm.trim(), isNotEmpty,
            reason: 'intro ${intro.id} needs Amharic key themes');
      }
    });

    test('commentary-depth bilingual coverage in every intro', () {
      for (final intro in library.intros.values) {
        final enWords = [
          intro.backgroundEn,
          intro.flowEn,
          intro.keyThemesEn,
        ].join(' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        final amWords = [
          intro.backgroundAm,
          intro.flowAm,
          intro.keyThemesAm,
        ].join(' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        expect(enWords, greaterThanOrEqualTo(60),
            reason: 'intro ${intro.id} must reach commentary depth in English, '
                'got $enWords words');
        expect(amWords, greaterThanOrEqualTo(60),
            reason: 'intro ${intro.id} must reach commentary depth in Amharic, '
                'got $amWords words');
      }
    });

    test('spiritual-boundary lint: no second-person "you" or God-in-your-life',
        () {
      final banned = [
        'god wants you',
        'god is telling you',
        'god told you',
        'god will speak to you',
        'you should',
        'you need to',
        'you must',
        'i am speaking to you',
        'pray this prayer',
      ];
      for (final intro in library.intros.values) {
        final en = [
          intro.backgroundEn,
          intro.flowEn,
          intro.keyThemesEn,
        ].join(' ').toLowerCase();
        for (final phrase in banned) {
          expect(en.contains(phrase), isFalse,
              reason: 'intro ${intro.id} contains banned English phrase "$phrase"');
        }
      }
    });

    test('every major genre occurs in the library', () {
      final seen = library.intros.values.map((i) => i.genre).toSet();
      for (final genre in StudyGenre.values) {
        expect(seen.contains(genre), isTrue,
            reason: 'no intro uses genre $genre');
      }
    });

    test('each book has its own id and the library has no duplicates', () {
      final ids = library.intros.keys;
      expect(ids.length, library.intros.length);
      expect(ids.toSet().length, ids.length);
    });

    test('rejects a library with a wrong version (fail closed)', () {
      final malformed = '{"version":9,"books":[]}';
      expect(() => StudyIntroLibrary.fromJsonString(malformed),
          throwsA(isA<FormatException>()));
    });

    test('flags a book missing from the canon (fail closed)', () {
      final canon = loadTestCanon();
      final extraBooks =
          '{"version":1,"books":[{'
          '"id":"notabook",'
          '"genre":"narrative",'
          '"background":{"en":"a","am":"ሀ"},'
          '"flow":{"en":"b","am":"ለ"},'
          '"keyThemes":{"en":"c","am":"ሐ"}}]}';
      final issues =
          StudyIntroLibrary.fromJsonString(extraBooks).validate(canon: canon);
      expect(issues.any((i) => i.contains('not a book of the canon')), isTrue,
          reason: issues.join('\n'));
    });

    test('flags a canon book that lacks an intro (fail closed)', () {
      final canon = loadTestCanon();
      final partial =
          '{"version":1,"books":[{"id":"genesis",'
          '"genre":"law",'
          '"background":{"en":"a","am":"ሀ"},'
          '"flow":{"en":"b","am":"ለ"},'
          '"keyThemes":{"en":"c","am":"ሐ"}}]}';
      final issues =
          StudyIntroLibrary.fromJsonString(partial).validate(canon: canon);
      expect(issues.any((i) => i.contains('missing')), isTrue,
          reason:
              'expected missing-book issues for a one-book library over ${canon.books.length} canon books\n${issues.join('\n')}');
    });

    test('flags both-languages requirement (fail closed)', () {
      final issues = StudyIntroLibrary.fromJsonString(
        '{"version":1,"books":['
        '{"id":"genesis","genre":"law",'
        '"background":{"en":"english only"},'
        '"flow":{"en":"flow en"},'
        '"keyThemes":{"en":"theme","am":"ሐ"}}]}',
      ).validate();
      expect(issues.any((i) => i.contains('both languages')), isTrue,
          reason: issues.join('\n'));
    });
  });
}