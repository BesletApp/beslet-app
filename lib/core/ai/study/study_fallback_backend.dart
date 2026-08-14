import 'dart:developer' as developer;

import 'study_backend.dart';
import 'study_models.dart';

/// Composes the smarter chain: curated offline bank first (free, unlimited,
/// canon-verified), then — only for passages the bank does not cover, when
/// online, and within the daily AI cap — the model. A banked passage never
/// touches the network.
///
/// The outcomes are deliberately distinguishable so a failed AI request can
/// never silently stand in for a generated one:
///  - offline (no network)        -> null (the service assembles the offline note)
///  - free daily AI cap reached   -> [StudyResult.aiLimit] (a clear, guided prompt)
///  - AI success                  -> the model's note
///  - AI failure (quota/auth/timeout/validator) -> null + a log (offline note shown)
class StudyFallbackBackend implements StudyBackend {
  final LocalStudyBackend local;
  final StudyBackend? ai;
  final Future<bool> Function() isOnline;
  final Future<bool> Function() mayUseAi;
  final Future<void> Function() recordAiUse;

  StudyFallbackBackend({
    required this.local,
    required this.ai,
    required this.isOnline,
    required this.mayUseAi,
    required this.recordAiUse,
  });

  @override
  Future<StudyResult?> study(StudyRequest request) async {
    try {
      final curated = await local.study(request);
      if (curated != null) {
        developer.log('study: curated bank', name: 'study');
        return curated;
      }
    } catch (_) {
      // A corrupted bank must never block reading Scripture.
    }

    final aiBackend = ai;
    if (aiBackend == null) return null;
    try {
      final online = await isOnline();
      if (!online) {
        developer.log('study: offline, no network', name: 'study');
        return null;
      }

      if (!await mayUseAi()) {
        developer.log('study: free daily AI cap reached', name: 'study');
        return StudyResult.aiLimit(reference: request.reference);
      }

      final result = await aiBackend.study(request);
      if (result != null) {
        developer.log('study: AI generated note', name: 'study');
        await recordAiUse();
      } else {
        developer.log('study: AI call failed/empty', name: 'study');
      }
      return result;
    } catch (e) {
      developer.log('study: AI reached exception: $e', name: 'study');
      return null;
    }
  }
}