import 'dart:convert';

import '../study/study_intro.dart';
import '../study/study_models.dart';

/// The on-demand "Delve Deeper" deep-study layer — the data types.
///
/// This subsystem is deliberately independent of the main Study workbook: it
/// has its own prompt, validator, service, cache, and usage gate, so the
/// default Study experience is never changed. It reuses only a few *read-only*
/// data carriers (the canonical reference type and the evidence/tier enums)
/// so a deep note speaks the same honest, canon-verified vocabulary the app
/// already guarantees.

/// Bump when the deep-study prompt, schema, or generation rules change so
/// cached deep notes from an older version are never served.
const int delvePromptVersion = 1;

/// The version of the serialized Delve cache payload.
const int _delveCacheVersion = 1;

/// The exact deliverable blocks of a deep-study note, in render order.
enum DelveSectionKind {
  /// Expanded historical background: evidence-categorized entries plus prose.
  expandedHistory,

  /// Literary analysis: movement, structure, imagery — observations only.
  literaryAnalysis,

  /// Original-language analysis: important terms with honest meanings.
  originalLanguage,

  /// Expanded cross-reference study, validated against the deterministic canon.
  expandedCrossReferences,

  /// Historically documented interpretations, labeled by tier and attribution.
  documentedInterpretations,

  /// Structured observations, anchored to verses inside the studied passage.
  structuredObservations,
}

/// Which engine produced a deep note. Currently always the AI model.
enum DelveSource { gemini }

/// Why a deep-study request could not be answered. Every non-`none` value is a
/// visible, reader-facing reason — never a silent blank.
enum DelveUnavailability {
  none,
  offline,
  rateLimited,
  timeout,
  authInvalid,
  server,
  contentRejected,
  capped,
}

/// The on-demand deep-study request. Generated only when the reader presses
/// "Delve Deeper" — never at study-panel open.
class DelveRequest {
  final StudyReference reference;
  final bool isAmharic;
  final List<String> verseTexts;

  /// The book's literary genre, when known (from the bundled intro library).
  final StudyGenre? genre;

  const DelveRequest({
    required this.reference,
    required this.isAmharic,
    required this.verseTexts,
    this.genre,
  });
}

/// One evidence-categorized historical entry in a deep note.
class DelveHistoryEntry {
  final StudyHistoryCategory category;
  final StudyHistoryLabel label;
  final String en;
  final String am;

  const DelveHistoryEntry({
    required this.category,
    required this.label,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => en.trim().isEmpty && am.trim().isEmpty;

  String textFor(bool isAm) => (isAm ? am : en).trim();

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'label': label.name,
        'en': en,
        'am': am,
      };

  static DelveHistoryEntry? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final category = StudyHistoryCategory.values
        .where((c) => c.name == raw['category'])
        .firstOrNull;
    final label =
        StudyHistoryLabel.values.where((l) => l.name == raw['label']).firstOrNull;
    if (category == null || label == null) return null;
    final entry = DelveHistoryEntry(
      category: category,
      label: label,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
    return entry.isEmpty ? null : entry;
  }
}

/// One important original-language term in a deep note. The term stays in its
/// own script; the meaning is carried in both languages.
class DelveTerm {
  final String term;
  final String language;
  final String? transliteration;
  final int? verseNumber;
  final String en;
  final String am;

  const DelveTerm({
    required this.term,
    this.language = '',
    this.transliteration,
    this.verseNumber,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => term.trim().isEmpty;

  String meaningFor(bool isAm) => (isAm ? am : en).trim();

  Map<String, dynamic> toJson() => {
        'term': term,
        if (language.isNotEmpty) 'language': language,
        if (transliteration != null && transliteration!.isNotEmpty)
          'transliteration': transliteration,
        if (verseNumber != null) 'verseNumber': verseNumber,
        'en': en,
        'am': am,
      };

  static DelveTerm? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final term = raw['term'];
    if (term is! String || term.trim().isEmpty) return null;
    final meaningEn = raw['en'] is String
        ? raw['en'] as String
        : (raw['meaning'] is String ? raw['meaning'] as String : '');
    return DelveTerm(
      term: term.trim(),
      language: raw['language'] is String ? raw['language'] as String : '',
      transliteration:
          raw['transliteration'] is String ? raw['transliteration'] as String : null,
      verseNumber: raw['verseNumber'] is int ? raw['verseNumber'] as int : null,
      en: meaningEn,
      am: raw['am'] is String ? raw['am'] as String : '',
    );
  }
}

/// A historically documented interpretation, labeled by tier and, when known,
/// by the tradition, era, or writer it is attributed to. Never a personal
/// application and never presented above its honest tier.
class DelveInterpretation {
  final StudyTier tier;
  final String? attributedTo;
  final String en;
  final String am;

  const DelveInterpretation({
    required this.tier,
    this.attributedTo,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => en.trim().isEmpty && am.trim().isEmpty;

  String textFor(bool isAm) => (isAm ? am : en).trim();

  String? attributionFor(bool isAm) {
    final a = attributedTo;
    if (a == null || a.trim().isEmpty) return null;
    return a.trim();
  }

  Map<String, dynamic> toJson() => {
        'tier': tier.name,
        if (attributedTo != null && attributedTo!.isNotEmpty)
          'attributedTo': attributedTo,
        'en': en,
        'am': am,
      };

  static DelveInterpretation? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final tier =
        StudyTier.values.where((t) => t.name == raw['tier']).firstOrNull;
    if (tier == null) return null;
    final interpretation = DelveInterpretation(
      tier: tier,
      attributedTo:
          raw['attributedTo'] is String ? raw['attributedTo'] as String : null,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
    return interpretation.isEmpty ? null : interpretation;
  }
}

/// One verse-anchored structured observation inside the studied passage.
class DelveObservation {
  final int startVerse;
  final int endVerse;
  final String en;
  final String am;

  const DelveObservation({
    required this.startVerse,
    required this.endVerse,
    this.en = '',
    this.am = '',
  });

  bool get isEmpty => en.trim().isEmpty && am.trim().isEmpty;

  String textFor(bool isAm) => (isAm ? am : en).trim();

  Map<String, dynamic> toJson() => {
        'startVerse': startVerse,
        'endVerse': endVerse,
        'en': en,
        'am': am,
      };

  static DelveObservation? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final startVerse = raw['startVerse'];
    final endVerse = raw['endVerse'];
    if (startVerse is! int || endVerse is! int) return null;
    if (startVerse < 1 || endVerse < startVerse) return null;
    final observation = DelveObservation(
      startVerse: startVerse,
      endVerse: endVerse,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
    return observation.isEmpty ? null : observation;
  }
}

/// One block of a deep-study note. A single-language AI note keeps only the
/// reader's language populated; the panel answers with [textFor].
class DelveSection {
  final DelveSectionKind kind;
  final String en;
  final String am;
  final List<DelveHistoryEntry> historyEntries;
  final List<DelveTerm> terms;

  /// Canon-validated cross-references. The [`StudyCrossReference`] type is
  /// reused read-only: same canon check, same localized labels.
  final List<StudyCrossReference> references;

  final List<DelveInterpretation> interpretations;
  final List<DelveObservation> observations;

  const DelveSection({
    required this.kind,
    this.en = '',
    this.am = '',
    this.historyEntries = const [],
    this.terms = const [],
    this.references = const [],
    this.interpretations = const [],
    this.observations = const [],
  });

  /// True when the section has no renderable content ("preserve silence").
  bool get isEmpty {
    switch (kind) {
      case DelveSectionKind.expandedHistory:
        return en.trim().isEmpty && am.trim().isEmpty && historyEntries.isEmpty;
      case DelveSectionKind.literaryAnalysis:
        return en.trim().isEmpty && am.trim().isEmpty;
      case DelveSectionKind.originalLanguage:
        return en.trim().isEmpty && am.trim().isEmpty && terms.isEmpty;
      case DelveSectionKind.expandedCrossReferences:
        return references.isEmpty;
      case DelveSectionKind.documentedInterpretations:
        return interpretations.isEmpty;
      case DelveSectionKind.structuredObservations:
        return observations.isEmpty;
    }
  }

  String textFor(bool isAm) => (isAm ? am : en).trim();

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'en': en,
        'am': am,
        if (historyEntries.isNotEmpty)
          'historyEntries': historyEntries.map((e) => e.toJson()).toList(),
        if (terms.isNotEmpty) 'terms': terms.map((t) => t.toJson()).toList(),
        if (references.isNotEmpty)
          'references': references.map((r) => r.toJson()).toList(),
        if (interpretations.isNotEmpty)
          'interpretations':
              interpretations.map((i) => i.toJson()).toList(),
        if (observations.isNotEmpty)
          'observations': observations.map((o) => o.toJson()).toList(),
      };

  static DelveSection? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final kindRaw = raw['kind'];
    final kind = kindRaw is String
        ? DelveSectionKind.values
            .where((k) => k.name == kindRaw)
            .firstOrNull
        : null;
    if (kind == null) return null;
    final section = DelveSection(
      kind: kind,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
      historyEntries: (raw['historyEntries'] as List<dynamic>? ?? [])
          .map(DelveHistoryEntry.tryParse)
          .whereType<DelveHistoryEntry>()
          .toList(),
      terms: (raw['terms'] as List<dynamic>? ?? [])
          .map(DelveTerm.tryParse)
          .whereType<DelveTerm>()
          .toList(),
      references: (raw['references'] as List<dynamic>? ?? [])
          .map(StudyCrossReference.tryParse)
          .whereType<StudyCrossReference>()
          .toList(),
      interpretations: (raw['interpretations'] as List<dynamic>? ?? [])
          .map(DelveInterpretation.tryParse)
          .whereType<DelveInterpretation>()
          .toList(),
      observations: (raw['observations'] as List<dynamic>? ?? [])
          .map(DelveObservation.tryParse)
          .whereType<DelveObservation>()
          .toList(),
    );
    if (section.isEmpty) return null;
    return section;
  }
}

/// The deep-study result delivered to the panel. `isAvailable == false` is the
/// graceful, always-explained fallback — never fabricated content.
class DelveResult {
  final StudyReference reference;
  final DelveSource source;
  final List<DelveSection> sections;
  final DateTime cachedAt;
  final bool isAvailable;

  /// True when the app's free daily deep-study allowance was exhausted. The
  /// panel turns it into the "add your own key" prompt. Transient — never
  /// serialized to the cache.
  final bool limitReached;

  /// Why the deep study was unavailable, when it was. Transient — never
  /// serialized to the cache.
  final DelveUnavailability unavailability;

  const DelveResult({
    required this.reference,
    required this.source,
    required this.sections,
    required this.cachedAt,
    required this.isAvailable,
    this.limitReached = false,
    this.unavailability = DelveUnavailability.none,
  });

  factory DelveResult.unavailable({required StudyReference reference}) =>
      DelveResult(
        reference: reference,
        source: DelveSource.gemini,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: false,
      );

  /// The sentinel for "the free daily deep-study allowance is exhausted."
  factory DelveResult.delveLimit({required StudyReference reference}) =>
      DelveResult(
        reference: reference,
        source: DelveSource.gemini,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: false,
        limitReached: true,
        unavailability: DelveUnavailability.capped,
      );

  DelveResult copyWith({
    bool? limitReached,
    DelveUnavailability? unavailability,
  }) =>
      DelveResult(
        reference: reference,
        source: source,
        sections: sections,
        cachedAt: cachedAt,
        isAvailable: isAvailable,
        limitReached: limitReached ?? this.limitReached,
        unavailability: unavailability ?? this.unavailability,
      );

  String toJsonString() => jsonEncode({
        'v': _delveCacheVersion,
        'source': source.name,
        'cachedAt': cachedAt.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
      });

  static DelveResult? tryParse(String raw, StudyReference reference) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final sections = (data['sections'] as List<dynamic>? ?? [])
          .map(DelveSection.tryParse)
          .whereType<DelveSection>()
          .toList();
      return DelveResult(
        reference: reference,
        source: DelveSource.values
            .where((s) => s.name == data['source'])
            .firstOrNull ??
            DelveSource.gemini,
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

/// The outcome of a single deep-study backend attempt: a usable [result] or a
/// concrete [unavailability] reason. A silent `null` result is never produced.
class DelveAttempt {
  final DelveResult? result;
  final DelveUnavailability unavailability;

  const DelveAttempt._(this.result, this.unavailability)
      : assert(result == null || unavailability == DelveUnavailability.none,
            'an available result never carries an unavailability reason');

  const DelveAttempt.available(DelveResult result)
      : this._(result, DelveUnavailability.none);

  const DelveAttempt.unavailable(DelveUnavailability reason)
      : this._(null, reason);

  bool get isAvailable => result != null;
}