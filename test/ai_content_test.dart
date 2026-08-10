import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/ai/ai_content.dart';
import 'package:beslet_app/core/ai/ai_models.dart';

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

void main() {
  group('AiContentBank (shipped asset)', () {
    late AiContentBank bank;

    setUpAll(() {
      final raw = File('assets/data/ai_bank.json').readAsStringSync();
      bank = AiContentBank.fromJsonString(raw);
    });

    test('passes full content validation (fail-closed gate)', () {
      expect(bank.validate(), isEmpty,
          reason: 'the shipped bank must be canon-clean: ${bank.validate()}');
    });

    test('contains both languages and non-empty lines', () {
      expect(bank.pointers, isNotEmpty);
      expect(bank.questions, isNotEmpty);
      for (final q in bank.questions) {
        expect(q.en.trim(), isNotEmpty);
        expect(q.am.trim(), isNotEmpty);
      }
    });

    test('question ids resolve to lines in the user language', () {
      final q = bank.questions.first;
      expect(q.lineFor(AiLanguageBucket.amharic), q.am);
      expect(q.lineFor(AiLanguageBucket.english), q.en);
    });

    test('banned-pattern lint: no Western self-help framing', () {
      for (final q in bank.questions) {
        final lower = q.en.toLowerCase();
        for (final banned in bannedPatterns) {
          expect(lower.contains(banned), isFalse,
              reason: 'question ${q.id} contains banned pattern "$banned"');
        }
      }
    });

    test('pointer ids are unique and every pointer maps to a reference', () {
      final seen = <String>{};
      for (final p in bank.pointers) {
        expect(seen.add(p.id), isTrue, reason: 'duplicate id ${p.id}');
        final ref = p.toReference();
        expect(ref.referenceFor(false), isNotEmpty);
      }
    });

    test('rejects a bank with an unknown book (fail closed)', () {
      final broken = bank.pointers
          .map((p) => p.id == 'ptr_ps23_1'
              ? '{"id":"${p.id}","bookId":"not_a_book","chapter":1,"verse":1}'
              : '{"id":"${p.id}","bookId":"${p.bookId}","chapter":${p.chapter},"verse":${p.verse}${p.endVerse != null ? ',"endVerse":${p.endVerse}' : ''}}')
          .join(',');
      final issues = AiContentBank.fromJsonString(
        '{"version":1,"pointers":[$broken],"questions":[]}',
      ).validate();
      expect(issues.any((i) => i.contains('unknown book')), isTrue);
    });
  });
}
