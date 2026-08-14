import 'dart:io';

import 'package:beslet_app/core/ai/study/study_local_bank.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

/// Content that quietly undermines the mission (Western self-improvement,
/// gamification, prosperity, romance advice) is banned from the curated bank.
const bannedPatterns = [
  'self-care',
  'self care',
  'manifest',
  'best life',
  'prosperity',
  'wealth',
  'dating',
  'romance',
  'gamif',
  'level up',
  'life hack',
  'quick fix',
  'boost your',
  '5 steps',
  '3 steps',
  'seven steps',
  'streak',
  'score',
  'unlock',
  'achievement',
];

/// Every renderable English string in a bank entry (text + sub-halves +
/// cross-reference reasons + tiered blocks + term meanings), for the
/// banned-pattern lint.
List<String> englishStrings(StudyBankEntry entry) {
  final out = <String>[];
  for (final section in entry.sections) {
    if (section.kind == StudySectionKind.scriptureInterconnections) {
      for (final ref in section.references) {
        if (ref.en.isNotEmpty) out.add(ref.en);
      }
      continue;
    }
    if (section.kind == StudySectionKind.explicitTeachings) {
      for (final block in section.blocks) {
        if (block.en.isNotEmpty) out.add(block.en);
      }
      continue;
    }
    if (section.kind == StudySectionKind.verseByVerse) {
      for (final observation in section.verseObservations) {
        if (observation.en.isNotEmpty) out.add(observation.en);
      }
      continue;
    }
    if (section.en.isNotEmpty) out.add(section.en);
    final sub = section.enSub;
    if (sub != null && sub.isNotEmpty) out.add(sub);
  }
  final anchor = entry.anchor;
  if (anchor != null) {
    if (anchor.imageEn.isNotEmpty) out.add(anchor.imageEn);
    if (anchor.keywordEn.isNotEmpty) out.add(anchor.keywordEn);
    if (anchor.sentenceEn.isNotEmpty) out.add(anchor.sentenceEn);
  }
  return out;
}

/// Every renderable Amharic string in a bank entry (text + sub-halves +
/// cross-reference reasons + tiered blocks + term meanings).
List<String> amharicStrings(StudyBankEntry entry) {
  final out = <String>[];
  for (final section in entry.sections) {
    if (section.kind == StudySectionKind.scriptureInterconnections) {
      for (final ref in section.references) {
        if (ref.am.isNotEmpty) out.add(ref.am);
      }
      continue;
    }
    if (section.kind == StudySectionKind.explicitTeachings) {
      for (final block in section.blocks) {
        if (block.am.isNotEmpty) out.add(block.am);
      }
      continue;
    }
    if (section.kind == StudySectionKind.verseByVerse) {
      for (final observation in section.verseObservations) {
        if (observation.am.isNotEmpty) out.add(observation.am);
      }
      continue;
    }
    if (section.am.isNotEmpty) out.add(section.am);
    final sub = section.amSub;
    if (sub != null && sub.isNotEmpty) out.add(sub);
    if (section.kind == StudySectionKind.originalLanguage) {
      for (final term in section.terms) {
        if (term.am.isNotEmpty) out.add(term.am);
      }
    }
  }
  final anchor = entry.anchor;
  if (anchor != null) {
    if (anchor.imageAm.isNotEmpty) out.add(anchor.imageAm);
    if (anchor.keywordAm.isNotEmpty) out.add(anchor.keywordAm);
    if (anchor.sentenceAm.isNotEmpty) out.add(anchor.sentenceAm);
  }
  return out;
}

void main() {
  group('StudyLocalBank (shipped asset)', () {
    late StudyLocalBank bank;

    setUpAll(() {
      final raw = File('assets/data/study.json').readAsStringSync();
      bank = StudyLocalBank.fromJsonString(raw);
    });

    test('passes full content validation (fail-closed gate)', () {
      expect(bank.validate(canon: loadTestCanon(), sources: loadTestSources()),
          isEmpty,
          reason:
              'the shipped study bank must be canon- and source-clean: ${bank.validate(canon: loadTestCanon(), sources: loadTestSources())}');
    });

    test('every section carries sourceIds that resolve in the registry', () {
      final sources = loadTestSources();
      for (final entry in bank.entries) {
        for (final section in entry.sections) {
          expect(section.sourceIds, isNotEmpty,
              reason: 'entry ${entry.id} ${section.kind.name} has no sourceIds');
          for (final id in section.sourceIds) {
            expect(sources.sourceFor(id), isNotNull,
                reason:
                    'entry ${entry.id} ${section.kind.name} cites unknown source "$id"');
          }
        }
      }
    });

    test('every entry is the full eight-section workbook with a memory anchor, '
        'both languages', () {
      expect(bank.entries, isNotEmpty);
      for (final entry in bank.entries) {
        expect(entry.sections.length, 8,
            reason:
                'entry ${entry.id} must serve the eight workbook sections exactly once');
        for (final section in entry.sections) {
          if (section.kind == StudySectionKind.scriptureInterconnections) {
            expect(section.references, isNotEmpty,
                reason:
                    'entry ${entry.id} scriptureInterconnections must not be empty');
            for (final ref in section.references) {
              expect(ref.en.trim(), isNotEmpty,
                  reason:
                      'entry ${entry.id} cross-reference needs an English reason');
              expect(ref.am.trim(), isNotEmpty,
                  reason:
                      'entry ${entry.id} cross-reference needs an Amharic reason');
            }
            continue;
          }
          if (section.kind == StudySectionKind.explicitTeachings) {
            expect(section.blocks, isNotEmpty,
                reason:
                    'entry ${entry.id} explicitTeachings must not be empty');
            for (final block in section.blocks) {
              expect(block.en.trim(), isNotEmpty,
                  reason: 'entry ${entry.id} tiered block needs English');
              expect(block.am.trim(), isNotEmpty,
                  reason: 'entry ${entry.id} tiered block needs Amharic');
            }
            continue;
          }
          if (section.kind == StudySectionKind.verseByVerse) {
            expect(section.verseObservations, isNotEmpty,
                reason: 'entry ${entry.id} verseByVerse must not be empty');
            for (final observation in section.verseObservations) {
              expect(observation.en.trim(), isNotEmpty,
                  reason:
                      'entry ${entry.id} observation ${observation.startVerse}-${observation.endVerse} needs English');
              expect(observation.am.trim(), isNotEmpty,
                  reason:
                      'entry ${entry.id} observation ${observation.startVerse}-${observation.endVerse} needs Amharic');
            }
            continue;
          }
          expect(section.en.trim(), isNotEmpty,
              reason: 'entry ${entry.id} ${section.kind.name} needs English');
          expect(section.am.trim(), isNotEmpty,
              reason: 'entry ${entry.id} ${section.kind.name} needs Amharic');
          if (section.kind == StudySectionKind.questionsToCarry) {
            expect(section.enSub?.trim(), isNotEmpty,
                reason:
                    'entry ${entry.id} questionsToCarry needs the English takeaway');
            expect(section.amSub?.trim(), isNotEmpty,
                reason:
                    'entry ${entry.id} questionsToCarry needs the Amharic takeaway');
          }
        }
        final anchor = entry.anchor;
        expect(anchor, isNotNull,
            reason: 'entry ${entry.id} needs a memory anchor');
        if (anchor != null) {
          for (final field in [
            anchor.imageEn,
            anchor.imageAm,
            anchor.keywordEn,
            anchor.keywordAm,
            anchor.sentenceEn,
            anchor.sentenceAm,
          ]) {
            expect(field.trim(), isNotEmpty,
                reason: 'entry ${entry.id} anchor field must not be empty');
          }
        }
      }
    });

    test('entryFor matches on the anchored start verse', () {
      final entry = bank.entryFor('psalms', 23, 1);
      expect(entry, isNotNull);
      expect(entry!.id, 'psalm23');
      expect(entry.covers('psalms', 23, 1), isTrue);
    });

    test('entryFor returns null for a passage not in the bank', () {
      expect(bank.entryFor('genesis', 1, 1), isNull);
    });

    test('banned-pattern lint: no Western self-help framing', () {
      for (final entry in bank.entries) {
        for (final text in englishStrings(entry)) {
          final lower = text.toLowerCase();
          for (final banned in bannedPatterns) {
            expect(lower.contains(banned), isFalse,
                reason: 'entry ${entry.id} contains "$banned"');
          }
        }
      }
    });

    test('every entry is commentary-depth in both languages', () {
      for (final entry in bank.entries) {
        final en = englishStrings(entry).join(' ').split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        final am = amharicStrings(entry).join(' ').split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;
        expect(en, greaterThanOrEqualTo(200),
            reason:
                'entry ${entry.id} must be commentary depth in English, got $en words');
        expect(am, greaterThanOrEqualTo(200),
            reason:
                'entry ${entry.id} must be commentary depth in Amharic, got $am words');
      }
    });

    test('rejects a bank with a wrong version (fail closed)', () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":4,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"passageOverview","en":"a","am":"a"},'
        '{"kind":"historicalBackground","en":"a","am":"a","enSub":"b","amSub":"b"},'
        '{"kind":"literaryContext","en":"a","am":"a"},'
        '{"kind":"originalLanguage","en":"a","am":"a"},'
        '{"kind":"scriptureInterconnections","references":['
        '{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11,"en":"r","am":"r"}]},'
        '{"kind":"explicitTeachings","blocks":['
        '{"tier":"clearlyStated","en":"a","am":"a"}]},'
        '{"kind":"questionsToCarry","en":"a","am":"a","enSub":"b","amSub":"b"}]}]}',
      ).validate();
      expect(issues.any((i) => i.contains('version must be 3')), isTrue,
          reason: issues.join('\n'));
    });

    test('rejects a section with an unknown source id (fail closed)', () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":2,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"passageOverview","en":"a","am":"a","sourceIds":["nope"]},'
        '{"kind":"historicalBackground","en":"a","am":"a","enSub":"b","amSub":"b","sourceIds":["scripture"]},'
        '{"kind":"literaryContext","en":"a","am":"a","sourceIds":["scripture"]},'
        '{"kind":"originalLanguage","en":"a","am":"a","sourceIds":["scripture"]},'
        '{"kind":"scriptureInterconnections","references":['
        '{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11,"en":"r","am":"r"}],'
        '"sourceIds":["scripture"]},'
        '{"kind":"explicitTeachings","blocks":['
        '{"tier":"clearlyStated","en":"a","am":"a"}],"sourceIds":["scripture"]},'
        '{"kind":"questionsToCarry","en":"a","am":"a","enSub":"b","amSub":"b","sourceIds":["scripture"]}]}]}',
      ).validate(sources: loadTestSources());
      expect(issues.any((i) => i.contains('unknown source id "nope"')), isTrue,
          reason: issues.join('\n'));
    });

    test('rejects a section without sourceIds when the registry is provided',
        () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":2,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"passageOverview","en":"a","am":"a"},'
        '{"kind":"historicalBackground","en":"a","am":"a","enSub":"b","amSub":"b","sourceIds":["scripture"]},'
        '{"kind":"literaryContext","en":"a","am":"a","sourceIds":["scripture"]},'
        '{"kind":"originalLanguage","en":"a","am":"a","sourceIds":["scripture"]},'
        '{"kind":"scriptureInterconnections","references":['
        '{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11,"en":"r","am":"r"}],'
        '"sourceIds":["scripture"]},'
        '{"kind":"explicitTeachings","blocks":['
        '{"tier":"clearlyStated","en":"a","am":"a"}],"sourceIds":["scripture"]},'
        '{"kind":"questionsToCarry","en":"a","am":"a","enSub":"b","amSub":"b","sourceIds":["scripture"]}]}]}',
      ).validate(sources: loadTestSources());
      expect(issues.any((i) => i.contains('sourceIds required')), isTrue,
          reason: issues.join('\n'));
    });

    test('rejects a bank with an unknown book (fail closed)', () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":2,"entries":[{"id":"x","bookId":"not_a_book","chapter":1,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"passageOverview","en":"a","am":"a"},'
        '{"kind":"historicalBackground","en":"a","am":"a","enSub":"b","amSub":"b"},'
        '{"kind":"literaryContext","en":"a","am":"a"},'
        '{"kind":"originalLanguage","en":"a","am":"a"},'
        '{"kind":"scriptureInterconnections","references":['
        '{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11,"en":"r","am":"r"}]},'
        '{"kind":"explicitTeachings","blocks":['
        '{"tier":"clearlyStated","en":"a","am":"a"}]},'
        '{"kind":"questionsToCarry","en":"a","am":"a","enSub":"b","amSub":"b"}]}]}',
      ).validate();
      expect(issues.any((i) => i.contains('unknown book')), isTrue);
    });

    test('rejects a cross-reference whose chapter is out of range (fail closed)',
        () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":2,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"passageOverview","en":"a","am":"a"},'
        '{"kind":"historicalBackground","en":"a","am":"a","enSub":"b","amSub":"b"},'
        '{"kind":"literaryContext","en":"a","am":"a"},'
        '{"kind":"originalLanguage","en":"a","am":"a"},'
        '{"kind":"scriptureInterconnections","references":['
        '{"bookId":"psalms","chapter":999,"startVerse":1,"endVerse":1,"en":"r","am":"r"}]},'
        '{"kind":"explicitTeachings","blocks":['
        '{"tier":"clearlyStated","en":"a","am":"a"}]},'
        '{"kind":"questionsToCarry","en":"a","am":"a","enSub":"b","amSub":"b"}]}]}',
      ).validate();
      expect(issues.any((i) => i.contains('out of range')), isTrue,
          reason: issues.join('\n'));
    });

    test('rejects a verseByVerse observation outside the passage (fail closed)',
        () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":3,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":3,"anchor":'
        '{"imageEn":"i","imageAm":"i","keywordEn":"k","keywordAm":"k",'
        '"sentenceEn":"s","sentenceAm":"s"},'
        '"sections":['
        '{"kind":"passageOverview","en":"a","am":"a"},'
        '{"kind":"historicalBackground","en":"a","am":"a"},'
        '{"kind":"literaryContext","en":"a","am":"a"},'
        '{"kind":"verseByVerse","verseObservations":['
        '{"startVerse":1,"endVerse":1,"en":"a","am":"a"},'
        '{"startVerse":5,"endVerse":5,"en":"a","am":"a"}]},'
        '{"kind":"originalLanguage","en":"a","am":"a"},'
        '{"kind":"scriptureInterconnections","references":['
        '{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11,"en":"r","am":"r"}]},'
        '{"kind":"explicitTeachings","blocks":['
        '{"tier":"clearlyStated","en":"a","am":"a"}]},'
        '{"kind":"questionsToCarry","en":"a","am":"a","enSub":"b","amSub":"b"}]}]}',
      ).validate();
      expect(issues.any((i) => i.contains('outside the passage')), isTrue,
          reason: issues.join('\n'));
    });

    test('rejects a cross-reference whose verse is outside the canon (fail closed)',
        () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":2,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"passageOverview","en":"a","am":"a"},'
        '{"kind":"historicalBackground","en":"a","am":"a","enSub":"b","amSub":"b"},'
        '{"kind":"literaryContext","en":"a","am":"a"},'
        '{"kind":"originalLanguage","en":"a","am":"a"},'
        '{"kind":"scriptureInterconnections","references":['
        '{"bookId":"john","chapter":3,"startVerse":36,"endVerse":37,"en":"r","am":"r"}]},'
        '{"kind":"explicitTeachings","blocks":['
        '{"tier":"clearlyStated","en":"a","am":"a"}]},'
        '{"kind":"questionsToCarry","en":"a","am":"a","enSub":"b","amSub":"b"}]}]}',
      ).validate(canon: loadTestCanon());
      expect(issues.any((i) => i.contains('outside the canon')), isTrue,
          reason: issues.join('\n'));
    });
  });
}