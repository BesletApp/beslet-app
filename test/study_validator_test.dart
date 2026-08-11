import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_prompt.dart';
import 'package:beslet_app/core/ai/study/study_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

const _am = 'እግዚአብሔር እረኛዬ ነው።';
const _am2 = 'በሸለቆ ውስጥ እንኳን አልፈራም።';

StudyRequest _request({bool am = false}) => StudyRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 3),
      isAmharic: am,
      verseTexts: const ['a', 'b', 'c'],
    );

Map<String, dynamic> _enPayload() => {
      'setting': {'text': 'A psalm of David, a song of trust in the LORD.'},
      'context': {
        'behindTheText': 'A psalm of David, a man who knew shepherding.',
        'inTheText': 'The psalm moves from provision to presence in the valley.',
      },
      'whatTextSays': {
        'text': 'The LORD is a caring shepherd who provides and guides.',
      },
      'meaningBackground': {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          {'term': 'רֹעִי', 'language': 'hebrew', 'transliteration': 'ro’i', 'meaning': 'shepherd'},
        ],
      },
      'reflection': {'text': "Where do you need the Shepherd's presence?"},
      'biblicalConnections': {
        'items': [
          {
            'bookId': 'john',
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
            'reason': 'Out of range chapter — must be dropped.',
          },
        ],
      },
      'whatCanBeUnderstood': {
        'blocks': [
          {
            'tier': 'clearlyStated',
            'text': 'God is presented as a personal keeper.',
          },
          {
            'tier': 'supportedUnderstanding',
            'text': 'Many read the valley as a time of trial.',
          },
        ],
      },
    };

Map<String, dynamic> _amPayload() => {
      'setting': {'text': _am},
      'context': {'behindTheText': _am2, 'inTheText': _am2},
      'whatTextSays': {'text': _am},
      'meaningBackground': {
        'text': _am,
        'terms': [
          {'term': 'רֹעִי', 'language': 'hebrew', 'meaning': 'እረኛ'},
        ],
      },
      'reflection': {'text': 'እረኛው የት ያስፈልገኛል?'},
      'biblicalConnections': {
        'items': [
          {
            'bookId': 'john',
            'chapter': 10,
            'startVerse': 11,
            'endVerse': 11,
            'priority': 0,
            'reason': 'ኢየሱስ ጥሩ እረኛ ነው።',
          },
        ],
      },
      'whatCanBeUnderstood': {
        'blocks': [
          {'tier': 'clearlyStated', 'text': _am},
        ],
      },
    };

void main() {
  final validator = StudyValidator(canon: loadTestCanon());

  group('StudyValidator (English)', () {
    test('a well-formed payload becomes a gemini StudyResult', () {
      final result = validator.validate(raw: _enPayload(), request: _request());
      expect(result, isNotNull);
      expect(result!.source, StudySource.gemini);
      expect(result.isAvailable, isTrue);
      final kinds = result.sections.map((s) => s.kind).toSet();
      expect(kinds, StudySectionKind.values.toSet(),
          reason: 'every section kind must be present');
    });

    test('sections render in canonical enum order', () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      expect(
        result.sections.map((s) => s.kind).toList(),
        StudySectionKind.values.where(
          (k) => result.sections.any((s) => s.kind == k),
        ),
        reason: 'the note must follow Setting → Context → … → Reflection',
      );
    });

    test('terms attach to meaningBackground and answer in the reader language',
        () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      final section = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.meaningBackground);
      expect(section.terms, isNotEmpty);
      expect(section.terms.single.term, 'רֹעִי');
      expect(section.terms.single.meaningFor(false), 'shepherd');
    });

    test('an invalid term is dropped; a valid one survives', () {
      final raw = _enPayload();
      raw['meaningBackground'] = {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          {'term': 'רֹעִי', 'language': 'hebrew', 'meaning': 'shepherd'},
          {'term': '', 'language': 'hebrew', 'meaning': 'empty term'},
          {'term': 'x' * 100, 'language': 'hebrew', 'meaning': 'too long'},
          {'term': 'ΔΟΞΑ', 'language': 'madeuplang', 'meaning': 'unknown language'},
          {'term': 'λόγος', 'language': 'greek', 'meaning': 'የተሳሳተ ፊደል'},
        ],
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final section = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.meaningBackground);
      expect(section.terms.length, 1);
      expect(section.terms.single.term, 'רֹעִי');
    });

    test('terms are capped at maxTerms', () {
      final raw = _enPayload();
      raw['meaningBackground'] = {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          for (var i = 0; i < StudyLengthBudget.maxTerms + 3; i++)
            {'term': 'word$i', 'language': 'greek', 'meaning': 'a meaning'},
        ],
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final section = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.meaningBackground);
      expect(section.terms.length, StudyLengthBudget.maxTerms);
    });

    test('a banned phrase inside a term meaning rejects the result', () {
      final raw = _enPayload();
      raw['meaningBackground'] = {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          {'term': 'word', 'language': 'greek', 'meaning': 'God wants you to.'},
        ],
      };
      expect(validator.validate(raw: raw, request: _request()), isNull);
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
          .firstWhere((s) => s.kind == StudySectionKind.biblicalConnections)
          .references;
      expect(refs.length, 1, reason: 'out-of-range chapter must be dropped');
      expect(refs.single.bookId, 'john');
      expect(refs.single.referenceFor(false), 'John 10:11');
      expect(refs.single.priority, 0);
    });

    test('a section over the hard cap is dropped; honest sections survive',
        () {
      final raw = _enPayload();
      raw['whatTextSays'] = {
        'text': 'word ' * (StudyLengthBudget.whatTextSaysMax * 3),
      };
      final result = validator.validate(raw: raw, request: _request());
      expect(result, isNotNull);
      expect(
        result!.sections.any((s) => s.kind == StudySectionKind.whatTextSays),
        isFalse,
        reason: 'the over-budget section must be dropped',
      );
      expect(
        result.sections.any((s) => s.kind == StudySectionKind.meaningBackground),
        isTrue,
      );
    });

    test('a banned authority phrase rejects the result', () {
      final raw = _enPayload();
      raw['whatCanBeUnderstood'] = {
        'blocks': [
          {'tier': 'clearlyStated', 'text': 'God wants you to do this.'},
        ],
      };
      expect(validator.validate(raw: raw, request: _request()), isNull);
    });

    test('an empty result is rejected (nothing honest to say)', () {
      expect(
        validator.validate(
          raw: {
            'whatTextSays': {'text': ''},
            'biblicalConnections': {'items': []},
          },
          request: _request(),
        ),
        isNull,
      );
    });

    test('a cross-reference with a missing reason is dropped', () {
      final raw = _enPayload();
      (raw['biblicalConnections'] as Map)['items'] = [
        {'bookId': 'john', 'chapter': 10, 'startVerse': 11, 'endVerse': 11},
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final refs = result.sections
          .where((s) => s.kind == StudySectionKind.biblicalConnections);
      expect(refs.isEmpty, isTrue);
    });

    test('a cross-reference whose verse is outside the canon is dropped', () {
      final raw = _enPayload();
      (raw['biblicalConnections'] as Map)['items'] = [
        {
          'bookId': 'john',
          'chapter': 3,
          'startVerse': 36,
          'endVerse': 37,
          'priority': 0,
          'reason': 'John 3 ends at verse 36, so 37 does not exist.',
        },
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final refs = result.sections
          .where((s) => s.kind == StudySectionKind.biblicalConnections);
      expect(refs.isEmpty, isTrue,
          reason: 'a verse outside the canon must never render');
    });

    test('a cross-reference with an out-of-range priority is dropped', () {
      final raw = _enPayload();
      (raw['biblicalConnections'] as Map)['items'] = [
        {
          'bookId': 'john',
          'chapter': 10,
          'startVerse': 11,
          'endVerse': 11,
          'priority': 3,
          'reason': 'Priority must be 0-2.',
        },
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final refs = result.sections
          .where((s) => s.kind == StudySectionKind.biblicalConnections);
      expect(refs.isEmpty, isTrue);
    });

    test('a reflection that is not a question is dropped', () {
      final raw = _enPayload();
      raw['reflection'] = {'text': 'Rest in the shepherd.'};
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections.any((s) => s.kind == StudySectionKind.reflection),
        isFalse,
        reason: 'the reflection must be a question, never a directive',
      );
    });

    test('a reflection with two questions is kept', () {
      final raw = _enPayload();
      raw['reflection'] = {
        'text':
            'Where do you need the Shepherd’s presence? What would change if you remembered He walks with you?'
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final reflection = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.reflection);
      expect(reflection.en, contains('What would change'));
    });

    test('a reflection with three questions is dropped', () {
      final raw = _enPayload();
      raw['reflection'] = {
        'text': 'Where are you? What do you see? Why does it matter?'
      };
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections.any((s) => s.kind == StudySectionKind.reflection),
        isFalse,
        reason: 'a run-on list of questions changes the reader\'s posture',
      );
    });

    test('tiered blocks: invalid tiers are dropped, valid ones kept', () {
      final raw = _enPayload();
      (raw['whatCanBeUnderstood'] as Map)['blocks'] = [
        {'tier': 'clearlyStated', 'text': 'A clear claim from the text itself.'},
        {'tier': 'not_a_tier', 'text': 'This must be dropped.'},
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final blocks = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.whatCanBeUnderstood)
          .blocks;
      expect(blocks.length, 1);
      expect(blocks.single.tier, StudyTier.clearlyStated);
    });

    test('tiered blocks: an empty block list is omitted', () {
      final raw = _enPayload();
      raw['whatCanBeUnderstood'] = {'blocks': []};
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections.any((s) => s.kind == StudySectionKind.whatCanBeUnderstood),
        isFalse,
      );
    });
  });

  group('StudyValidator (Amharic)', () {
    test("a Ge'ez payload fills only the Amharic side", () {
      final result = validator.validate(raw: _amPayload(), request: _request(am: true));
      expect(result, isNotNull);
      final summary = result!.sections
          .firstWhere((s) => s.kind == StudySectionKind.whatTextSays);
      expect(summary.en.trim(), isEmpty);
      expect(summary.am.trim(), isNotEmpty);
    });

    test('Latin text in an Amharic request is dropped per section', () {
      final raw = _amPayload();
      raw['whatTextSays'] = {'text': 'The Lord is my shepherd.'};
      final result = validator.validate(raw: raw, request: _request(am: true));
      expect(result, isNotNull);
      expect(
        result!.sections.any((s) => s.kind == StudySectionKind.whatTextSays),
        isFalse,
        reason: 'the Latin summary must be dropped from an Amharic note',
      );
      expect(
        result.sections.any((s) => s.kind == StudySectionKind.meaningBackground),
        isTrue,
      );
    });

    test("Ge'ez text in an English request is rejected", () {
      expect(
        validator.validate(raw: _amPayload(), request: _request()),
        isNull,
      );
    });

    test('an Amharic banned phrase rejects the result', () {
      final raw = _amPayload();
      raw['whatTextSays'] = {'text': 'እግዚአብሔር ይነግርሃል ይህን ልታደርግ።'};
      expect(validator.validate(raw: raw, request: _request(am: true)), isNull);
    });
  });
}
