import 'dart:async';
import 'dart:developer' as developer;

import 'study_backend.dart';
import 'study_diagnostics.dart';
import 'study_models.dart';

/// Composes the chain the reader asked for — AI first, offline only as the
/// honest fallback:
///
///   1. AI model — every passage, when online and within the AI allowance. A
///      reader's own key bypasses the app's free daily cap entirely.
///   2. Transient AI failures (offline/timeout/rate-limit/server) get one retry
///      before the chain gives up.
///   3. Only when AI cannot answer does the curated offline bank serve — and it
///      carries the *reason* AI was unavailable so the panel can explain.
///   4. Still nothing → the reason alone (the service assembles the book intro).
///
/// Nothing here is silent: a failed AI request is never returned as a plain
/// note. The outcomes are deliberately distinguishable:
///  - no network interface     -> unavailable(offline)
///  - free daily AI cap reached -> the aiLimit sentinel (a clear, guided prompt)
///  - AI success               -> the model's note (quota counted when app key)
///  - AI failure               -> offline note/bank carrying the failure reason
class StudyFallbackBackend implements StudyBackend {
  final LocalStudyBackend local;
  final StudyBackend? ai;
  final Future<bool> Function() isOnline;
  final Future<bool> Function() mayUseAi;
  final Future<void> Function() recordAiUse;
  final Duration retryDelay;

  StudyFallbackBackend({
    required this.local,
    required this.ai,
    required this.isOnline,
    required this.mayUseAi,
    required this.recordAiUse,
    this.retryDelay = const Duration(milliseconds: 1500),
  });

  /// Whether a failure is worth a single retry — transient conditions that can
  /// clear in a second, never policy/content errors.
  static bool _retryable(StudyUnavailability reason) =>
      reason == StudyUnavailability.offline ||
      reason == StudyUnavailability.timeout ||
      reason == StudyUnavailability.rateLimited ||
      reason == StudyUnavailability.server;

  @override
  Future<StudyAttempt> study(StudyRequest request) async {
    final aiBackend = ai;
    if (aiBackend == null) {
      // No AI configured (tests/offline build) — the bank is the answer.
      return _bankFallback(request);
    }

    final online = await isOnline();
    if (!online) {
      developer.log('study: offline, no network interface', name: 'study');
      StudyDiagnostics.instance.record(
          failureReason: StudyUnavailability.offline);
      return const StudyAttempt.unavailable(StudyUnavailability.offline);
    }

    if (!await mayUseAi()) {
      developer.log('study: free daily AI cap reached', name: 'study');
      StudyDiagnostics.instance.record(
          failureReason: StudyUnavailability.capped);
      return StudyAttempt.available(
          StudyResult.aiLimit(reference: request.reference));
    }

    StudyUnavailability lastReason = StudyUnavailability.none;
    for (var attemptNo = 0; attemptNo < 2; attemptNo++) {
      final attempt = await _safeAi(request, aiBackend);
      final result = attempt.result;
      if (result != null) {
        developer.log('study: AI generated note', name: 'study');
        StudyDiagnostics.instance.record(failureReason: null);
        await recordAiUse();
        return StudyAttempt.available(result);
      }
      lastReason = attempt.unavailability;
      StudyDiagnostics.instance.record(failureReason: lastReason);
      if (attemptNo == 0 && _retryable(lastReason)) {
        developer.log('study: AI ${lastReason.name} — retrying once',
            name: 'study');
        await Future.delayed(retryDelay);
        continue;
      }
      break;
    }

    developer.log('study: AI unavailable (${lastReason.name}) -> offline note',
        name: 'study');
    return _bankFallback(request, reason: lastReason);
  }

  Future<StudyAttempt> _safeAi(
      StudyRequest request, StudyBackend aiBackend) async {
    try {
      return await aiBackend.study(request);
    } catch (e) {
      developer.log('study: AI reached exception: $e', name: 'study');
      return const StudyAttempt.unavailable(StudyUnavailability.server);
    }
  }

  /// The curated bank — only ever reached after AI has failed. The banked note
  /// keeps the failure [reason] attached so the panel can still explain why AI
  /// wasn't used (never a silent swap).
  Future<StudyAttempt> _bankFallback(
    StudyRequest request, {
    StudyUnavailability reason = StudyUnavailability.none,
  }) async {
    try {
      final curated = await local.study(request);
      final note = curated.result;
      if (note != null) {
        final withReason = reason == StudyUnavailability.none
            ? note
            : note.copyWith(unavailability: reason);
        return StudyAttempt.available(withReason);
      }
    } catch (_) {
      // A corrupted bank must never block reading Scripture.
    }
    if (reason == StudyUnavailability.none) {
      return const StudyAttempt.nothing();
    }
    return StudyAttempt.unavailable(reason);
  }
}
