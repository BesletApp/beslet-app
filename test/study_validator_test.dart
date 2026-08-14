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
      'passageOverview': {
        'text': 'A psalm of David, a song of trust in the LORD.',
      },
      'historicalBackground': {
        'text': 'A psalm of David, a man who knew shepherding.',
        'entries': [
          {
            'label': 'author',
            'category': 'probable',
            'text': 'Tradition ascribes this psalm to David, a shepherd-king.',
          },
        ],
      },
      'literaryContext': {
        'text': 'The psalm moves from provision to presence in the valley.',
      },
      'verseByVerse': {
        'observations': [
          {
            'startVerse': 1,
            'endVerse': 1,
            'text': "The LORD is named as the psalmist's shepherd.",
          },
          {
            'startVerse': 2,
            'endVerse': 3,
            'text': 'He leads, feeds, and restores.',
          },
        ],
      },
      'originalLanguage': {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          {
            'term': 'רֹעִי',
            'language': 'hebrew',
            'transliteration': 'ro’i',
            'meaning': 'shepherd',
          },
        ],
      },
      'scriptureInterconnections': {
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
      'explicitTeachings': {
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
      'questionsToCarry': {
        'text': "Where do you need the Shepherd's presence?",
      },
      'anchor': {
        'image': 'a shepherd leading by still waters',
        'keyword': 'shepherd',
        'sentence':
            'The LORD stays close as the psalm moves through the valley.',
      },
    };

Map<String, dynamic> _amPayload() => {
      'passageOverview': {'text': _am},
      'historicalBackground': {
        'text': _am2,
        'entries': [
          {'label': 'author', 'category': 'probable', 'text': _am2},
        ],
      },
      'literaryContext': {'text': _am2},
      'verseByVerse': {
        'observations': [
          {'startVerse': 1, 'endVerse': 1, 'text': _am},
        ],
      },
      'originalLanguage': {
        'text': _am,
        'terms': [
          {'term': 'רֹעִי', 'language': 'hebrew', 'meaning': 'እረኛ'},
        ],
      },
      'scriptureInterconnections': {
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
      'explicitTeachings': {
        'blocks': [
          {'tier': 'clearlyStated', 'text': _am},
        ],
      },
      'questionsToCarry': {'text': 'እረኛው የት ያስፈልገኛል?'},
      'anchor': {'image': _am2, 'keyword': _am, 'sentence': _am2},
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
        StudySectionKind.values
            .where((k) => result.sections.any((s) => s.kind == k)),
        reason:
            'the note must follow Overview → Historical → Literary → Verse → '
            'Language → Scripture → Teachings → Questions',
      );
    });

    test('historical entries keep their label, category, and reader language',
        () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      final history = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.historicalBackground);
      expect(history.historyEntries, isNotEmpty);
      final entry = history.historyEntries.single;
      expect(entry.label, StudyHistoryLabel.author);
      expect(entry.category, StudyHistoryCategory.probable);
      expect(entry.textFor(false), contains('David'));
    });

    test('a historical entry with an unknown label or category is dropped', () {
      final raw = _enPayload();
      (raw['historicalBackground'] as Map)['entries'] = [
        {
          'label': 'author',
          'category': 'probable',
          'text': 'Tradition ascribes this psalm to David.',
        },
        {
          'label': 'not_a_label',
          'category': 'probable',
          'text': 'This entry must be dropped.',
        },
        {
          'label': 'author',
          'category': 'not_a_category',
          'text': 'This entry must be dropped too.',
        },
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final history = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.historicalBackground);
      expect(history.historyEntries.length, 1);
    });

    test('verse-by-verse keeps only in-passage observations', () {
      final raw = _enPayload();
      (raw['verseByVerse'] as Map)['observations'] = [
        {'startVerse': 1, 'endVerse': 1, 'text': 'Inside the passage.'},
        {'startVerse': 5, 'endVerse': 5, 'text': 'Outside the passage.'},
        {'startVerse': 1, 'endVerse': 5, 'text': 'Spans too many verses.'},
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final verses = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.verseByVerse);
      expect(verses.verseObservations.length, 1);
      expect(verses.verseObservations.single.startVerse, 1);
    });

    test('terms attach to originalLanguage and answer in the reader language',
        () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      final section = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.originalLanguage);
      expect(section.terms, isNotEmpty);
      expect(section.terms.single.term, 'רֹעִי');
      expect(section.terms.single.meaningFor(false), 'shepherd');
    });

    test('an invalid term is dropped; a valid one survives', () {
      final raw = _enPayload();
      raw['originalLanguage'] = {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          {'term': 'רֹעִי', 'language': 'hebrew', 'meaning': 'shepherd'},
          {'term': '', 'language': 'hebrew', 'meaning': 'empty term'},
          {'term': 'x' * 100, 'language': 'hebrew', 'meaning': 'too long'},
          {
            'term': 'ΔΟΞΑ',
            'language': 'madeuplang',
            'meaning': 'unknown language',
          },
          {'term': 'λόγος', 'language': 'greek', 'meaning': 'የተሳሳተ ፊደል'},
        ],
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final section = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.originalLanguage);
      expect(section.terms.length, 1);
      expect(section.terms.single.term, 'רֹעִי');
    });

    test('terms are capped at maxTerms', () {
      final raw = _enPayload();
      raw['originalLanguage'] = {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          for (var i = 0; i < StudyLengthBudget.maxTerms + 3; i++)
            {'term': 'word$i', 'language': 'greek', 'meaning': 'a meaning'},
        ],
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final section = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.originalLanguage);
      expect(section.terms.length, StudyLengthBudget.maxTerms);
    });

    test('a banned phrase inside a term meaning rejects the result', () {
      final raw = _enPayload();
      raw['originalLanguage'] = {
        'text': 'A shepherd leads, feeds, and protects the flock.',
        'terms': [
          {'term': 'word', 'language': 'greek', 'meaning': 'God wants you to.'},
        ],
      };
      expect(validator.validate(raw: raw, request: _request()), isNull);
    });

    test('invalid cross-references are dropped, valid ones kept', () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      final refs = result.sections
          .firstWhere(
              (s) => s.kind == StudySectionKind.scriptureInterconnections)
          .references;
      expect(refs.length, 1, reason: 'out-of-range chapter must be dropped');
      expect(refs.single.bookId, 'john');
      expect(refs.single.referenceFor(false), 'John 10:11');
      expect(refs.single.priority, 0);
    });

    test('USFM and abbreviated bookIds are resolved to canonical ids', () {
      final raw = _enPayload();
      (raw['scriptureInterconnections'] as Map)['items'] = [
        {
          'bookId': 'JHN',
          'chapter': 10,
          'startVerse': 11,
          'endVerse': 11,
          'priority': 0,
          'reason': 'Jesus calls Himself the good Shepherd.',
        },
        {
          'bookId': 'Ps.',
          'chapter': 95,
          'startVerse': 7,
          'endVerse': 7,
          'priority': 1,
          'reason': 'The people are the sheep of His hand.',
        },
        {
          'bookId': '1 Cor',
          'chapter': 15,
          'startVerse': 20,
          'endVerse': 20,
          'priority': 1,
          'reason': 'Christ is the firstfruits of those who sleep.',
        },
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final refs = result.sections
          .firstWhere(
              (s) => s.kind == StudySectionKind.scriptureInterconnections)
          .references;
      expect(refs.map((r) => r.bookId).toSet(),
          {'john', 'psalms', '1corinthians'});
      expect(refs.any((r) => r.referenceFor(false) == 'John 10:11'), isTrue);
    });

    test('an unknown bookId is dropped, valid ones survive', () {
      final raw = _enPayload();
      (raw['scriptureInterconnections'] as Map)['items'] = [
        {
          'bookId': 'john',
          'chapter': 10,
          'startVerse': 11,
          'endVerse': 11,
          'priority': 0,
          'reason': 'Jesus calls Himself the good Shepherd.',
        },
        {
          'bookId': 'Harambe',
          'chapter': 1,
          'startVerse': 1,
          'endVerse': 1,
          'priority': 1,
          'reason': 'Not a real book.',
        },
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final refs = result.sections
          .firstWhere(
              (s) => s.kind == StudySectionKind.scriptureInterconnections)
          .references;
      expect(refs.length, 1);
      expect(refs.single.bookId, 'john');
    });

    test('a section over the hard cap is dropped; honest sections survive', () {
      final raw = _enPayload();
      raw['literaryContext'] = {
        'text': 'word ' * (StudyLengthBudget.literaryContextMax * 3),
      };
      final result = validator.validate(raw: raw, request: _request());
      expect(result, isNotNull);
      expect(
        result!.sections
            .any((s) => s.kind == StudySectionKind.literaryContext),
        isFalse,
        reason: 'the over-budget section must be dropped',
      );
      expect(
        result.sections.any((s) => s.kind == StudySectionKind.originalLanguage),
        isTrue,
      );
    });

    test('a banned authority phrase rejects the result', () {
      final raw = _enPayload();
      raw['explicitTeachings'] = {
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
            'passageOverview': {'text': ''},
            'scriptureInterconnections': {'items': []},
          },
          request: _request(),
        ),
        isNull,
      );
    });

    test('a cross-reference with a missing reason is dropped', () {
      final raw = _enPayload();
      (raw['scriptureInterconnections'] as Map)['items'] = [
        {'bookId': 'john', 'chapter': 10, 'startVerse': 11, 'endVerse': 11},
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final refs = result.sections
          .where((s) => s.kind == StudySectionKind.scriptureInterconnections);
      expect(refs.isEmpty, isTrue);
    });

    test('a cross-reference whose verse is outside the canon is dropped', () {
      final raw = _enPayload();
      (raw['scriptureInterconnections'] as Map)['items'] = [
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
          .where((s) => s.kind == StudySectionKind.scriptureInterconnections);
      expect(refs.isEmpty, isTrue,
          reason: 'a verse outside the canon must never render');
    });

    test('a cross-reference with an out-of-range priority is dropped', () {
      final raw = _enPayload();
      (raw['scriptureInterconnections'] as Map)['items'] = [
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
          .where((s) => s.kind == StudySectionKind.scriptureInterconnections);
      expect(refs.isEmpty, isTrue);
    });

    test('a questionsToCarry that is not a question is dropped', () {
      final raw = _enPayload();
      raw['questionsToCarry'] = {'text': 'Rest in the shepherd.'};
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections
            .any((s) => s.kind == StudySectionKind.questionsToCarry),
        isFalse,
        reason: 'the question must be open-ended, never a directive',
      );
    });

    test('a questionsToCarry with two questions is kept', () {
      final raw = _enPayload();
      raw['questionsToCarry'] = {
        'text':
            'Where do you need the Shepherd’s presence? What would change if you remembered He walks with you?'
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final questions = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.questionsToCarry);
      expect(questions.en, contains('What would change'));
    });

    test('a questionsToCarry with three questions is dropped', () {
      final raw = _enPayload();
      raw['questionsToCarry'] = {
        'text': 'Where are you? What do you see? Why does it matter?'
      };
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections
            .any((s) => s.kind == StudySectionKind.questionsToCarry),
        isFalse,
        reason: 'a run-on list of questions changes the reader\'s posture',
      );
    });

    test('tiered blocks: invalid tiers are dropped, valid ones kept', () {
      final raw = _enPayload();
      (raw['explicitTeachings'] as Map)['blocks'] = [
        {'tier': 'clearlyStated', 'text': 'A clear claim from the text itself.'},
        {'tier': 'not_a_tier', 'text': 'This must be dropped.'},
      ];
      final result = validator.validate(raw: raw, request: _request())!;
      final blocks = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.explicitTeachings)
          .blocks;
      expect(blocks.length, 1);
      expect(blocks.single.tier, StudyTier.clearlyStated);
    });

    test('tiered blocks: an empty block list is omitted', () {
      final raw = _enPayload();
      raw['explicitTeachings'] = {'blocks': []};
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections
            .any((s) => s.kind == StudySectionKind.explicitTeachings),
        isFalse,
      );
    });

    test('a valid memory anchor is kept', () {
      final result = validator.validate(raw: _enPayload(), request: _request())!;
      expect(result.anchor, isNotNull);
      expect(result.anchor!.imageFor(false), contains('shepherd'));
      expect(result.anchor!.keywordFor(false), 'shepherd');
    });

    test('an anchor whose fields are all empty is omitted', () {
      final raw = _enPayload();
      raw['anchor'] = {'image': '', 'keyword': '', 'sentence': ''};
      final result = validator.validate(raw: raw, request: _request())!;
      expect(result.anchor, isNull);
    });

    test('an anchor whose sentence is a question keeps only the honest fields',
        () {
      final raw = _enPayload();
      raw['anchor'] = {
        'image': 'a shepherd by still waters',
        'keyword': 'presence',
        'sentence': 'Is the LORD your shepherd?',
      };
      final result = validator.validate(raw: raw, request: _request())!;
      expect(result.anchor, isNotNull);
      expect(result.anchor!.sentenceFor(false), isEmpty,
          reason: 'the anchor is an observation, never a question');
      expect(result.anchor!.keywordFor(false), 'presence');
    });
  });

  group('StudyValidator (Amharic)', () {
    test("a Ge'ez payload fills only the Amharic side", () {
      final result =
          validator.validate(raw: _amPayload(), request: _request(am: true));
      expect(result, isNotNull);
      final literary = result!.sections
          .firstWhere((s) => s.kind == StudySectionKind.literaryContext);
      expect(literary.en.trim(), isEmpty);
      expect(literary.am.trim(), isNotEmpty);
    });

    test('Latin text in an Amharic request is dropped per section', () {
      final raw = _amPayload();
      raw['literaryContext'] = {'text': 'The Lord is my shepherd.'};
      final result = validator.validate(raw: raw, request: _request(am: true));
      expect(result, isNotNull);
      expect(
        result!.sections
            .any((s) => s.kind == StudySectionKind.literaryContext),
        isFalse,
        reason: 'the Latin section must be dropped from an Amharic note',
      );
      expect(
        result.sections.any((s) => s.kind == StudySectionKind.originalLanguage),
        isTrue,
      );
    });

    test("Ge'ez text in an English request is rejected", () {
      expect(validator.validate(raw: _amPayload(), request: _request()), isNull);
    });

    test('an Amharic banned phrase rejects the result', () {
      final raw = _amPayload();
      raw['literaryContext'] = {'text': 'እግዚአብሔር ይነግርሃል ይህን ልታደርግ።'};
      expect(validator.validate(raw: raw, request: _request(am: true)), isNull);
    });
  });

  group('movement steps, bullets & threads', () {
    test('labeled movement steps are kept in literaryContext', () {
      final raw = _enPayload();
      raw['literaryContext'] = {
        'text': 'Step 1 — The psalm opens with the LORD as shepherd.\n'
            'Step 2 — It moves through the valley without fear.\n'
            'Step 3 — It ends in the house of the LORD.',
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final kept = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.literaryContext);
      expect(kept.textFor(false), contains('Step 3 —'));
    });

    test('a step heading without a body is rejected, dropping the section', () {
      final raw = _enPayload();
      raw['literaryContext'] = {'text': 'Step — let us trace the movement.'};
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections
            .any((s) => s.kind == StudySectionKind.literaryContext),
        isFalse,
        reason: 'a malformed step heading must not reach the reader',
      );
    });

    test('more than five steps drops the section', () {
      final raw = _enPayload();
      raw['literaryContext'] = {
        'text': List.generate(6, (i) => 'Step ${i + 1} — one sentence.')
            .join('\n'),
      };
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections
            .any((s) => s.kind == StudySectionKind.literaryContext),
        isFalse,
        reason: 'a runaway step list is a violation, not a style slip',
      );
    });

    test('real bullet rows are kept; a dash is plain prose', () {
      final raw = _enPayload();
      raw['literaryContext'] = {
        'text': '• The shepherd provides and restores.\n• He stays present.',
      };
      final result = validator.validate(raw: raw, request: _request())!;
      expect(result, isNotNull);
    });

    test('a malformed bullet row (no space after the bullet) drops the section',
        () {
      final raw = _enPayload();
      raw['literaryContext'] = {'text': '•First point\nSecond paragraph.'};
      final result = validator.validate(raw: raw, request: _request())!;
      expect(
        result.sections
            .any((s) => s.kind == StudySectionKind.literaryContext),
        isFalse,
      );
    });

    test('a well-formed optional threads line is kept on questionsToCarry', () {
      final raw = _enPayload();
      raw['questionsToCarry'] = {
        'text': "Where do you need the Shepherd's presence?",
        'threads':
            'The passage itself presents the LORD as a personal shepherd.',
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final questions = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.questionsToCarry);
      expect(questions.subTextFor(false),
          'The passage itself presents the LORD as a personal shepherd.');
    });

    test('a question-shaped threads line is dropped, questions kept', () {
      final raw = _enPayload();
      raw['questionsToCarry'] = {
        'text': "Where do you need the Shepherd's presence?",
        'threads': 'Is the LORD your shepherd?',
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final questions = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.questionsToCarry);
      expect(questions.subTextFor(false), isNull);
    });

    test('an over-long threads line is dropped, questions kept', () {
      final raw = _enPayload();
      raw['questionsToCarry'] = {
        'text': "Where do you need the Shepherd's presence?",
        'threads': List.filled(45, 'word').join(' '),
      };
      final result = validator.validate(raw: raw, request: _request())!;
      final questions = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.questionsToCarry);
      expect(questions.subTextFor(false), isNull);
    });

    test('a threads line in the wrong script is dropped, questions kept', () {
      final raw = _amPayload();
      raw['questionsToCarry'] = {
        'text': 'በዚህ መዝሙር ውስጥ ምን ትመለከታለህ?',
        'threads': 'The passage itself presents the LORD as a shepherd.',
      };
      final result = validator.validate(raw: raw, request: _request(am: true))!;
      final questions = result.sections
          .firstWhere((s) => s.kind == StudySectionKind.questionsToCarry);
      expect(questions.subTextFor(true), isNull);
      expect(questions.textFor(true), contains('ትመለከታለህ'));
    });

    test('a directive threads line rejects the entire note', () {
      final raw = _enPayload();
      raw['questionsToCarry'] = {
        'text': "Where do you need the Shepherd's presence?",
        'threads': 'God wants you to trust Him today.',
      };
      expect(validator.validate(raw: raw, request: _request()), isNull);
    });
  });

  group('voice boundaries', () {
    test('promotional hype rejects the entire note', () {
      final raw = _enPayload();
      raw['literaryContext'] = {
        'text': 'This is a life-changing promise for every reader.',
      };
      expect(validator.validate(raw: raw, request: _request()), isNull);
    });

    test('denominational posturing rejects the entire note', () {
      final raw = _enPayload();
      raw['historicalBackground'] = {
        'text': 'The Catholic Church teaches otherwise.',
      };
      expect(validator.validate(raw: raw, request: _request()), isNull);
    });

    test('a second-person directive rejects the entire note', () {
      final raw = _enPayload();
      raw['passageOverview'] = {'text': 'You should read this psalm slowly.'};
      expect(validator.validate(raw: raw, request: _request()), isNull);
    });
  });
}
