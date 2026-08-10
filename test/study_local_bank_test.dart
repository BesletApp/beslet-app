import 'dart:io';

import 'package:beslet_app/core/ai/study/study_local_bank.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:flutter_test/flutter_test.dart';

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

/// Every renderable English string in a bank entry (text + context halves +
/// cross-reference reasons), for the banned-pattern lint.
List<String> englishStrings(StudyBankEntry entry) {
  final out = <String>[];
  for (final section in entry.sections) {
    if (section.kind == StudySectionKind.crossReferences) {
      for (final ref in section.references) {
        if (ref.en.isNotEmpty) out.add(ref.en);
      }
      continue;
    }
    if (section.en.isNotEmpty) out.add(section.en);
    final sub = section.enSub;
    if (sub != null && sub.isNotEmpty) out.add(sub);
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
      expect(bank.validate(), isEmpty,
          reason: 'the shipped study bank must be canon-clean: ${bank.validate()}');
    });

    test('every entry has all six sections, both languages, both context halves',
        () {
      expect(bank.entries, isNotEmpty);
      for (final entry in bank.entries) {
        expect(entry.sections.length, StudySectionKind.values.length,
            reason: 'entry ${entry.id} must have all six sections');
        for (final section in entry.sections) {
          if (section.kind == StudySectionKind.crossReferences) {
            expect(section.references, isNotEmpty,
                reason: 'entry ${entry.id} crossReferences must not be empty');
            for (final ref in section.references) {
              expect(ref.en.trim(), isNotEmpty,
                  reason: 'entry ${entry.id} cross-reference needs an English reason');
              expect(ref.am.trim(), isNotEmpty,
                  reason: 'entry ${entry.id} cross-reference needs an Amharic reason');
            }
            continue;
          }
          expect(section.en.trim(), isNotEmpty,
              reason: 'entry ${entry.id} ${section.kind.name} needs English');
          expect(section.am.trim(), isNotEmpty,
              reason: 'entry ${entry.id} ${section.kind.name} needs Amharic');
          if (section.kind == StudySectionKind.context) {
            expect(section.enSub?.trim(), isNotEmpty,
                reason: 'entry ${entry.id} context needs the "in the text" English part');
            expect(section.amSub?.trim(), isNotEmpty,
                reason: 'entry ${entry.id} context needs the "in the text" Amharic part');
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

    test('rejects a bank with an unknown book (fail closed)', () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":1,"entries":[{"id":"x","bookId":"not_a_book","chapter":1,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"summary","en":"a","am":"a"},'
        '{"kind":"context","en":"a","am":"a","enSub":"b","amSub":"b"},'
        '{"kind":"observations","en":"a","am":"a"},'
        '{"kind":"teachings","en":"a","am":"a"},'
        '{"kind":"reflection","en":"a","am":"a"},'
        '{"kind":"crossReferences","references":['
        '{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11,"en":"r","am":"r"}]}]}]}',
      ).validate();
      expect(issues.any((i) => i.contains('unknown book')), isTrue);
    });

    test('rejects a cross-reference whose chapter is out of range (fail closed)',
        () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":1,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"summary","en":"a","am":"a"},'
        '{"kind":"context","en":"a","am":"a","enSub":"b","amSub":"b"},'
        '{"kind":"observations","en":"a","am":"a"},'
        '{"kind":"teachings","en":"a","am":"a"},'
        '{"kind":"reflection","en":"a","am":"a"},'
        '{"kind":"crossReferences","references":['
        '{"bookId":"psalms","chapter":999,"startVerse":1,"endVerse":1,"en":"r","am":"r"}]}]}]}',
      ).validate();
      expect(issues.any((i) => i.contains('out of range')), isTrue,
          reason: issues.join('\n'));
    });

    test('rejects context missing the "in the text" part', () {
      final issues = StudyLocalBank.fromJsonString(
        '{"version":1,"entries":[{"id":"x","bookId":"psalms","chapter":23,'
        '"startVerse":1,"endVerse":1,"sections":['
        '{"kind":"summary","en":"a","am":"a"},'
        '{"kind":"context","en":"a","am":"a"},'
        '{"kind":"observations","en":"a","am":"a"},'
        '{"kind":"teachings","en":"a","am":"a"},'
        '{"kind":"reflection","en":"a","am":"a"},'
        '{"kind":"crossReferences","references":['
        '{"bookId":"john","chapter":10,"startVerse":11,"endVerse":11,"en":"r","am":"r"}]}]}]}',
      ).validate();
      expect(issues.any((i) => i.contains('in the text')), isTrue,
          reason: issues.join('\n'));
    });
  });
}