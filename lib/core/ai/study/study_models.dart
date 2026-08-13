import 'dart:convert';

import '../../services/scripture_service.dart';
import 'study_intro.dart';

/// The on-demand Study feature — core types.
///
/// Phase 1 serves curated, hand-written notes from the bundled
/// `assets/data/study.json` bank. Phase 2 adds a Gemini backend behind the
/// same `StudyBackend` seam. The UI only ever says "study this passage"; it
/// never learns about Gemini, keys, models, or prompts.
///
/// The seven sections deliberately follow a Scripture-first shape:
/// SCRIPTURE → CONTEXT → BACKGROUND → CONNECTIONS → INTERPRETATION →
/// REFLECTION. Cross-references are structured (book/chapter/verse + a short
/// reason) so they can be validated against the real canon before anything is
/// shown. There is no Application section: personal understanding, conviction,
/// application, and revelation belong to the reader and the Holy Spirit.

/// Bump when the prompt, schema, or generation rules change so cached notes
/// from an older version are never served.
const int studyPromptVersion = 10;

/// The version of the serialized cache payload.
const int _cacheVersion = 7;

/// The shared marker vocabulary a note uses for hierarchy. The prompt tells the
/// model to write these markers, the validator guarantees they are well-formed,
/// and the panel renders them — so a reader always sees the same, calm
/// structure whether a note came from the bank or from the model.
class StudyFormat {
  StudyFormat._();

  /// A bulleted line: U+2022 BULLET, a space, then content. The only bullet
  /// form the app understands — dashes and asterisks render as plain prose.
  static final RegExp bullet = RegExp(r'^•\s+(.+)$');

  /// A labeled movement step in the reader's language: "Step N — body" or
  /// "ደረጃ N — body", all on one line. At most [maxSteps] per section.
  static RegExp step(bool isAm) => isAm ? _stepAm : _stepEn;

  static final RegExp _stepEn = RegExp(r'^Step\s+(\d+)\s*[—–-]\s*(.+)$');
  static final RegExp _stepAm = RegExp(r'^ደረጃ\s+(\d+)\s*[—–-]\s*(.+)$');

  /// A line that clearly intends to be a step heading but is not in the
  /// validated form (e.g. "Step 1" with no dash, or "Step — body"). Used by
  /// the validator to catch malformed structure.
  static RegExp stepHeadingAttempt(bool isAm) =>
      isAm ? _stepHeadingAttemptAm : _stepHeadingAttemptEn;

  static final RegExp _stepHeadingAttemptEn =
      RegExp(r'^Step\s+(?=\d|[—–-])');
  static final RegExp _stepHeadingAttemptAm =
      RegExp(r'^ደረጃ\s+(?=\d|[—–-])');

  /// The most labeled movement steps one section may carry. Beyond this the
  /// structure is runaway, not a passage tracing its own movement.
  static const int maxSteps = 5;
}

/// One of the seven sections of a study note. The order in the enum is the
/// order the panel renders them.
///
/// The shape deliberately follows the Scripture-first hierarchy:
/// SCRIPTURE → CONTEXT → HISTORICAL/CULTURAL → LITERARY/TEXTUAL →
/// BIBLICAL CONNECTIONS → CAREFUL INTERPRETIVE OBSERVATIONS →
/// PERSONAL REFLECTION. The AI illuminates the text; the reader and the Holy
/// Spirit do the personal work. There is deliberately no Application section.
enum StudySectionKind {
  /// One or two lines anchoring the passage in its book and moment.
  setting,

  /// Historical + literary context: "behind the text" and "in the text".
  context,

  /// A plain, faithful tracing of what the passage itself says.
  whatTextSays,

  /// Meaning, key terms, and cultural/historical background needed to
  /// understand the text. Interpretive claims carry tier labels.
  meaningBackground,

  /// Validated cross-references with a short reason each.
  biblicalConnections,

  /// Careful interpretive observations split into three honest tiers.
  whatCanBeUnderstood,

  /// Open-ended questions that send the reader back to the text.
  reflection,
}

/// How firmly a claim can be held. The model must never present a lower tier
/// as a higher one, and no tier ever becomes "God is telling you".
enum StudyTier {
  /// The text clearly states this.
  clearlyStated,

  /// A strongly supported, widely held understanding.
  supportedUnderstanding,

  /// A point genuinely disputed among Christians.
  disputed,
}

/// How confident the source is in a section. Carried so the reader can weigh
/// the note honestly; never used to inflate authority.
enum StudyConfidence { high, medium, low }

/// One tier-labeled block inside [StudySectionKind.whatCanBeUnderstood].
class StudyTieredBlock {
  final StudyTier tier;
  final String en;
  final String am;

  const StudyTieredBlock({
    required this.tier,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => en.trim().isEmpty && am.trim().isEmpty;

  String textFor(bool isAm) {
    final t = isAm ? am : en;
    return t.trim();
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        'en': en,
        'am': am,
      };

  static StudyTieredBlock? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final tier = StudyTier.values.where((t) => t.name == raw['tier']).firstOrNull;
    if (tier == null) return null;
    final block = StudyTieredBlock(
      tier: tier,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
    return block.isEmpty ? null : block;
  }
}

/// One important term or original-language word worth a reader's attention.
/// The term itself stays in its own script (Hebrew, Greek, Ge'ez, ...), the
/// meaning is carried in both languages so the panel answers in the reader's
/// language. Only an AI note generates these; the curated bank keeps its terms
/// inside its prose.
class StudyTerm {
  final String term;
  final String language;
  final String? transliteration;
  final String en;
  final String am;

  const StudyTerm({
    required this.term,
    this.language = '',
    this.transliteration,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => term.trim().isEmpty;

  String meaningFor(bool isAm) {
    final t = isAm ? am : en;
    return t.trim();
  }

  Map<String, dynamic> toJson() => {
        'term': term,
        if (language.isNotEmpty) 'language': language,
        if (transliteration != null && transliteration!.isNotEmpty)
          'transliteration': transliteration,
        'en': en,
        'am': am,
      };

  static StudyTerm? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final term = raw['term'];
    if (term is! String || term.trim().isEmpty) return null;
    return StudyTerm(
      term: term.trim(),
      language: raw['language'] is String ? raw['language'] as String : '',
      transliteration: raw['transliteration'] is String
          ? raw['transliteration'] as String
          : null,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
  }
}

/// Which engine produced a note — keeps the Gemini seam honest and lets a
/// future remote backend be measured against the curated local one.
enum StudySource {
  /// The handwritten, canon-verified bank.
  localBank,

  /// The AI model, standing behind the validator.
  gemini,

  /// A deterministic note assembled from the bundled knowledge layers (book
  /// intro + cross-reference index) when nothing else is reachable. Served
  /// only from memory; never persisted, so it can never shadow a richer note.
  knowledge,
}

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

  /// The book's literary genre, when known. Deterministic for a given book, so
  /// it needs no place in the cache key; it shapes the note's voice only
  /// (`poetry` breathes imagery, `epistle` reads like a letter, ...).
  final StudyGenre? genre;

  const StudyRequest({
    required this.reference,
    required this.isAmharic,
    required this.verseTexts,
    this.genre,
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
  final int priority; // 0 (core) to 2 (supporting), for ordering only

  const StudyCrossReference({
    required this.bookId,
    required this.chapter,
    required this.startVerse,
    required this.endVerse,
    this.en = '',
    this.am = '',
    this.priority = 0,
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
        if (priority != 0) 'priority': priority,
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
      priority: raw['priority'] is int ? raw['priority'] as int : 0,
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

  /// Tier-labeled blocks for [StudySectionKind.whatCanBeUnderstood].
  final List<StudyTieredBlock> blocks;

  /// Important terms and original-language words (meaningBackground).
  final List<StudyTerm> terms;

  /// An optional, neutral one-line anchor that gathers what the passage itself
  /// said, nested on the reflection. Never a directive and never a question.
  final String? takeawayEn;
  final String? takeawayAm;

  /// How confident the producer is in this section (null = unstated).
  final StudyConfidence? confidence;

  /// Curated sources this content draws on (empty for AI-generated notes).
  final List<String> sourceIds;

  const StudySection({
    required this.kind,
    this.en = '',
    this.am = '',
    this.enSub,
    this.amSub,
    this.references = const [],
    this.blocks = const [],
    this.terms = const [],
    this.takeawayEn,
    this.takeawayAm,
    this.confidence,
    this.sourceIds = const [],
  });

  /// True when the section has no renderable content ("preserve silence").
  bool get isEmpty {
    if (kind == StudySectionKind.biblicalConnections) return references.isEmpty;
    if (kind == StudySectionKind.whatCanBeUnderstood) return blocks.isEmpty;
    final hasText = en.trim().isNotEmpty || am.trim().isNotEmpty;
    if (kind == StudySectionKind.meaningBackground) {
      return !hasText && terms.isEmpty;
    }
    return !hasText;
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

  /// The neutral takeaway line in the reader's language, when present.
  String? takeawayFor(bool isAm) {
    final t = isAm ? takeawayAm : takeawayEn;
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
        if (blocks.isNotEmpty)
          'blocks': blocks.map((b) => b.toJson()).toList(),
        if (terms.isNotEmpty) 'terms': terms.map((t) => t.toJson()).toList(),
        if (takeawayEn != null) 'takeawayEn': takeawayEn,
        if (takeawayAm != null) 'takeawayAm': takeawayAm,
        if (confidence != null) 'confidence': confidence!.name,
        if (sourceIds.isNotEmpty) 'sourceIds': sourceIds,
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
      blocks: (raw['blocks'] as List<dynamic>? ?? [])
          .map(StudyTieredBlock.tryParse)
          .whereType<StudyTieredBlock>()
          .toList(),
      terms: (raw['terms'] as List<dynamic>? ?? [])
          .map(StudyTerm.tryParse)
          .whereType<StudyTerm>()
          .toList(),
      takeawayEn: raw['takeawayEn'] is String ? raw['takeawayEn'] as String : null,
      takeawayAm: raw['takeawayAm'] is String ? raw['takeawayAm'] as String : null,
      confidence: StudyConfidence.values
          .where((c) => c.name == raw['confidence'])
          .firstOrNull,
      sourceIds: raw['sourceIds'] is List
          ? (raw['sourceIds'] as List)
              .whereType<String>()
              .toList()
          : const [],
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
        source: StudySource.values
            .where((s) => s.name == data['source'])
            .firstOrNull ??
            StudySource.localBank,
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
