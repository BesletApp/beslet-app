import 'dart:convert';

import '../../services/scripture_service.dart';
import 'study_intro.dart';

/// The on-demand Study feature — core types.
///
/// The Study Workbook serves one passage through a fixed, Scripture-first
/// scaffold: the passage card, then eight sections the AI (or the curated bank)
/// may fill, then the memory anchor, then questions, then the reader's own
/// notes. The AI is a research assistant: it organizes facts about the text
/// (context, history, language, structure) and never claims to reveal God's
/// message. The reader studies; the Holy Spirit reveals.
///
/// The eight sections are validated against the deterministic canon before
/// anything reaches a reader. There is no Application section: personal
/// understanding, conviction, application, and revelation belong to the reader
/// and the Holy Spirit.

/// Bump when the prompt, schema, or generation rules change so cached notes
/// from an older version are never served.
const int studyPromptVersion = 12;

/// The version of the serialized cache payload.
const int _cacheVersion = 8;

/// Study depth: a shorter, faster note or the full workbook. The reader can
/// switch instantly because each depth has its own cache entry.
enum StudyDepth {
  /// Fast reading (3–5 minutes): anchor + overview + verse-by-verse +
  /// connections + one question. The AI is told to omit the other sections and
  /// the validator enforces it.
  brief,

  /// Serious study (7–10 minutes): the full eight-section workbook.
  standard;

  /// The automatic default for a selection. Complex genres (prophecy,
  /// apocalyptic, poetry, wisdom, epistle) always study in Standard regardless
  /// of length; an entire chapter defaults to Brief; short selections (1–5
  /// verses) default to Standard; everything else Brief.
  static StudyDepth autoFor({
    required StudyGenre? genre,
    required int verseCount,
    required int chapterVerseCount,
  }) {
    const complex = {
      StudyGenre.prophecy,
      StudyGenre.apocalyptic,
      StudyGenre.poetry,
      StudyGenre.wisdom,
      StudyGenre.epistle,
    };
    if (genre != null && complex.contains(genre)) return StudyDepth.standard;
    if (verseCount >= chapterVerseCount) return StudyDepth.brief;
    if (verseCount <= 5) return StudyDepth.standard;
    return StudyDepth.brief;
  }
}

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

/// One of the eight sections of a study workbook. The order in the enum is the
/// order the panel renders them.
///
/// The shape deliberately follows the Scripture-first hierarchy:
/// OVERVIEW → CONTEXT → STRUCTURE → VERSE-BY-VERSE → LANGUAGE → SCRIPTURE
/// ALONGSIDE SCRIPTURE → WHAT IS CLEARLY PRESENT → QUESTIONS. The AI organizes
/// facts about the text; the reader does the personal work. There is
/// deliberately no Application section.
enum StudySectionKind {
  /// Three to five bullet facts: kind of writing, place in the book, the
  /// passage's place in the larger story, its key images.
  passageOverview,

  /// Evidence-categorized historical background: author, audience, date, place,
  /// occasion, cultural setting, each visibly labeled by confidence. Only facts
  /// that help the reader understand this passage.
  historicalBackground,

  /// The movement of the passage: what comes before, what follows, and the
  /// passage's own movement traced as a short map.
  literaryContext,

  /// Verse-anchored observations: what each verse (or small group) says — its
  /// wording, imagery, repetition, structure. Facts and observations only.
  verseByVerse,

  /// Original-language study: important terms as cards, each anchored to the
  /// verse where it appears, with a meaning in the reader's language.
  originalLanguage,

  /// Canon-validated cross-references with a short reason each.
  scriptureInterconnections,

  /// What the text clearly presents, kept honest with three labeled tiers
  /// (clearly stated / supported understanding / discussed among Christians).
  explicitTeachings,

  /// One or two questions that send the reader back to the text, plus open
  /// threads of study to continue. The AI never closes the study.
  questionsToCarry,
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

/// The confidence category of a historical statement. Every historical entry
/// is visibly labeled so a reader always knows what is fact, what is
/// reconstruction, and what is discussed.
enum StudyHistoryCategory {
  /// Established historical fact.
  established,

  /// Historically probable reconstruction.
  probable,

  /// Scholarly discussion or uncertainty.
  debated;
}

/// The fixed labels a historical entry may carry. Only labels with something
/// honest to say are used; the rest are omitted.
enum StudyHistoryLabel {
  author,
  audience,
  date,
  place,
  occasion,
  culturalSetting;
}

/// One evidence-labeled historical statement.
class StudyHistoryEntry {
  final StudyHistoryCategory category;
  final StudyHistoryLabel label;
  final String en;
  final String am;

  const StudyHistoryEntry({
    required this.category,
    required this.label,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => en.trim().isEmpty && am.trim().isEmpty;

  String textFor(bool isAm) {
    final t = isAm ? am : en;
    return t.trim();
  }

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'label': label.name,
        'en': en,
        'am': am,
      };

  static StudyHistoryEntry? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final category = StudyHistoryCategory.values
        .where((c) => c.name == raw['category'])
        .firstOrNull;
    final label = StudyHistoryLabel.values
        .where((l) => l.name == raw['label'])
        .firstOrNull;
    if (category == null || label == null) return null;
    final entry = StudyHistoryEntry(
      category: category,
      label: label,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
    return entry.isEmpty ? null : entry;
  }
}

/// One tier-labeled block inside [StudySectionKind.explicitTeachings].
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

/// One verse-anchored observation. Observations cover 1–3 contiguous verses
/// within the studied passage and state what the text says — its wording,
/// imagery, repetition, structure. Facts and observations only.
class StudyVerseObservation {
  final int startVerse;
  final int endVerse;
  final String en;
  final String am;

  const StudyVerseObservation({
    required this.startVerse,
    required this.endVerse,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => en.trim().isEmpty && am.trim().isEmpty;

  String textFor(bool isAm) {
    final t = isAm ? am : en;
    return t.trim();
  }

  Map<String, dynamic> toJson() => {
        'startVerse': startVerse,
        'endVerse': endVerse,
        'en': en,
        'am': am,
      };

  static StudyVerseObservation? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final startVerse = raw['startVerse'];
    final endVerse = raw['endVerse'];
    if (startVerse is! int || endVerse is! int) return null;
    if (startVerse < 1 || endVerse < startVerse) return null;
    final observation = StudyVerseObservation(
      startVerse: startVerse,
      endVerse: endVerse,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
    return observation.isEmpty ? null : observation;
  }
}

/// One important term or original-language word worth a reader's attention.
/// The term itself stays in its own script (Hebrew, Greek, Ge'ez, ...), the
/// meaning is carried in both languages so the panel answers in the reader's
/// language. [verseNumber] anchors the term to the verse where it appears in
/// the studied passage.
class StudyTerm {
  final String term;
  final String language;
  final String? transliteration;
  final int? verseNumber;
  final String en;
  final String am;

  const StudyTerm({
    required this.term,
    this.language = '',
    this.transliteration,
    this.verseNumber,
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
        if (verseNumber != null) 'verseNumber': verseNumber,
        'en': en,
        'am': am,
      };

  static StudyTerm? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final term = raw['term'];
    if (term is! String || term.trim().isEmpty) return null;
    // The bundled v2 bank carried the English meaning under "meaning" (the
    // Gemini schema's key); accept it as the English side when "en" is absent
    // so the legacy content keeps serving until Phase D migrates it.
    final en = raw['en'] is String
        ? raw['en'] as String
        : (raw['meaning'] is String ? raw['meaning'] as String : '');
    return StudyTerm(
      term: term.trim(),
      language: raw['language'] is String ? raw['language'] as String : '',
      transliteration: raw['transliteration'] is String
          ? raw['transliteration'] as String
          : null,
      verseNumber: raw['verseNumber'] is int ? raw['verseNumber'] as int : null,
      en: en,
      am: raw['am'] is String ? raw['am'] as String : '',
    );
  }
}

/// The memory anchor: exactly three elements — a key image, a key word, and a
/// one-sentence statement of the passage's central movement. Never an
/// application, never a command, never a revelation. Generated once, stored in
/// the cached payload, and rendered as a small always-visible card.
class StudyAnchor {
  final String imageEn;
  final String imageAm;
  final String keywordEn;
  final String keywordAm;
  final String sentenceEn;
  final String sentenceAm;

  const StudyAnchor({
    this.imageEn = '',
    this.imageAm = '',
    this.keywordEn = '',
    this.keywordAm = '',
    this.sentenceEn = '',
    this.sentenceAm = '',
  });

  bool get isEmpty =>
      imageEn.trim().isEmpty &&
      imageAm.trim().isEmpty &&
      keywordEn.trim().isEmpty &&
      keywordAm.trim().isEmpty &&
      sentenceEn.trim().isEmpty &&
      sentenceAm.trim().isEmpty;

  String imageFor(bool isAm) {
    final t = isAm ? imageAm : imageEn;
    return t.trim();
  }

  String keywordFor(bool isAm) {
    final t = isAm ? keywordAm : keywordEn;
    return t.trim();
  }

  String sentenceFor(bool isAm) {
    final t = isAm ? sentenceAm : sentenceEn;
    return t.trim();
  }

  Map<String, dynamic> toJson() => {
        'imageEn': imageEn,
        'imageAm': imageAm,
        'keywordEn': keywordEn,
        'keywordAm': keywordAm,
        'sentenceEn': sentenceEn,
        'sentenceAm': sentenceAm,
      };

  static StudyAnchor? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final anchor = StudyAnchor(
      imageEn: raw['imageEn'] is String ? raw['imageEn'] as String : '',
      imageAm: raw['imageAm'] is String ? raw['imageAm'] as String : '',
      keywordEn: raw['keywordEn'] is String ? raw['keywordEn'] as String : '',
      keywordAm: raw['keywordAm'] is String ? raw['keywordAm'] as String : '',
      sentenceEn: raw['sentenceEn'] is String ? raw['sentenceEn'] as String : '',
      sentenceAm: raw['sentenceAm'] is String ? raw['sentenceAm'] as String : '',
    );
    return anchor.isEmpty ? null : anchor;
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

  /// The app's free daily AI allowance is exhausted (and the reader has not
  /// connected their own Gemini key). A sentinel, never persisted — the panel
  /// turns it into the "used today's free sessions / add your own key" prompt
  /// instead of silently falling back to offline content.
  limitReached,
}

/// Why a study request could not be answered by the intended producer (the AI,
/// then the offline fallbacks). `none` means no reason — the attempt carried a
/// real note (or the chain simply had nothing more to try). Every other value
/// is a *visible, reader-facing* reason: the panel must always explain why AI
/// study is unavailable rather than silently presenting offline content.
enum StudyUnavailability {
  /// No reason to surface — either a real note was produced or the chain
  /// legitimately has nothing more to offer.
  none,

  /// The device has no usable network connection.
  offline,

  /// The AI provider throttled the request (429) — transient, worth a retry.
  rateLimited,

  /// The AI call took too long and was abandoned.
  timeout,

  /// The AI provider rejected the credentials (invalid/revoked key, 401/403).
  authInvalid,

  /// The AI provider failed for another reason (bad model, 4xx/5xx, generic).
  server,

  /// The model replied, but the strict content/honesty validator refused it.
  contentRejected,

  /// The app's free daily AI allowance is exhausted (and no personal key).
  capped,
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

  /// Stable key for the SharedPreferences cache (language, prompt version, and
  /// depth are added by the service).
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

  /// The book's literary genre, when known. Deterministic for a given book; it
  /// shapes the note's voice and the automatic depth default.
  final StudyGenre? genre;

  /// The depth of the note. Included in the cache key.
  final StudyDepth depth;

  /// The app's curated book profile (background + flow) in the reader's
  /// language, when available. The only external knowledge the model may
  /// reorganize — never add beyond it.
  final String? profileText;

  const StudyRequest({
    required this.reference,
    required this.isAmharic,
    required this.verseTexts,
    this.genre,
    this.depth = StudyDepth.standard,
    this.profileText,
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
/// Typed sub-lists carry a section's structured content:
/// `verseObservations` (verseByVerse), `historyEntries`
/// (historicalBackground), `terms` (originalLanguage), `references`
/// (scriptureInterconnections), `blocks` (explicitTeachings). `questionsToCarry`
/// uses [en]/[am] for the questions and [enSub]/[amSub] for the threads.
class StudySection {
  final StudySectionKind kind;
  final String en;
  final String am;
  final String? enSub;
  final String? amSub;
  final List<StudyCrossReference> references;
  final List<StudyTieredBlock> blocks;
  final List<StudyTerm> terms;
  final List<StudyHistoryEntry> historyEntries;
  final List<StudyVerseObservation> verseObservations;

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
    this.historyEntries = const [],
    this.verseObservations = const [],
    this.confidence,
    this.sourceIds = const [],
  });

  /// True when the section has no renderable content ("preserve silence").
  bool get isEmpty {
    switch (kind) {
      case StudySectionKind.scriptureInterconnections:
        return references.isEmpty;
      case StudySectionKind.explicitTeachings:
        return blocks.isEmpty;
      case StudySectionKind.verseByVerse:
        return verseObservations.isEmpty;
      case StudySectionKind.historicalBackground:
        return en.trim().isEmpty &&
            am.trim().isEmpty &&
            historyEntries.isEmpty;
      case StudySectionKind.originalLanguage:
        return en.trim().isEmpty && am.trim().isEmpty && terms.isEmpty;
      default:
        return en.trim().isEmpty &&
            am.trim().isEmpty &&
            (enSub ?? '').trim().isEmpty &&
            (amSub ?? '').trim().isEmpty;
    }
  }

  /// The primary text in the reader's language.
  String textFor(bool isAm) {
    final t = isAm ? am : en;
    return t.trim();
  }

  /// The second text half in the reader's language (threads on
  /// questionsToCarry), when present.
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
        if (blocks.isNotEmpty)
          'blocks': blocks.map((b) => b.toJson()).toList(),
        if (terms.isNotEmpty) 'terms': terms.map((t) => t.toJson()).toList(),
        if (historyEntries.isNotEmpty)
          'historyEntries': historyEntries.map((h) => h.toJson()).toList(),
        if (verseObservations.isNotEmpty)
          'verseObservations':
              verseObservations.map((v) => v.toJson()).toList(),
        if (confidence != null) 'confidence': confidence!.name,
        if (sourceIds.isNotEmpty) 'sourceIds': sourceIds,
      };

  /// Legacy kind ids shipped in the v2 bank asset. They map onto the new
  /// workbook sections so the bundled bank keeps serving until Phase D migrates
  /// the content.
  static const Map<String, StudySectionKind> _legacyKinds = {
    'setting': StudySectionKind.passageOverview,
    'context': StudySectionKind.historicalBackground,
    'whatTextSays': StudySectionKind.literaryContext,
    'meaningBackground': StudySectionKind.originalLanguage,
    'biblicalConnections': StudySectionKind.scriptureInterconnections,
    'whatCanBeUnderstood': StudySectionKind.explicitTeachings,
    'reflection': StudySectionKind.questionsToCarry,
  };

  static StudySection? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final kindRaw = raw['kind'];
    final kind = kindRaw is String
        ? (StudySectionKind.values
                    .where((k) => k.name == kindRaw)
                    .firstOrNull ??
                _legacyKinds[kindRaw])
        : null;
    if (kind == null) return null;
    // The bundled v2 bank carried the reflection's quiet takeaway line under
    // "takeawayEn"/"takeawayAm"; the workbook keeps that second half as the
    // questionsToCarry sub-text, so carry it over when the new keys are absent.
    final enSub = raw['enSub'] is String
        ? raw['enSub'] as String
        : (raw['takeawayEn'] is String ? raw['takeawayEn'] as String : null);
    final amSub = raw['amSub'] is String
        ? raw['amSub'] as String
        : (raw['takeawayAm'] is String ? raw['takeawayAm'] as String : null);
    final section = StudySection(
      kind: kind,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
      enSub: enSub,
      amSub: amSub,
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
      historyEntries: (raw['historyEntries'] as List<dynamic>? ?? [])
          .map(StudyHistoryEntry.tryParse)
          .whereType<StudyHistoryEntry>()
          .toList(),
      verseObservations: (raw['verseObservations'] as List<dynamic>? ?? [])
          .map(StudyVerseObservation.tryParse)
          .whereType<StudyVerseObservation>()
          .toList(),
      confidence: StudyConfidence.values
          .where((c) => c.name == raw['confidence'])
          .firstOrNull,
      sourceIds: raw['sourceIds'] is List
          ? (raw['sourceIds'] as List).whereType<String>().toList()
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

  /// The memory anchor, when the note carries one. Omitted when unavailable —
  /// never invented.
  final StudyAnchor? anchor;
  final DateTime cachedAt;
  final bool isAvailable;

  /// True when the note is the quiet offline assembly that also signals the
  /// app's free daily AI allowance was exhausted. The panel uses this to show
  /// the "used today's free sessions / add your own key" prompt. Transient —
  /// never serialized to the cache (an offline note is memory-only anyway).
  final bool limitReached;

  /// Why AI study was unavailable for this note, when it was. `none` for real
  /// AI/bank notes and for notes served with no attached reason. Attached to
  /// offline/limited assemblies so the panel can always say why AI wasn't
  /// used. Transient — never serialized to the cache.
  final StudyUnavailability unavailability;

  const StudyResult({
    required this.reference,
    required this.source,
    required this.sections,
    this.anchor,
    required this.cachedAt,
    required this.isAvailable,
    this.limitReached = false,
    this.unavailability = StudyUnavailability.none,
  });

  factory StudyResult.unavailable({required StudyReference reference}) =>
      StudyResult(
        reference: reference,
        source: StudySource.localBank,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: false,
      );

  /// The sentinel for "the app's free daily AI allowance is exhausted." The
  /// service replaces it with the offline note (flagged [limitReached]) when
  /// the bundled knowledge layers can produce one; otherwise this empty note
  /// reaches the panel alone.
  factory StudyResult.aiLimit({required StudyReference reference}) =>
      StudyResult(
        reference: reference,
        source: StudySource.limitReached,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: false,
        limitReached: true,
      );

  /// A copy that may mark the note as an offline assembly surfaced after the
  /// free AI limit was hit and/or attach the reason AI was unavailable. Only
  /// the transient flags are overridable here.
  StudyResult copyWith({
    bool? limitReached,
    StudyUnavailability? unavailability,
  }) =>
      StudyResult(
        reference: reference,
        source: source,
        sections: sections,
        anchor: anchor,
        cachedAt: cachedAt,
        isAvailable: isAvailable,
        limitReached: limitReached ?? this.limitReached,
        unavailability: unavailability ?? this.unavailability,
      );

  String toJsonString() {
    final body = {
      'v': _cacheVersion,
      'source': source.name,
      'cachedAt': cachedAt.toIso8601String(),
      'sections': sections.map((s) => s.toJson()).toList(),
      if (anchor != null) 'anchor': anchor!.toJson(),
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
        anchor: StudyAnchor.tryParse(data['anchor']),
        cachedAt: DateTime.tryParse(data['cachedAt'] as String? ?? '') ??
            DateTime.now(),
        isAvailable: true,
      );
    } catch (_) {
      return null;
    }
  }
}

/// The outcome of a single backend attempt: either a usable [result] or a
/// concrete [unavailability] reason why nothing came back. A backend that
/// produced nothing **must** say why (or explicitly [StudyAttempt.nothing] to
/// let the next layer of the chain try) — silent `null` collapse is what hid
/// real failures, so the attempt type makes the reason first-class.
class StudyAttempt {
  final StudyResult? result;
  final StudyUnavailability unavailability;

  const StudyAttempt._(this.result, this.unavailability)
      : assert(result == null || unavailability == StudyUnavailability.none,
            'an available result never carries an unavailability reason');

  /// A real, usable note.
  const StudyAttempt.available(StudyResult result)
      : this._(result, StudyUnavailability.none);

  /// Nothing produced, and nothing more to say — the composer moves on to the
  /// next layer of its chain (a bank miss, for example).
  const StudyAttempt.nothing()
      : this._(null, StudyUnavailability.none);

  /// Nothing produced, with the reason the reader must be told.
  const StudyAttempt.unavailable(StudyUnavailability reason)
      : this._(null, reason);

  bool get isAvailable => result != null;
}
