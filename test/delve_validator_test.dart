import 'package:beslet_app/core/ai/delve/delve_models.dart';
import 'package:beslet_app/core/ai/delve/delve_validator.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

const _am = 'እግዚአብሔር እረኛዬ ነው።';
const _am2 = 'በሸለቆ ውስጥ እንኳን አልፈራም።';

DelveRequest _request({bool am = false}) => DelveRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 4),
      isAmharic: am,
      verseTexts: const ['a', 'b', 'c', 'd'],
    );

Map<String, dynamic> _enPayload() => {
      'expandedHistory': {
        'text': 'The psalm uses shepherd imagery rooted in David\u2019s own past.',
        'entries': [
          {
            'label': 'author',
            'category': 'probable',
            'text': 'Tradition ascribes this psalm to David, a shepherd-king.',
          },
          {
            'label': 'date',
            'category': 'debated',
            'text': 'The dating of the psalm remains debated.',
          },
          {
            'label': 'bogus',
            'category': 'established',
            'text': 'An unknown label must be dropped.',
          },
        ],
      },
      'literaryAnalysis': {
        'text':
            'Step 1 — The psalm opens with settled trust in the LORD.\n'
            'Step 2 — It moves from the table to the valley before returning.\n'
            '• a supporting note about the imagery',
      },
      'originalLanguage': {
        'text': 'The shepherd word shapes the whole psalm.',
        'terms': [
          {
            'term': 'רֹעִי',
            'language': 'hebrew',
            'transliteration': 'ro\u2019i',
            'verseNumber': 1,
            'meaning': 'my shepherd',
          },
          {
            'term': 'madeup',
            'language': 'madeup',
            'transliteration': 'x',
            'verseNumber': 1,
            'meaning': 'unknown language dropped',
          },
        ],
      },
      'expandedCrossReferences': {
        'items': [
          {
            'bookId': 'jhn',
            'chapter': 10,
            'startVerse': 11,
            'endVerse': 11,
            'priority': 0,
            'reason': 'Jesus calls Himself the good Shepherd.',
          },
          {
            'bookId': 'psalms',
            'chapter': 999,
            'startVerse': 1,
            'endVerse': 1,
            'priority': 1,
            'reason': 'Out of range chapter must be dropped.',
          },
        ],
      },
      'documentedInterpretations': {
        'items': [
          {
            'tier': 'supportedUnderstanding',
            'attributedTo': 'Augustine',
            'text': 'Some early readers saw the valley as death\u2019s shadow.',
          },
          {
            'tier': 'clearlyStated',
            'text': 'The text states the LORD is the psalmist\u2019s shepherd.',
          },
          {
            'tier': 'mysteryTier',
            'text': 'An unknown tier must be dropped.',
          },
        ],
      },
      'structuredObservations': {
        'observations': [
          {'startVerse': 1, 'endVerse': 1, 'text': 'Opens by naming the LORD.'},
          {'startVerse': 3, 'endVerse': 3, 'text': 'Restores and leads.'},
          {
            'startVerse': 5,
            'endVerse': 5,
            'text': 'Outside the studied passage — dropped.',
          },
        ],
      },
    };

void main() {
  final canon = loadTestCanon();

  // The validator needs a live canon; build it with the real one.
  DelveValidator withCanon() => DelveValidator(canon: canon);

  group('DelveValidator.validate', () {
    test('accepts a complete deep note in English', () {
      final result = withCanon().validate(raw: _enPayload(), request: _request());
      expect(result, isNotNull);
      expect(result!.isAvailable, isTrue);
      expect(result.source, DelveSource.gemini);
      expect(result.sections.length, 6);
      expect(
        result.sections.map((s) => s.kind),
        containsAll(DelveSectionKind.values),
      );
    });

    test('drops invalid history labels, terms, tiers, and references', () {
      final result = withCanon().validate(raw: _enPayload(), request: _request());
      expect(result, isNotNull);
      final history = result!.sections
          .firstWhere((s) => s.kind == DelveSectionKind.expandedHistory);
      expect(history.historyEntries.length, 2); // bogus label dropped

      final language = result.sections
          .firstWhere((s) => s.kind == DelveSectionKind.originalLanguage);
      expect(language.terms.length, 1); // unknown language dropped

      final refs = result.sections
          .firstWhere((s) => s.kind == DelveSectionKind.expandedCrossReferences);
      expect(refs.references.length, 1); // out-of-canon chapter dropped
      expect(refs.references.single.bookId, 'john'); // USFM 'jhn' resolved

      final interpretations = result.sections.firstWhere(
          (s) => s.kind == DelveSectionKind.documentedInterpretations);
      expect(interpretations.interpretations.length, 2); // unknown tier dropped
    });

    test('keeps only observations inside the studied passage', () {
      final result = withCanon().validate(raw: _enPayload(), request: _request());
      final observations = result!.sections
          .firstWhere((s) => s.kind == DelveSectionKind.structuredObservations);
      expect(observations.observations.length, 2); // verse 5 dropped
      expect(
        observations.observations.every((o) => o.endVerse <= 4),
        isTrue,
      );
    });

    test('accepts a complete deep note in Amharic', () {
      final payload = <String, dynamic>{
        'expandedHistory': {
          'text': _am2,
          'entries': [
            {'label': 'author', 'category': 'probable', 'text': _am2},
          ],
        },
        'literaryAnalysis': {'text': 'ደረጃ 1 — ጽሑፉ በመተማመን ይከፈታል።'},
        'originalLanguage': {
          'text': _am,
          'terms': [
            {'term': 'רֹעִי', 'language': 'hebrew', 'meaning': 'እረኛ'},
          ],
        },
        'expandedCrossReferences': {
          'items': [
            {
              'bookId': 'john',
              'chapter': 10,
              'startVerse': 11,
              'endVerse': 11,
              'priority': 0,
              'reason': 'ኢየሱስ ራሱን ጥሩ እረኛ ብሎ ጠርቷል።',
            },
          ],
        },
        'documentedInterpretations': {
          'items': [
            {'tier': 'clearlyStated', 'text': 'እግዚአብሔር እረኛ ነው።'},
          ],
        },
        'structuredObservations': {
          'observations': [
            {'startVerse': 1, 'endVerse': 1, 'text': _am},
          ],
        },
      };
      final result =
          withCanon().validate(raw: payload, request: _request(am: true));
      expect(result, isNotNull);
      expect(result!.sections.length, 6);
      final history = result.sections
          .firstWhere((s) => s.kind == DelveSectionKind.expandedHistory);
      expect(history.textFor(true), _am2);
    });

    test('a banned phrase anywhere rejects the entire deep note', () {
      final payload = _enPayload();
      (payload['expandedHistory'] as Map<String, dynamic>)['text'] =
          'God is telling you to trust Him in the valley.';
      final result = withCanon().validate(raw: payload, request: _request());
      expect(result, isNull);
    });

    test('drops a whole deep note that has no honest sections', () {
      final result = withCanon().validate(
        raw: const {'expandedHistory': {'text': ''}},
        request: _request(),
      );
      expect(result, isNull);
    });

    test('rejects a runaway block while keeping the honest rest', () {
      final payload = _enPayload();
      (payload['literaryAnalysis'] as Map<String, dynamic>)['text'] =
          List.filled(900, 'padding').join(' '); // far over the hard cap
      final result = withCanon().validate(raw: payload, request: _request());
      expect(result, isNotNull);
      expect(
        result!.sections.any((s) => s.kind == DelveSectionKind.literaryAnalysis),
        isFalse,
      );
      expect(result.sections.length, greaterThanOrEqualTo(5));
    });

    test('swaps reader-language content across the en/am seam', () {
      final en = withCanon().validate(raw: _enPayload(), request: _request());
      expect(en!.sections.first.textFor(false), en.sections.first.en);
      expect(en.sections.first.textFor(true), en.sections.first.am);
    });
  });
}