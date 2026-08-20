import 'package:beslet_app/core/ai/delve/delve_models.dart';
import 'package:beslet_app/core/ai/delve/delve_prompt.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:flutter_test/flutter_test.dart';

DelveRequest _request({bool am = false}) => DelveRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 4),
      isAmharic: am,
      verseTexts: const [
        'The LORD is my shepherd.',
        'He leads me beside still waters.',
        'He restores my soul.',
        'Though I walk through the valley.',
      ],
    );

void main() {
  const builder = DelvePromptBuilder();

  group('DelvePromptBuilder.build', () {
    test('names the passage, verses, and reader language', () {
      final prompt = builder.build(_request());
      expect(prompt, contains('Psalms 23:1–4'));
      expect(prompt, contains('1. The LORD is my shepherd.'));
      expect(prompt, contains('2. He leads me beside still waters.'));
      expect(prompt, contains('4. Though I walk through the valley.'));
      expect(prompt, contains('Write in: english'));
    });

    test('for Amharic requests, writes in Amharic with the step language', () {
      final prompt = builder.build(_request(am: true));
      expect(prompt, contains('Write in: amharic'));
      expect(prompt, contains('ደረጃ'));
      expect(prompt, contains('እግዚአብሔር'));
    });

    test('covers all six deep-study output blocks in the JSON schema', () {
      final prompt = builder.build(_request());
      for (final key in [
        'expandedHistory',
        'literaryAnalysis',
        'originalLanguage',
        'expandedCrossReferences',
        'documentedInterpretations',
        'structuredObservations',
      ]) {
        expect(prompt, contains(key));
      }
    });

    test('keeps the honesty rules explicit', () {
      final prompt = builder.build(_request());
      expect(prompt, contains('never'));
      expect(prompt, contains("God is telling you"));
      expect(prompt, contains('documented'));
      expect(prompt, contains('clearlyStated'));
      expect(prompt, contains('canonical bookId'));
    });

    test('promises the vocabulary of the app\'s Amharic Bible when Amharic',
        () {
      expect(builder.build(_request(am: true)), contains('ጽድቅ'));
    });
  });
}