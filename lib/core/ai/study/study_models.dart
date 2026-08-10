import 'dart:convert';

import '../../services/scripture_service.dart';

/// The on-demand Study feature — core types.
///
/// Phase 1 serves curated, hand-written notes from the bundled
/// `assets/data/study.json` bank. Phase 2 adds a Gemini backend behind the
/// same `StudyBackend` seam. The UI only ever says "study this passage"; it
/// never learns about Gemini, keys, models, or prompts.
///
/// The six sections deliberately follow a Scripture-first shape:
/// SCRIPTURE → UNDERSTANDING → REFLECTION → GOD. Cross-references are
/// structured (book/chapter/verse + a short reason) so they can be validated
/// against the real canon before anything is shown.

/// Bump when the prompt, schema, or generation rules change so cached notes
/// from an older version are never served.
const int studyPromptVersion = 1;

/// The version of the serialized cache payload.
const int _cacheVersion = 2;

/// One of the six sections of a study note. The order in the enum is the
/// order the panel renders them.
enum StudySectionKind {
  /// What the passage says in its immediate flow. Very short.
  summary,

  /// Historical + literary context: "behind the text" and "in the text".
  context,

  /// Literary/textual observations: repeated words, contrasts, structure.
  observations,

  /// What the passage itself communicates about God, humanity, etc.
  teachings,

  /// Open-ended questions that send the reader back to the text.
  reflection,

  /// Validated cross-references with a short reason each.
  crossReferences,
}

/// Which engine produced a note — keeps the Gemini seam honest and lets a
/// future remote backend be measured against the curated local one.
enum StudySource { localBank, gemini }

/// Which passage is being studied. Contiguous verses within one chapter.
class StudyReference {
  final String bookId;
  final int chapter;
  final int startVerse;
  final int endVerse;

  const StudyReference({
    required this.bookId,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
  });

  int get verseCount => endVerse - startVerse + 1;

  /// Stable key for the SharedPreferences cache (language is added by the
  /// service, prompt version by the service too).
  String get cacheKey => '${bookId}_${chapter}_${startVerse}_$endVerse';

  /// Localized label, e.g. "Psalm 23:1–6" or "መዝሙረ ዳዊት 23:1–6".
  String referenceFor(bool isAm) {
    final book = ScriptureService.bookMap[bookId];
    final name = book != null ? (isAm ? book.nameAm : book.nameEn) : bookId;
    if (startVerse == endVerse) return '$name $chapter:$startVerse';
    return '$name $chapter:$startVerse–$endVerse';
  }
}

/// Everything the Study backend needs to answer, including the exact verse
/// texts in the reader's language so the panel never has to re-fetch.
class StudyRequest {
  final StudyReference reference;
  final bool isAmharic;
  final List<String> verseTexts;

  const StudyRequest({
    required this.reference,
    required this.isAmharic,
    required this.verseTexts,
  });
}

/// A canonical cross-reference: a valid Bible passage plus a short reason
/// explaining why it relates. Validated against the app's Bible data before
/// it can reach a reader.
class StudyCrossReference {
  final String bookId;
  final int chapter;
  final int startVerse;
  final int endVerse;
  final String en; // reason, English (empty when the note is Amharic-only)
  final String am; // reason, Amharic (empty when the note is English-only)

  const StudyCrossReference({
    required this.bookId,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    this.en = '',
    this.am = '',
  });

  /// Localized canonical label, e.g. "John 10:11" or "ዮሐንስ 10፡11".
  String referenceFor(bool isAm) {
    final book = ScriptureService.bookMap[bookId];
    final name = book != null ? (isAm ? book.nameAm : book.nameEn) : bookId;
    if (startVerse == endVerse) return '$name $chapter:$startVerse';
    return '$name $chapter:$startVerse–$endVerse';
  }

  /// The reason in the reader's language (may be empty).
  String reasonFor(bool isAm) {
    final r = isAm ? am : en;
    return r.trim();
  }

  Map<String, dynamic> toJson() => {
        'bookId': bookId,
        'chapter': chapter,
        'startVerse': startVerse,
        'endVerse': endVerse,
        'en': en,
        'am': am,
      };

  static StudyCrossReference? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final bookId = raw['bookId'];
    final chapter = raw['chapter'];
    final startVerse = raw['startVerse'];
    final endVerse = raw['endVerse'];
    if (bookId is! String ||
        chapter is! int ||
        startVerse is! int ||
        endVerse is! int) {
      return null;
    }
    return StudyCrossReference(
      bookId: bookId,
      chapter: chapter,
      startVerse: startVerse,
      endVerse: endVerse,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
  }
}

/// One section of a study note.
///
/// A section may be single-language (an AI note is generated natively in the
/// reader's language only; the other side is empty) or bilingual (the
/// hand-written bank provides both). The panel answers with [textFor].
///
/// `context` uses [en]/[am] for "behind the text" and [enSub]/[amSub] for
/// "in the text". `crossReferences` carries a validated [references] list.
class StudySection {
  final StudySectionKind kind;
  final String en;
  final String am;
  final String? enSub;
  final String? amSub;
  final List<StudyCrossReference> references;

  const StudySection({
    required this.kind,
    this.en = '',
    this.am = '',
    this.enSub,
    this.amSub,
    this.references = const [],
  });

  /// True when the section has no renderable content ("preserve silence").
  bool get isEmpty {
    if (kind == StudySectionKind.crossReferences) return references.isEmpty;
    return en.trim().isEmpty && am.trim().isEmpty;
  }

  /// The primary text in the reader's language (behind-the-text for context).
  String textFor(bool isAm) {
    final t = isAm ? am : en;
    return t.trim();
  }

  /// The "in the text" half of context, when present.
  String? subTextFor(bool isAm) {
    final t = isAm ? amSub : enSub;
    if (t == null) return null;
    return t.trim().isEmpty ? null : t.trim();
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'en': en,
        'am': am,
        if (enSub != null) 'enSub': enSub,
        if (amSub != null) 'amSub': amSub,
        if (references.isNotEmpty)
          'references': references.map((r) => r.toJson()).toList(),
      };

  static StudySection? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final kind = StudySectionKind.values
        .where((k) => k.name == raw['kind'])
        .firstOrNull;
    if (kind == null) return null;
    final section = StudySection(
      kind: kind,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
      enSub: raw['enSub'] is String ? raw['enSub'] as String : null,
      amSub: raw['amSub'] is String ? raw['amSub'] as String : null,
      references: (raw['references'] as List<dynamic>? ?? [])
          .map(StudyCrossReference.tryParse)
          .whereType<StudyCrossReference>()
          .toList(),
    );
    if (section.isEmpty) return null;
    return section;
  }
}

/// The result delivered to the panel. `isAvailable == false` is the quiet
/// graceful fallback — the panel renders an honest note instead of fabricating
/// content, and Scripture reading is never blocked.
class StudyResult {
  final StudyReference reference;
  final StudySource source;
  final List<StudySection> sections;
  final DateTime cachedAt;
  final bool isAvailable;

  const StudyResult({
    required this.reference,
    required this.source,
    required this.sections,
    required this.cachedAt,
    required this.isAvailable,
  });

  factory StudyResult.unavailable({required StudyReference reference}) =>
      StudyResult(
        reference: reference,
        source: StudySource.localBank,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: false,
      );

  String toJsonString() {
    final body = {
      'v': _cacheVersion,
      'source': source.name,
      'cachedAt': cachedAt.toIso8601String(),
      'sections': sections.map((s) => s.toJson()).toList(),
    };
    return jsonEncode(body);
  }

  static StudyResult? tryParse(String raw, StudyReference reference) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final sections = (data['sections'] as List<dynamic>? ?? [])
          .map(StudySection.tryParse)
          .whereType<StudySection>()
          .toList();
      return StudyResult(
        reference: reference,
        source: data['source'] == 'gemini'
            ? StudySource.gemini
            : StudySource.localBank,
        sections: sections,
        cachedAt: DateTime.tryParse(data['cachedAt'] as String? ?? '') ??
            DateTime.now(),
        isAvailable: true,
      );
    } catch (_) {
      return null;
    }
  }
}
