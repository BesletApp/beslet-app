import 'dart:convert';
import 'dart:io';

import 'package:beslet_app/core/services/provocative_question_service.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProvocativeQuestionService (shipped asset)', () {
    late ProvocativeQuestionService library;

    setUpAll(() {
      final raw = File('assets/data/provocative_questions.json').readAsStringSync();
      library = ProvocativeQuestionService.fromJsonString(raw);
    });

    test('passes full content validation (fail-closed gate)', () {
      final issues = library.validate();
      expect(issues, isEmpty,
          reason: 'the shipped question library must be clean:\n${issues.join('\n')}');
    });

    test('contains exactly 60 questions across the nine categories at exact counts', () {
      expect(library.questions.length, ProvocativeQuestionService.expectedTotal);
      final counts = <String, int>{};
      for (final q in library.questions) {
        counts[q.category] = (counts[q.category] ?? 0) + 1;
      }
      for (final entry in ProvocativeQuestionService.expectedCategoryCounts.entries) {
        expect(counts[entry.key], entry.value,
            reason: 'category ${entry.key} must hold exactly ${entry.value} entries');
      }
    });

    test('every question is bilingual and references a real, allowed passage', () {
      for (final q in library.questions) {
        expect(q.questionEn.trim(), isNotEmpty, reason: '${q.id} needs an English question');
        expect(q.questionAm.trim(), isNotEmpty, reason: '${q.id} needs an Amharic question');
        expect(q.reflectionEn.trim(), isNotEmpty, reason: '${q.id} needs an English reflection');
        expect(q.reflectionAm.trim(), isNotEmpty, reason: '${q.id} needs an Amharic reflection');
        expect(q.verses.length, 2, reason: '${q.id} must carry exactly two references');
        for (final reference in q.verses) {
          final range = ScriptureService.referenceRange(reference);
          expect(range, isNotNull, reason: '${q.id} has an unparsable reference: $reference');
          expect(ProvocativeQuestionService.allowedBooks.contains(range!.bookId), isTrue,
              reason: '${q.id} uses a book outside the allowed set: $reference');
        }
      }
    });

    test('rotation is deterministic and wraps after the full cycle', () {
      final first = library.questionFor(DateTime(2026, 1, 1))!;
      final second = library.questionFor(DateTime(2026, 1, 2))!;
      final cycled = library.questionFor(DateTime(2026, 3, 2))!;
      expect(first.id, isNot(second.id),
          reason: 'consecutive days must show different questions');
      expect(cycled.id, first.id,
          reason: 'the same date must repeat after the full 60-day cycle');
      final dayAfterCycle = library.questionFor(DateTime(2026, 3, 2))!;
      expect(dayAfterCycle.id, first.id);
      final sameDay = library.questionFor(DateTime(2026, 1, 1))!;
      expect(sameDay.id, first.id, reason: 'the same date must always yield the same question');
    });

    test('negative rotation stays in bounds and preserves the last entry', () {
      final last = library.questions.last;
      final beforeEpoch = library.questionFor(DateTime(2025, 12, 31))!;
      expect(beforeEpoch.id, last.id);
      final twoBefore = library.questionFor(DateTime(2025, 12, 30));
      expect(twoBefore, isNotNull);
    });

    test('fails closed on an unexpected version', () {
      final raw = File('assets/data/provocative_questions.json').readAsStringSync();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      data['version'] = 999;
      expect(
          () => ProvocativeQuestionService.fromJsonString(jsonEncode(data)),
          throwsA(isA<FormatException>()));
    });

    test('validate() flags violations instead of accepting bad content', () {
      const bad = ProvocativeQuestionService(
        version: 1,
        questions: [
          ProvocativeQuestion(
            id: 'bad-1',
            category: 'return',
            questionEn: 'too many words in this question sentence here',
            questionAm: 'አህ',
            verses: ['Genesis 1:1', 'Genesis 1:1'],
            reflectionEn: 'Is this a question?',
            reflectionAm: 'ጽሑፍ',
          ),
        ],
      );
      final issues = bad.validate();
      expect(issues, isNotEmpty);
      expect(issues.where((i) => i.contains('3-6 words')).isNotEmpty, isTrue);
      expect(issues.where((i) => i.contains('two references must differ')).isNotEmpty, isTrue);
    });
  });
}