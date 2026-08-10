import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_prompt.dart';
import 'package:beslet_app/core/ai/study/study_validator.dart';
import 'package:flutter_test/flutter_test.dart';

const _am = 'እግዚአብሔር እረኛዬ ነው።';
const _am2 = 'በሸለቆ ውስጥ እንኳን አልፈራም።';

StudyRequest _request({bool am = false}) => StudyRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 3),
      isAmharic: am,
      verseTexts: const ['a', 'b', 'c'],
    );

Map<String, dynamic> _enPayload() => {
      'summary': {'text': 'The Lord is a caring shepherd who provides and guides.'},
      'context': {
        'behindTheText': 'A psalm of David, a man who knew shepherding.',
        'inTheText': 'The psalm moves from provision to presence in the valley.',
      },
      'observations': {'text': 'Notice the verbs: leads, restores, guides.'},
      'teachings': {'text': 'God provides what we truly need (v. 1).'},
      'reflection': {'text': "Where do you need the Shepherd's presence?"},
      'crossReferences': {
        'items': [
          {
            'bookId': 'john',
            'chapter': 10,
            'startVerse': 11,
            'endVerse': 11,
            'reason': 'Jesus calls Himself the good Shepherd.',
          },
          {
            'bookId': 'psalms',
            'chapter': 999,
            'startVerse': 1,
            'endVerse': 1,
            'reason': 'Out of range chapter — must be dropped.',
          },
        ],
      },
    };

Map<String, dynamic> _amPayload() => {
      'summary': {'text': _am},
      'context': {'behindTheText': _am2, 'inTheText': _am2},
      'observations': {'text': _am},
      'teachings': {'text': _am},
      'reflection': {'text': _am},
      'crossReferences': {
        'items': [
          {
            'bookId': 'john',
            'chapter': 10,
            'startVerse': 11,
            'endVerse': 11,
            'reason': 'ኢየሱስ ጥሩ እረኛ ነው።',
          },
        ],
      },
    };

void main() {
  const validator = StudyValidator();

  group('StudyValidator (English)', () {
    test('a well-formed payload becomes a gemini StudyResult', () {
      final result = validator.validate(raw: _enPayload(), request: _request());
      expect(result, isNotNull);
      expect(result!.source, StudySource.gemini);
      expect(result.isAvailable, isTrue);
      final kinds = result.sections.map((s) => s.kind).toSet();
      expect(kinds, containsAll(StudySectionKind.values));
    });

    test('context keeps both halves; in-the-text lands in enSub', () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      final context = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.context);
      expect(context.textFor(false), 'A psalm of David, a man who knew shepherding.');
      expect(context.subTextFor(false), contains('moves from provision'));
    });

    test('invalid cross-references are dropped, valid ones kept', () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      final refs = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.crossReferences)
          .references;
      expect(refs.length, 1, reason: 'out-of-range chapter must be dropped');
      expect(refs.single.bookId, 'john');
      expect(refs.single.referenceFor(false), 'John 10:11');
    });

    test('a section over the hard cap is dropped; honest sections survive',
        () {
      final raw = _enPayload();
      raw['summary'] = {
        'text': 'word ' * (StudyLengthBudget.summaryMax * 3),
      };
      final result = validator.validate(raw: raw, request: _request());
      expect(result, isNotNull);
      expect(
        result!.sections.any((s) => s.kind == StudySectionKind.summary),
        isFalse,
        reason: 'the over-budget section must be dropped',
      );
      expect(result.sections.any((s) => s.kind == StudySectionKind.teachings),
          isTrue);
    });

    test('a banned authority phrase rejects the result', () {
      final raw = _enPayload();
      raw['teachings'] = {'text': 'God wants you to do this.'};
      expect(validator.validate(raw: raw, request: _request()), isNull);
    });

    test('an empty result is rejected (nothing honest to say)', () {
      expect(
        validator.validate(
          raw: {
            'summary': {'text': ''},
            'crossReferences': {'items': []},
          },
          request: _request(),
        ),
        isNull,
      );
    });

    test('a cross-reference with a missing reason is dropped', () {
      final raw = _enPayload();
      (raw['crossReferences'] as Map)['items'] = [
        {'bookId': 'john', 'chapter': 10, 'startVerse': 11, 'endVerse': 11},
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final refs = result.sections
          .where((s) => s.kind == StudySectionKind.crossReferences);
      expect(refs.isEmpty, isTrue);
    });
  });

  group('StudyValidator (Amharic)', () {
    test("a Ge'ez payload fills only the Amharic side", () {
      final result = validator.validate(raw: _amPayload(), request: _request(am: true));
      expect(result, isNotNull);
      final summary = result!.sections
          .firstWhere((s) => s.kind == StudySectionKind.summary);
      expect(summary.en.trim(), isEmpty);
      expect(summary.am.trim(), isNotEmpty);
    });

    test('Latin text in an Amharic request is dropped per section', () {
      final raw = _amPayload();
      raw['summary'] = {'text': 'The Lord is my shepherd.'};
      final result = validator.validate(raw: raw, request: _request(am: true));
      expect(result, isNotNull);
      expect(
        result!.sections.any((s) => s.kind == StudySectionKind.summary),
        isFalse,
        reason: 'the Latin summary must be dropped from an Amharic note',
      );
      expect(result.sections.any((s) => s.kind == StudySectionKind.teachings),
          isTrue);
    });

    test("Ge'ez text in an English request is rejected", () {
      expect(
        validator.validate(raw: _amPayload(), request: _request()),
        isNull,
      );
    });

    test('an Amharic banned phrase rejects the result', () {
      final raw = _amPayload();
      raw['teachings'] = {'text': 'እግዚአብሔር ይነግርሃል ይህን ልታደርግ።'};
      expect(validator.validate(raw: raw, request: _request(am: true)), isNull);
    });
  });
}