import 'dart:developer' as developer;

import 'voice_journal_backend.dart';
import 'voice_journal_diagnostics.dart';
import 'voice_journal_models.dart';

/// Orchestrates a voice-journal lookup: in-memory cache first, the single-flight
/// dedup for identical transcripts, then the persistent disk cache, then the AI
/// backend.
///
/// "Voice Journal" is an on-demand AI pass with no offline substitute — it is a
/// genuinely separate AI request, never a masked fallback. So the reliability
/// contract is deliberately strict about honesty, not about availability:
///  - real organized journals are memoized and persisted, keyed by the exact
///    transcript, so re-organizing the same dictation (or retrying after a
///    failure with unchanged text) never re-runs the backend or re-bills;
///  - unavailable/flagged results are **never** memoized or persisted:
///    re-opening re-attempts AI and always re-surfaces the reason;
///  - a failed request always carries the concrete reason the sheet must
///    explain — never a silent blank, never a fabricated journal.
class VoiceJournalService {
  final VoiceJournalBackend backend;
  final Future<String?> Function(String key) readCache;
  final Future<void> Function(String key, String value) writeCache;

  /// Optional removal hook for [refresh]'s `bypassDisk` path.
  final Future<void> Function(String key)? removeCache;

  /// The connectivity gate. An empty probe result is treated as unknown (the
  /// transport classifies the real outcome), matching the Study/Delve layers.
  final Future<bool> Function() isOnline;

  /// Whether an AI organize may run now: the reader has their own key (never
  /// counted) or the free daily voice-journal allowance remains.
  final Future<bool> Function() mayOrganize;

  /// Records a bundled-key use after a successful run.
  final Future<void> Function() recordVoiceJournalUse;

  /// The single retry delay for transient AI failures.
  final Duration retryDelay;

  /// In-memory results: a repeated organize of identical text within a session
  /// is served instantly. Holds only real journals.
  final Map<String, VoiceJournalResult> _memory = {};

  /// Single-flight dedup: concurrent requests for the same key share one
  /// future.
  final Map<String, Future<VoiceJournalResult>> _inflight = {};

  VoiceJournalService({
    required this.backend,
    required this.readCache,
    required this.writeCache,
    this.removeCache,
    required this.isOnline,
    required this.mayOrganize,
    required this.recordVoiceJournalUse,
    this.retryDelay = const Duration(milliseconds: 1500),
  });

  /// The key includes the prompt version, the language, and a stable hash of
  /// the exact transcript, so an organized journal generated under an older
  /// prompt, a different reader language, or different text is never served
  /// from cache.
  String cacheKeyFor(VoiceJournalRequest request) =>
      'vj_v${voiceJournalPromptVersion}_${request.isAmharic ? 'am' : 'en'}_'
      '${voiceJournalTranscriptKey(request.transcript)}';

  Future<VoiceJournalResult> organize(VoiceJournalRequest request) async {
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
  /// fresh resolution happens — used after the reader adds their own Gemini
  /// key so organizing continues in place. Set [bypassDisk] to also drop any
  /// stale journal persisted for this transcript.
  Future<VoiceJournalResult> refresh(VoiceJournalRequest request,
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
    return organize(request);
  }

  Future<VoiceJournalResult> _resolve(
      String key, VoiceJournalRequest request) async {
    try {
      final cached = await readCache(key);
      if (cached != null) {
        final result = VoiceJournalResult.tryParse(cached);
        if (result != null && result.isAvailable) {
          _memory[key] = result;
          VoiceJournalDiagnostics.instance.recordCacheHit(true);
          developer.log('voice_journal: disk cache hit', name: 'voice_journal');
          return result;
        }
      }
    } catch (_) {
      // Cache must never break the organize flow.
    }

    if (request.transcript.length > voiceJournalMaxTranscriptChars) {
      // Defensive: the service should be sent a capped transcript; if not, fail
      // honestly rather than subsidize a runaway bill.
      developer.log('voice_journal: transcript over cap', name: 'voice_journal');
      return VoiceJournalResult.unavailable(
          unavailability: VoiceJournalUnavailability.tooLong);
    }

    if (!await isOnline()) {
      developer.log('voice_journal: offline, no network interface',
          name: 'voice_journal');
      VoiceJournalDiagnostics.instance.record(
          failureReason: VoiceJournalUnavailability.offline);
      return VoiceJournalResult.unavailable(
          unavailability: VoiceJournalUnavailability.offline);
    }

    if (!await mayOrganize()) {
      developer.log('voice_journal: free daily cap reached',
          name: 'voice_journal');
      VoiceJournalDiagnostics.instance.record(
          failureReason: VoiceJournalUnavailability.capped);
      return VoiceJournalResult.voiceJournalLimit();
    }

    var lastReason = VoiceJournalUnavailability.none;
    for (var attemptNo = 0; attemptNo < 2; attemptNo++) {
      developer.log('voice_journal: AI attempt ${attemptNo + 1}/2',
          name: 'voice_journal');
      final attempt = await _safeBackend(request);
      final result = attempt.result;
      if (result != null) {
        developer.log('voice_journal: AI organized journal', name: 'voice_journal');
        VoiceJournalDiagnostics.instance.record(failureReason: null);
        _memory[key] = result;
        try {
          await writeCache(key, result.toJsonString());
        } catch (_) {
          // Persisting is optional.
        }
        await recordVoiceJournalUse();
        return result;
      }
      lastReason = attempt.unavailability;
      VoiceJournalDiagnostics.instance.record(failureReason: lastReason);
      if (attemptNo == 0 && _retryable(lastReason)) {
        developer.log('voice_journal: AI ${lastReason.name} — retrying once',
            name: 'voice_journal');
        await Future.delayed(retryDelay);
        continue;
      }
      break;
    }

    developer.log('voice_journal: AI unavailable (${lastReason.name})',
        name: 'voice_journal');
    return _resolveUnavailable(lastReason);
  }

  Future<VoiceJournalAttempt> _safeBackend(VoiceJournalRequest request) async {
    try {
      return await backend.organize(request);
    } catch (e) {
      developer.log('voice_journal: AI reached exception: $e',
          name: 'voice_journal');
      return const VoiceJournalAttempt.unavailable(
          VoiceJournalUnavailability.server);
    }
  }

  static bool _retryable(VoiceJournalUnavailability reason) =>
      reason == VoiceJournalUnavailability.offline ||
      reason == VoiceJournalUnavailability.timeout ||
      reason == VoiceJournalUnavailability.rateLimited ||
      reason == VoiceJournalUnavailability.server;

  static VoiceJournalResult _resolveUnavailable(
          VoiceJournalUnavailability reason) =>
      VoiceJournalResult.unavailable(unavailability: reason);
}