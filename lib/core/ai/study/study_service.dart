import 'dart:developer' as developer;

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
///
/// Reliability contract:
///  - Only *real* notes (AI or curated bank, with no unavailability reason) are
///    memoized or persisted, so a repeat open of the same passage loads
///    instantly — your choice to keep same-passage caching.
///  - Unavailable/flagged results are **never** memoized or persisted: re-opening
///    the passage re-attempts AI and always re-surfaces the reason. A failure
///    can never poison the session the way the old code did.
class StudyService {
  final StudyBackend backend;
  final Future<String?> Function(String key) readCache;
  final Future<void> Function(String key, String value) writeCache;

  /// Optional removal hook for [refresh]'s `bypassDisk` path (clearing a stale
  /// note so a fresh user-key run is never shadowed by old content).
  final Future<void> Function(String key)? removeCache;

  /// Optional bundled knowledge layers used for the never-blank offline
  /// assembly. When absent, an empty backend result becomes the quiet
  /// "unavailable" note.
  final StudyIntroLibrary? intros;
  final StudyCrossRefIndex? crossRefs;

  /// In-memory results: a repeated open within a session is served instantly
  /// and never re-runs the backend or the disk cache. Holds only real notes.
  final Map<String, StudyResult> _memory = {};

  /// Single-flight dedup: concurrent requests for the same key share one
  /// future, so the backend is called at most once per key at a time.
  final Map<String, Future<StudyResult>> _inflight = {};

  StudyService({
    required this.backend,
    required this.readCache,
    required this.writeCache,
    this.removeCache,
    this.intros,
    this.crossRefs,
  });

  /// The key includes the prompt version and the depth so a note generated
  /// under an older prompt, schema, or depth is never served from cache.
  String cacheKeyFor(StudyRequest request) =>
      'study_v${studyPromptVersion}_${request.reference.cacheKey}_${request.isAmharic ? 'am' : 'en'}_${request.depth.name}';

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

  /// Re-runs a request bypassing the in-memory cache and in-flight dedup so a
  /// fresh resolution happens. Used after the reader adds their own Gemini key
  /// so a study continues in place — no reopened Bible, no restart. Set
  /// [bypassDisk] to also drop any stale note persisted for this passage, so a
  /// fresh user-key run can never be shadowed by old disk content.
  Future<StudyResult> refresh(StudyRequest request,
      {bool bypassDisk = false}) async {
    final key = cacheKeyFor(request);
    _memory.remove(key);
    _inflight.remove(key);
    if (bypassDisk) {
      try {
        await removeCache?.call(key);
      } catch (_) {
        // Clearing is optional.
      }
    }
    return study(request);
  }

  Future<StudyResult> _resolve(String key, StudyRequest request) async {
    try {
      final cached = await readCache(key);
      if (cached != null) {
        final result = StudyResult.tryParse(cached, request.reference);
        if (result != null && result.isAvailable) {
          _memory[key] = result;
          developer.log('study: disk cache hit', name: 'study');
          return result;
        }
      }
    } catch (_) {
      // Cache must never break the study flow.
    }

    StudyAttempt attempt;
    try {
      attempt = await backend.study(request);
    } catch (e) {
      developer.log('study: backend threw: $e', name: 'study');
      attempt = const StudyAttempt.unavailable(StudyUnavailability.server);
    }

    final result = attempt.result;

    // The app's free daily AI allowance is exhausted: surface the guided flow
    // (offline note marked limitReached, or the prompt alone) rather than
    // silently presenting the offline assembly as a fresh AI study. Never
    // memoized — re-opening re-checks the gate so a new day is respected.
    if (result != null && result.source == StudySource.limitReached) {
      final assembled = _assembleOffline(request);
      if (assembled != null) {
        final flagged = assembled.copyWith(
          limitReached: true,
          unavailability: StudyUnavailability.capped,
        );
        developer.log('study: limited -> offline note flagged', name: 'study');
        return flagged;
      }
      developer.log('study: limited -> no offline note', name: 'study');
      return result;
    }

    if (result != null) {
      // A real note. Memoize and persist only when it carries no attached
      // failure reason (a bank note served after AI failed must not be cached
      // as if it were a fresh answer).
      if (result.unavailability == StudyUnavailability.none) {
        _memory[key] = result;
        if (result.isAvailable) {
          try {
            await writeCache(key, result.toJsonString());
          } catch (_) {
            // Persisting is optional.
          }
        }
      }
      developer.log('study: backend result (${result.source.name})',
          name: 'study');
      return result;
    }

    // No AI/bank note: assemble the deterministic offline note, attach the
    // reason AI was unavailable, and do NOT memoize — so a re-open re-attempts
    // AI instead of being served the same silent offline assembly forever.
    final reason = attempt.unavailability;
    final assembled = _assembleOffline(request);
    if (assembled != null) {
      final flagged = reason == StudyUnavailability.none
          ? assembled
          : assembled.copyWith(unavailability: reason);
      developer.log('study: offline assembly (${reason.name})', name: 'study');
      return flagged;
    }
    developer.log('study: unavailable (${reason.name})', name: 'study');
    return StudyResult.unavailable(reference: request.reference)
        .copyWith(unavailability: reason);
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
          kind: StudySectionKind.passageOverview,
          en: intro.backgroundEn,
          am: intro.backgroundAm,
        ));
      }
      if (intro.flowEn.trim().isNotEmpty) {
        sections.add(StudySection(
          kind: StudySectionKind.literaryContext,
          en: intro.flowEn,
          am: intro.flowAm,
        ));
      }
      if (intro.keyThemesEn.trim().isNotEmpty) {
        sections.add(StudySection(
          kind: StudySectionKind.originalLanguage,
          en: intro.keyThemesEn,
          am: intro.keyThemesAm,
        ));
      }
    }
    if (refs.isNotEmpty) {
      sections.add(StudySection(
        kind: StudySectionKind.scriptureInterconnections,
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
