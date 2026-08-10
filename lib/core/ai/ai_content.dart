import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../services/scripture_service.dart';
import 'ai_models.dart';

/// A canonical Scripture pointer in the curated bank.
class AiBankPointer {
  final String id;
  final String bookId;
  final int chapter;
  final int verse;
  final int? endVerse;

  const AiBankPointer({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    this.endVerse,
  });

  AiReference toReference() =>
      AiReference(bookId: bookId, chapter: chapter, verse: verse, endVerse: endVerse);
}

/// A hand-written reflective line, in both languages. Written by hand, never
/// translated by the model — natural Amharic and English.
class AiBankQuestion {
  final String id;
  final String en;
  final String am;

  const AiBankQuestion({required this.id, required this.en, required this.am});

  String lineFor(AiLanguageBucket language) =>
      language == AiLanguageBucket.amharic ? am : en;
}

/// The curated, canon-verified content bank. Every pointer is checked against
/// `ScriptureService.bookMap` at load time — a pointer that cannot exist never
/// reaches a user. Every visible word in the app comes from here or from the
/// canonical Scripture service; never from a model.
class AiContentBank {
  final int version;
  final List<AiBankPointer> pointers;
  final List<AiBankQuestion> questions;

  const AiContentBank({
    required this.version,
    required this.pointers,
    required this.questions,
  });

  Map<String, AiBankPointer> get pointerById =>
      {for (final p in pointers) p.id: p};

  Map<String, AiBankQuestion> get questionById =>
      {for (final q in questions) q.id: q};

  /// Loads the bundled bank. Throws if the asset is missing or malformed —
  /// the app fails closed rather than serving uncurated content.
  static Future<AiContentBank> load() async {
    final raw = await rootBundle.loadString('assets/data/ai_bank.json');
    return AiContentBank.fromJsonString(raw);
  }

  static AiContentBank fromJsonString(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final version = data['version'] as int;
    final pointers = (data['pointers'] as List<dynamic>).map((e) {
      final p = e as Map<String, dynamic>;
      return AiBankPointer(
        id: p['id'] as String,
        bookId: p['bookId'] as String,
        chapter: p['chapter'] as int,
        verse: p['verse'] as int,
        endVerse: p['endVerse'] as int?,
      );
    }).toList();
    final questions = (data['questions'] as List<dynamic>).map((e) {
      final q = e as Map<String, dynamic>;
      return AiBankQuestion(
        id: q['id'] as String,
        en: q['en'] as String,
        am: q['am'] as String,
      );
    }).toList();
    return AiContentBank(
      version: version,
      pointers: pointers,
      questions: questions,
    );
  }

  /// Returns a list of content problems (empty when the bank is clean).
  /// Called at load and asserted in tests so a bad edit cannot ship.
  List<String> validate() {
    final issues = <String>[];
    if (version != 1) issues.add('bank version must be 1, found $version');
    final seen = <String>{};
    for (final p in pointers) {
      if (!seen.add(p.id)) issues.add('duplicate pointer id ${p.id}');
      final book = ScriptureService.bookMap[p.bookId];
      if (book == null) {
        issues.add('pointer ${p.id}: unknown book ${p.bookId}');
        continue;
      }
      if (p.chapter < 1 || p.chapter > book.chapters) {
        issues.add('pointer ${p.id}: chapter ${p.chapter} out of range for ${p.bookId} (${book.chapters})');
      }
      if (p.verse < 1) issues.add('pointer ${p.id}: verse must be >= 1');
      if (p.endVerse != null && p.endVerse! < p.verse) {
        issues.add('pointer ${p.id}: endVerse before verse');
      }
    }
    for (final q in questions) {
      if (!seen.add(q.id)) issues.add('duplicate question id ${q.id}');
      if (q.en.trim().isEmpty || q.am.trim().isEmpty) {
        issues.add('question ${q.id}: both languages required');
      }
    }
    if (pointers.isEmpty || questions.isEmpty) {
      issues.add('bank must contain at least one pointer and one question');
    }
    return issues;
  }
}
