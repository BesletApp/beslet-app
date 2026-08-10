import '../services/scripture_service.dart';

/// The Quiet Guide — core types.
///
/// The LLM is a *selector*, never a writer. Every visible word is either a
/// canonical Scripture reference (validated against `ScriptureService.bookMap`)
/// or a hand-written line from the curated bank (`ai_bank.json`). These types
/// make that boundary airtight: a selector can only name an item that already
/// exists, and the validator rejects anything else before it can reach a user.

/// How a quiet moment may appear. Silence is a first-class mode, not an error.
enum AiMode { scripturePointer, reflectiveGuidance, silence }

/// Where a moment appears in the app. Phase 2 wires the triggers; Phase 1 only
/// defines them so the boundary gate and the bank can be built on them.
enum AiMomentType {
  /// After finishing a chapter — a still point, one pointer, then nothing.
  stillPoint,

  /// After completing a Word Challenge build — a gentle reminder of the Word
  /// behind the work.
  wordChallengePointer,

  /// Prayer rest/ask — a day-fit verse matching the posture the user chose.
  prayerDayFit,

  /// Fasting / church-season-aware selection (Phase 2 fills the calendar).
  fastingAware,

  /// Opt-in weekly reflection companion (Phase 4).
  weeklyReflection,
}

/// Which engine produced a choice — keeps the Gemini seam honest and lets a
/// future local model be measured against it.
enum AiSource { local, gemini }

// ─── Coarse context buckets ────────────────────────────────────────────────
// Only enums and booleans — never names, journal text, device ids, location,
// or raw counts. The anti-surveillance contract is enforced by the *shape* of
// `ContextPacket`: it is impossible to put a number or a string of text in it.

enum AiLanguageBucket { amharic, english }

enum AiDayPartBucket { morning, afternoon, evening, night }

/// A coarse, gently-mapped maturity level derived from the journey season.
enum AiMaturityBucket { seeding, growing, rooted }

enum AiEngagementBucket { low, steady, deep }

enum AiAbsenceBucket { present, returning }

/// The entire picture a selector may see.
class ContextPacket {
  final AiLanguageBucket language;
  final AiDayPartBucket dayPart;
  final AiMaturityBucket maturity;
  final AiEngagementBucket engagement;
  final AiAbsenceBucket absence;
  final bool isRestDay;
  final bool isFastingSeason;

  const ContextPacket({
    required this.language,
    required this.dayPart,
    required this.maturity,
    required this.engagement,
    required this.absence,
    this.isRestDay = false,
    this.isFastingSeason = false,
  });
}

// ─── The raw selector output (pre-validation) ──────────────────────────────

/// The raw, unvalidated choice a selector returns. The model is told to answer
/// only with an existing pointer/question id, never free-form Scripture.
class AiOutput {
  final String? mode; // 'scripturePointer' | 'reflectiveGuidance' | 'silence'
  final String? itemId; // a bank pointer/question id, or null for silence

  const AiOutput({this.mode, this.itemId});

  factory AiOutput.fromJson(Map<String, dynamic> json) => AiOutput(
        mode: json['mode'] as String?,
        itemId: json['itemId'] as String?,
      );
}

// ─── A canonical, validated reference ──────────────────────────────────────

class AiReference {
  final String bookId;
  final int chapter;
  final int verse;
  final int? endVerse;

  const AiReference({
    required this.bookId,
    required this.chapter,
    required this.verse,
    this.endVerse,
  });

  /// Localized label, e.g. "Psalm 23:1" or "መዝሙረ ዳዊት 23:1-3".
  String referenceFor(bool isAmharic) {
    final book = ScriptureService.bookMap[bookId];
    final name = book != null ? (isAmharic ? book.nameAm : book.nameEn) : bookId;
    final base = '$name $chapter:$verse';
    if (endVerse == null || endVerse == verse) return base;
    return '$base-$endVerse';
  }
}

// ─── The validated, resolved decision ──────────────────────────────────────

/// A decision that has passed the validator. `mode == silence` means nothing
/// is shown; everything else references only pre-existing, allow-listed items.
class AiChoice {
  final AiMode mode;
  final String? itemId; // pointer or question id, validated against the bank
  final AiReference? reference; // resolved when the item is a pointer

  const AiChoice({required this.mode, this.itemId, this.reference});

  bool get isSilent => mode == AiMode.silence;
}

/// The result a moment delivers to the UI (Phase 2) — everything is either a
/// canonical reference label or a hand-written line from the bank.
class QuietGuideResult {
  final AiMode mode;
  final String? reference; // localized canonical reference, for pointers
  final String? line; // localized bank line, for reflective guidance
  final AiSource source;

  const QuietGuideResult({
    required this.mode,
    this.reference,
    this.line,
    this.source = AiSource.local,
  });

  bool get isSilent => mode == AiMode.silence;

  const QuietGuideResult.silent() : this(mode: AiMode.silence, source: AiSource.local);
}

/// A moment record — the only thing the app persists about a quiet moment.
/// Deliberately minimal and non-personal: which moment, which mode, which
/// engine, which day. No journal text, no input, no personal data.
class AiMoment {
  final String dayKey; // local yyyy-MM-dd
  final AiMomentType type;
  final AiMode mode;
  final AiSource source;
  final String? reference; // canonical label, when a pointer was offered
  final String? itemId;
  final DateTime createdAt;

  const AiMoment({
    required this.dayKey,
    required this.type,
    required this.mode,
    required this.source,
    this.reference,
    this.itemId,
    required this.createdAt,
  });
}
