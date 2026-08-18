import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'scripture_service.dart';

final _geezPattern = RegExp(r'[\u1200-\u137F]');

/// One day's curated self-examination question. Authored offline in both
/// languages the app ships; the Amharic is written independently, never as a
/// literal translation.
class ProvocativeQuestion {
  final String id;
  final String category;
  final String questionEn;
  final String questionAm;
  final List<String> verses;
  final String reflectionEn;
  final String reflectionAm;

  const ProvocativeQuestion({
    required this.id,
    required this.category,
    required this.questionEn,
    required this.questionAm,
    required this.verses,
    required this.reflectionEn,
    required this.reflectionAm,
  });

  String questionFor(bool isAm) => isAm ? questionAm : questionEn;
  String reflectionFor(bool isAm) => isAm ? reflectionAm : reflectionEn;
}

/// The bundled library of daily questions. Loaded once and shared. Every entry
/// is validated at load and asserted in tests so a bad edit cannot ship.
class ProvocativeQuestionService {
  static const int expectedVersion = 1;
  static const int expectedTotal = 60;

  static const Map<String, int> expectedCategoryCounts = {
    'return': 9,
    'prayer': 6,
    'bible': 6,
    'growth': 9,
    'repentance': 6,
    'love': 6,
    'faith': 6,
    'discipleship': 6,
    'eternity': 6,
  };

  static const Set<String> allowedBooks = {
    'matthew',
    'mark',
    'luke',
    'john',
    'psalms',
    'proverbs',
    'romans',
    'james',
    '1peter',
    'hebrews',
    '1john',
  };

  static final DateTime epoch = DateTime(2026, 1, 1);

  final int version;
  final List<ProvocativeQuestion> questions;

  const ProvocativeQuestionService({required this.version, required this.questions});

  static Future<ProvocativeQuestionService> load() async {
    final raw = await rootBundle.loadString('assets/data/provocative_questions.json');
    return ProvocativeQuestionService.fromJsonString(raw);
  }

  static ProvocativeQuestionService fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['version'] != expectedVersion) {
      throw FormatException('unexpected provocative_questions version');
    }
    final questions = <ProvocativeQuestion>[];
    for (final rawQuestion in data['questions'] as List<dynamic>) {
      final q = rawQuestion as Map<String, dynamic>;
      questions.add(ProvocativeQuestion(
        id: q['id'] as String,
        category: q['category'] as String,
        questionEn: (q['questionEn'] as String?) ?? '',
        questionAm: (q['questionAm'] as String?) ?? '',
        verses: ((q['verses'] as List<dynamic>?) ?? const []).cast<String>(),
        reflectionEn: (q['reflectionEn'] as String?) ?? '',
        reflectionAm: (q['reflectionAm'] as String?) ?? '',
      ));
    }
    return ProvocativeQuestionService(version: data['version'] as int, questions: questions);
  }

  /// The question for [day]: a deterministic, date-based rotation over the
  /// bundled entries. Pure math; nothing is stored or persisted.
  ProvocativeQuestion? questionFor(DateTime day) {
    if (questions.isEmpty) return null;
    final idx = day.difference(epoch).inDays % questions.length;
    return questions[idx < 0 ? idx + questions.length : idx];
  }

  /// Returns a list of content problems, empty when the library is clean.
  /// Called at load and asserted in tests so a bad edit cannot ship.
  List<String> validate() {
    final issues = <String>[];

    if (questions.length != expectedTotal) {
      issues.add('expected $expectedTotal questions, found ${questions.length}');
    }

    final counts = <String, int>{};
    for (final q in questions) {
      counts[q.category] = (counts[q.category] ?? 0) + 1;
    }
    for (final entry in expectedCategoryCounts.entries) {
      final found = counts[entry.key] ?? 0;
      if (found != entry.value) {
        issues.add('category ${entry.key}: expected ${entry.value}, found $found');
      }
    }
    for (final key in counts.keys) {
      if (!expectedCategoryCounts.containsKey(key)) {
        issues.add('unknown category: $key');
      }
    }

    final seenIds = <String>{};
    for (final q in questions) {
      if (q.id.isEmpty) {
        issues.add('a question has an empty id');
      } else if (!seenIds.add(q.id)) {
        issues.add('duplicate id: ${q.id}');
      }

      final enWords = q.questionEn
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      if (enWords < 3 || enWords > 6) {
        issues.add('${q.id}: questionEn must be 3-6 words, got $enWords');
      }
      if (q.questionEn.length > 30) {
        issues.add('${q.id}: questionEn exceeds 30 characters');
      }

      if (q.questionAm.isEmpty) {
        issues.add('${q.id}: questionAm is empty');
      } else {
        if (q.questionAm.length > 45) {
          issues.add('${q.id}: questionAm exceeds 45 characters');
        }
        if (!_geezPattern.hasMatch(q.questionAm)) {
          issues.add('${q.id}: questionAm is not written in Amharic script');
        }
      }

      final refEnWords = q.reflectionEn
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      if (refEnWords < 1 || refEnWords > 15) {
        issues.add('${q.id}: reflectionEn must be 1-15 words, got $refEnWords');
      }
      if (q.reflectionEn.contains('?') || q.reflectionEn.contains('!')) {
        issues.add('${q.id}: reflectionEn must end with a period, not a question or exclamation');
      }

      final refAmWords = q.reflectionAm
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .length;
      if (refAmWords < 1 || refAmWords > 18) {
        issues.add('${q.id}: reflectionAm must be 1-18 words, got $refAmWords');
      }
      if (!_geezPattern.hasMatch(q.reflectionAm)) {
        issues.add('${q.id}: reflectionAm is not written in Amharic script');
      }

      if (q.verses.length != 2) {
        issues.add('${q.id}: exactly 2 references required, got ${q.verses.length}');
      } else if (q.verses[0] == q.verses[1]) {
        issues.add('${q.id}: the two references must differ');
      }
      for (final reference in q.verses) {
        final range = ScriptureService.referenceRange(reference);
        if (range == null) {
          issues.add('${q.id}: reference does not parse: $reference');
          continue;
        }
        if (!allowedBooks.contains(range.bookId)) {
          issues.add('${q.id}: reference outside allowed books: $reference');
        }
        final book = ScriptureService.bookMap[range.bookId];
        if (book != null && (range.chapter < 1 || range.chapter > book.chapters)) {
          issues.add('${q.id}: reference chapter out of bounds: $reference');
        }
      }
    }

    return issues;
  }
}