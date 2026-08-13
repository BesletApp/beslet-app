import 'study_backend.dart';
import 'study_cross_refs.dart';
import 'study_intro.dart';
import 'study_models.dart';

/// Orchestrates a study lookup: in-memory cache first, then the single-flight
/// dedup, then the persistent disk cache, then the backend, and finally — when
/// the backend honestly has nothing — a deterministic offline note assembled
/// from the bundled knowledge layers (book intro + cross-reference index) so a
/// canon passage is never left blank. Every step is non-blocking and can never
/// raise to the caller.
class StudyService {
  final StudyBackend backend;
  final Future<String?> Function(String key) readCache;
  final Future<void> Function(String key, String value) writeCache;

  /// Optional bundled knowledge layers used for the never-blank offline
  /// assembly. When absent, an empty backend result becomes the quiet
  /// "unavailable" note.
  final StudyIntroLibrary? intros;
  final StudyCrossRefIndex? crossRefs;

  /// In-memory results: a repeated open within a session is served instantly
  /// and never re-runs the backend or the disk cache.
  final Map<String, StudyResult> _memory = {};

  /// Single-flight dedup: concurrent requests for the same key share one
  /// future, so the backend is called at most once per key at a time.
  final Map<String, Future<StudyResult>> _inflight = {};

  StudyService({
    required this.backend,
    required this.readCache,
    required this.writeCache,
    this.intros,
    this.crossRefs,
  });

  /// The key includes the prompt version so a note generated under an older
  /// prompt or schema is never served from cache.
  String cacheKeyFor(StudyRequest request) =>
      'study_v${studyPromptVersion}_${request.reference.cacheKey}_${request.isAmharic ? 'am' : 'en'}';

  Future<StudyResult> study(StudyRequest request) async {
    final key = cacheKeyFor(request);

    final memo = _memory[key];
    if (memo != null) return memo;

    final running = _inflight[key];
    if (running != null) return running;

    final future = _resolve(key, request);
    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<StudyResult> _resolve(String key, StudyRequest request) async {
    try {
      final cached = await readCache(key);
      if (cached != null) {
        final result = StudyResult.tryParse(cached, request.reference);
        if (result != null) {
          _memory[key] = result;
          return result;
        }
      }
    } catch (_) {
      // Cache must never break the study flow.
    }

    StudyResult? result;
    try {
      result = await backend.study(request);
    } catch (_) {
      result = null;
    }
    if (result == null) {
      final assembled = _assembleOffline(request);
      if (assembled != null) {
        _memory[key] = assembled;
        return assembled;
      }
      return StudyResult.unavailable(reference: request.reference);
    }

    _memory[key] = result;
    try {
      await writeCache(key, result.toJsonString());
    } catch (_) {
      // Persisting is optional.
    }
    return result;
  }

  /// Builds a deterministic, honest note from the bundled knowledge layers:
  /// the book intro (background → setting, flow → what the text says, key
  /// themes → meaning/background) plus validated cross-references. This is the
  /// "never-blank" guarantee: an offline reader always has the app's curated
  /// context for a canon passage, even when no note is banked and no AI is
  /// reachable. Assembled notes are served from memory but never persisted —
  /// the disk cache holds only real backend results, so this thin note can
  /// never shadow a richer note once the backend has one.
  StudyResult? _assembleOffline(StudyRequest request) {
    final reference = request.reference;
    final intro = intros?.introFor(reference.bookId);
    final refs = crossRefs?.crossReferencesFor(
          reference.bookId,
          reference.chapter,
          reference.startVerse,
        ) ??
        const <StudyCrossReference>[];

    final sections = <StudySection>[];
    if (intro != null) {
      if (intro.backgroundEn.trim().isNotEmpty) {
        sections.add(StudySection(
          kind: StudySectionKind.setting,
          en: intro.backgroundEn,
          am: intro.backgroundAm,
        ));
      }
      if (intro.flowEn.trim().isNotEmpty) {
        sections.add(StudySection(
          kind: StudySectionKind.whatTextSays,
          en: intro.flowEn,
          am: intro.flowAm,
        ));
      }
      if (intro.keyThemesEn.trim().isNotEmpty) {
        sections.add(StudySection(
          kind: StudySectionKind.meaningBackground,
          en: intro.keyThemesEn,
          am: intro.keyThemesAm,
        ));
      }
    }
    if (refs.isNotEmpty) {
      sections.add(StudySection(
        kind: StudySectionKind.biblicalConnections,
        references: refs,
      ));
    }
    if (sections.isEmpty) return null;

    return StudyResult(
      reference: reference,
      source: StudySource.knowledge,
      sections: sections,
      cachedAt: DateTime.now(),
      isAvailable: true,
    );
  }
}