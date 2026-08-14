import 'package:beslet_app/core/ai/study/study_intro.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_prompt.dart';
import 'package:flutter_test/flutter_test.dart';

StudyRequest _request({bool am = false, StudyGenre? genre}) => StudyRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 3),
      isAmharic: am,
      verseTexts: const ['a', 'b', 'c'],
      genre: genre,
    );

void main() {
  const builder = StudyPromptBuilder();

  group('length bands', () {
    test('a single verse is a plain study', () {
      expect(StudyLengthBudget.lengthBandFor(1), ('plain', 300, 500));
    });

    test('two or three verses are a clear study', () {
      expect(StudyLengthBudget.lengthBandFor(2), ('clear', 450, 700));
      expect(StudyLengthBudget.lengthBandFor(3), ('clear', 450, 700));
    });

    test('four to eight verses are a focused study', () {
      expect(StudyLengthBudget.lengthBandFor(4), ('focused', 600, 900));
      expect(StudyLengthBudget.lengthBandFor(8), ('focused', 600, 900));
    });

    test('a longer passage is a sustained study', () {
      expect(StudyLengthBudget.lengthBandFor(9), ('sustained', 750, 1100));
    });
  });

  group('prompt content', () {
    test('the voice contract is present', () {
      final prompt = builder.build(_request());
      expect(prompt, contains('not cold'));
      expect(prompt, contains('NEUTRAL TO ALL TRADITIONS'));
      expect(prompt, contains('the Church'));
      expect(prompt, contains('The AI provides understanding.'));
      expect(prompt, contains('The Holy Spirit provides revelation.'));
    });

    test('the passage length band is promised in words', () {
      final prompt = builder.build(_request());
      expect(prompt, contains('a "clear" study'));
      expect(prompt, contains('450'));
      expect(prompt, contains('700'));
    });

    test('the movement and bullet contract is present', () {
      final prompt = builder.build(_request());
      expect(prompt, contains('Step N —'));
      expect(prompt, contains('ደረጃ N —'));
      expect(prompt, contains('• '));
    });

    test('the takeaway contract is present and bans the second person', () {
      final prompt = builder.build(_request());
      expect(prompt, contains('MEMORY ANCHOR'));
      expect(prompt, contains('one-sentence'));
      expect(prompt, contains('second person'));
      expect(prompt, contains('never as a question'));
    });

    test('genre guidance is included when the request knows the genre', () {
      final prompt = builder.build(_request(genre: StudyGenre.poetry));
      expect(prompt, contains('poetry work'));
      expect(prompt, contains('let the imagery breathe'));
    });

    test('genre guidance is omitted when the genre is unknown', () {
      final prompt = builder.build(_request());
      expect(prompt, isNot(contains('poetry work')));
      expect(prompt, isNot(contains('let the imagery breathe')));
    });

    test('the Amharic register block appears for both, the language differs', () {
      final en = builder.build(_request());
      final am = builder.build(_request(am: true));
      expect(en, contains('Write in: english'));
      expect(am, contains('Write in: amharic'));
      expect(am, contains('AMHARIC (when the requested language'));
      expect(am, contains('እግዚአብሔር'));
    });
  });
}
