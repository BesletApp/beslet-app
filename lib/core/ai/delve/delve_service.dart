import 'dart:developer' as developer;

import 'delve_backend.dart';
import 'delve_diagnostics.dart';
import 'delve_models.dart';

/// Orchestrates a deep-study lookup: in-memory cache first, then the
/// single-flight dedup, then the persistent disk cache, then the AI backend.
///
/// "Delve Deeper" is an on-demand second pass with no offline substitute — it
/// is a genuinely separate AI request, never a masked fallback. So the
/// reliability contract is deliberately strict about honesty, not about
/// availability:
///  - real deep notes are memoized and persisted, so re-opening the same
///    passage (or scrolling to the same passage) reuses the cached result;
///  - unavailable/flagged results are **never** memoized or persisted:
///    re-opening re-attempts AI and always re-surfaces the reason;
///  - a failed request always carries the concrete reason the panel must
///    explain — never a silent blank, never a fabricated note.
class DelveService {
  final DelveBackend backend;
  final Future<String?> Function(String key) readCache;
  final Future<void> Function(String key, String value) writeCache;

  /// Optional removal hook for [refresh]'s `bypassDisk` path.
  final Future<void> Function(String key)? removeCache;

  /// The connectivity gate. An empty probe result is treated as unknown (the
  /// transport classifies the real outcome), matching the Study layer.
  final Future<bool> Function() isOnline;

  /// Whether an AI deep study may run now: the reader has their own key (never
  /// counted) or the free daily deep-study allowance remains.
  final Future<bool> Function() mayDelve;

  /// Records a bundled-key use after a successful run.
  final Future<void> Function() recordDelveUse;

  /// The single retry delay for transient AI failures.
  final Duration retryDelay;

  /// In-memory results: a repeated instanceof a key within a session is served
  /// instantly. Holds only real notes.
  final Map<String, DelveResult> _memory = {};

  /// Single-flight dedup: concurrent requests for the same key share one
  /// future.
  final Map<String, Future<DelveResult>> _inflight = {};

  DelveService({
    required this.backend,
    required this.readCache,
    required this.writeCache,
    this.removeCache,
    required this.isOnline,
    required this.mayDelve,
    required this.recordDelveUse,
    this.retryDelay = const Duration(milliseconds: 1500),
  });

  /// The key includes the prompt version and the language so a deep note
  /// generated under an older prompt or a different reader language is never
  /// served from cache. Delve is a fixed-depth pass — it carries no depth in
  /// the key.
  String cacheKeyFor(DelveRequest request) =>
      'delve_v${delvePromptVersion}_${request.reference.cacheKey}_${request.isAmharic ? 'am' : 'en'}';

  Future<DelveResult> delve(DelveRequest request) async {
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
  /// key so the deep study continues in place. Set [bypassDisk] to also drop
  /// any stale note persisted for this passage.
  Future<DelveResult> refresh(DelveRequest request,
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
    return delve(request);
  }

  Future<DelveResult> _resolve(String key, DelveRequest request) async {
    try {
      final cached = await readCache(key);
      if (cached != null) {
        final result = DelveResult.tryParse(cached, request.reference);
        if (result != null && result.isAvailable) {
          _memory[key] = result;
          DelveDiagnostics.instance.recordCacheHit(true);
          developer.log('delve: disk cache hit', name: 'delve');
          return result;
        }
      }
    } catch (_) {
      // Cache must never break the deep-study flow.
    }

    if (!await isOnline()) {
      developer.log('delve: offline, no network interface', name: 'delve');
      DelveDiagnostics.instance.record(
          failureReason: DelveUnavailability.offline);
      return _resolveUnavailable(request, DelveUnavailability.offline);
    }

    if (!await mayDelve()) {
      developer.log('delve: free daily deep-study cap reached', name: 'delve');
      DelveDiagnostics.instance.record(
          failureReason: DelveUnavailability.capped);
      return DelveResult.delveLimit(reference: request.reference);
    }

    var lastReason = DelveUnavailability.none;
    for (var attemptNo = 0; attemptNo < 2; attemptNo++) {
      developer.log('delve: AI attempt ${attemptNo + 1}/2', name: 'delve');
      final attempt = await _safeBackend(request);
      final result = attempt.result;
      if (result != null) {
        developer.log('delve: AI generated deep note', name: 'delve');
        DelveDiagnostics.instance.record(failureReason: null);
        _memory[key] = result;
        try {
          await writeCache(key, result.toJsonString());
        } catch (_) {
          // Persisting is optional.
        }
        await recordDelveUse();
        return result;
      }
      lastReason = attempt.unavailability;
      DelveDiagnostics.instance.record(failureReason: lastReason);
      if (attemptNo == 0 && _retryable(lastReason)) {
        developer.log('delve: AI ${lastReason.name} — retrying once',
            name: 'delve');
        await Future.delayed(retryDelay);
        continue;
      }
      break;
    }

    developer.log('delve: AI unavailable (${lastReason.name})', name: 'delve');
    return _resolveUnavailable(request, lastReason);
  }

  Future<DelveAttempt> _safeBackend(DelveRequest request) async {
    try {
      return await backend.delve(request);
    } catch (e) {
      developer.log('delve: AI reached exception: $e', name: 'delve');
      return const DelveAttempt.unavailable(DelveUnavailability.server);
    }
  }

  static bool _retryable(DelveUnavailability reason) =>
      reason == DelveUnavailability.offline ||
      reason == DelveUnavailability.timeout ||
      reason == DelveUnavailability.rateLimited ||
      reason == DelveUnavailability.server;

  static DelveResult _resolveUnavailable(
      DelveRequest request, DelveUnavailability reason) {
    return DelveResult.unavailable(reference: request.reference)
        .copyWith(unavailability: reason);
  }
}