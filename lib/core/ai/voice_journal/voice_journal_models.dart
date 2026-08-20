import 'dart:convert';

/// The "Voice Journal" AI layer — the data types.
///
/// This subsystem sits next to "Delve Deeper" and the Study layer as its own
/// independent chain: its own transport, validator, service, cache, usage gate,
/// and observability. It is deliberately separate so the Study workbook and the
/// plain Today's Journal are never changed by it.
///
/// The defining contract: the AI is an **editor, not an author**. It may only
/// reorganize, tighten, group, and transcribe-fix the reader's own words —
/// never add events, emotions, spiritual claims, or revelation.

/// Bump when the voice-journal prompt, schema, or generation rules change so
/// cached organized journals from an older version are never served.
const int voiceJournalPromptVersion = 1;

/// The version of the serialized voice-journal cache payload.
const int _voiceJournalCacheVersion = 1;

/// Hard ceiling on the transcript the AI is asked to organize. Longer voice
/// notes are transparently trimmed (with a reader-visible notice) before the
/// request is built, so a single turn stays small and honest.
const int voiceJournalMaxTranscriptChars = 6000;

/// The exact deliverable blocks of an organized voice journal, in render order.
enum VoiceNoteSectionKind {
  /// What happened today — chronological facts from the user's own words.
  whatHappened,

  /// Emotions the user expressed — never invented ones.
  emotions,

  /// Spiritual moments the user shared — never generated.
  spiritualMoments,

  /// Important insights from the user's own thinking.
  insights,

  /// One sentence to remember — drawn from the user's own words.
  sentenceToRemember,
}

/// Which engine produced an organized journal. Currently always the AI model.
enum VoiceJournalSource { gemini }

/// Why a voice journal could not be answered. Every non-`none` value is a
/// visible, reader-facing reason — never a silent blank.
enum VoiceJournalUnavailability {
  none,
  permissionDenied,
  noRecognitionEngine,
  languageNotSupported,
  tooLong,
  offline,
  rateLimited,
  timeout,
  authInvalid,
  server,
  contentRejected,
  capped,
}

/// A stable, dependency-free content hash used to key the AI cache by exact
/// transcript, so re-organizing identical text is never billed again.
String voiceJournalTranscriptKey(String raw) {
  var h = 0x811c9dc5;
  final normalized = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  for (final unit in normalized.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xffffffff;
  }
  return h.toRadixString(16);
}

/// Trim a transcript to the hard ceiling for organization. The caller shows the
/// notice; this only ever cuts the tail so a long morning monologue still gets
/// organized rather than rejected wholesale.
String capVoiceJournalTranscript(String raw) {
  final t = raw.trim();
  if (t.length <= voiceJournalMaxTranscriptChars) return t;
  return t.substring(0, voiceJournalMaxTranscriptChars).trimRight();
}

/// The on-demand voice-journal organize request. Generated only when the user
/// presses "Organize" — never automatically.
class VoiceJournalRequest {
  final String transcript;
  final bool isAmharic;

  const VoiceJournalRequest({required this.transcript, required this.isAmharic});
}

/// One block of an organized voice journal. A single-language organized note
/// keeps only the reader's language populated; the sheet answers with
/// [textFor].
class VoiceNoteSection {
  final VoiceNoteSectionKind kind;
  final String en;
  final String am;

  const VoiceNoteSection({required this.kind, this.en = '', this.am = ''});

  bool get isEmpty => en.trim().isEmpty && am.trim().isEmpty;

  String textFor(bool isAm) => (isAm ? am : en).trim();

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'en': en,
        'am': am,
      };

  static VoiceNoteSection? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final kindRaw = raw['kind'];
    final kind = kindRaw is String
        ? VoiceNoteSectionKind.values
            .where((k) => k.name == kindRaw)
            .firstOrNull
        : null;
    if (kind == null) return null;
    final section = VoiceNoteSection(
      kind: kind,
      en: raw['en'] is String ? raw['en'] as String : '',
      am: raw['am'] is String ? raw['am'] as String : '',
    );
    return section.isEmpty ? null : section;
  }
}

/// The organized voice journal delivered to the sheet. `isAvailable == false`
/// is the graceful, always-explained fallback — never fabricated content.
class VoiceJournalResult {
  final VoiceJournalSource source;
  final List<VoiceNoteSection> sections;
  final DateTime cachedAt;
  final bool isAvailable;

  /// True when the app's free daily voice-journal allowance was exhausted. The
  /// sheet turns it into the "add your own key" prompt. Transient — never
  /// serialized to the cache.
  final bool limitReached;

  /// Why organizing was unavailable, when it was. Transient — never serialized
  /// to the cache.
  final VoiceJournalUnavailability unavailability;

  const VoiceJournalResult({
    required this.source,
    required this.sections,
    required this.cachedAt,
    required this.isAvailable,
    this.limitReached = false,
    this.unavailability = VoiceJournalUnavailability.none,
  });

  factory VoiceJournalResult.unavailable({
    required VoiceJournalUnavailability unavailability,
  }) =>
      VoiceJournalResult(
        source: VoiceJournalSource.gemini,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: false,
        unavailability: unavailability,
      );

  /// The sentinel for "the free daily voice-journal allowance is exhausted."
  factory VoiceJournalResult.voiceJournalLimit() => VoiceJournalResult(
        source: VoiceJournalSource.gemini,
        sections: const [],
        cachedAt: DateTime.now(),
        isAvailable: false,
        limitReached: true,
        unavailability: VoiceJournalUnavailability.capped,
      );

  VoiceJournalResult copyWith({
    bool? limitReached,
    VoiceJournalUnavailability? unavailability,
  }) =>
      VoiceJournalResult(
        source: source,
        sections: sections,
        cachedAt: cachedAt,
        isAvailable: isAvailable,
        limitReached: limitReached ?? this.limitReached,
        unavailability: unavailability ?? this.unavailability,
      );

  String toJsonString() => jsonEncode({
        'v': _voiceJournalCacheVersion,
        'source': source.name,
        'cachedAt': cachedAt.toIso8601String(),
        'sections': sections.map((s) => s.toJson()).toList(),
      });

  static VoiceJournalResult? tryParse(String raw) {
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final sections = (data['sections'] as List<dynamic>? ?? [])
          .map(VoiceNoteSection.tryParse)
          .whereType<VoiceNoteSection>()
          .toList();
      if (sections.isEmpty) return null;
      return VoiceJournalResult(
        source: VoiceJournalSource.values
            .where((s) => s.name == data['source'])
            .firstOrNull ??
            VoiceJournalSource.gemini,
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

/// The outcome of a single voice-journal backend attempt: a usable [result] or
/// a concrete [unavailability] reason. A silent `null` result is never produced.
class VoiceJournalAttempt {
  final VoiceJournalResult? result;
  final VoiceJournalUnavailability unavailability;

  const VoiceJournalAttempt._(this.result, this.unavailability)
      : assert(result == null || unavailability == VoiceJournalUnavailability.none,
            'an available result never carries an unavailability reason');

  const VoiceJournalAttempt.available(VoiceJournalResult result)
      : this._(result, VoiceJournalUnavailability.none);

  const VoiceJournalAttempt.unavailable(VoiceJournalUnavailability reason)
      : this._(null, reason);

  bool get isAvailable => result != null;
}