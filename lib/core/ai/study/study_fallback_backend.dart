import 'study_backend.dart';
import 'study_models.dart';

/// Composes the smarter chain: curated offline bank first (free, unlimited,
/// canon-verified), then — only for passages the bank does not cover, when
/// online, and within the daily AI cap — the model. A banked passage never
/// touches the network. Any failure anywhere yields null so the service falls
/// back to the quiet "unavailable" note.
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
      if (curated != null) return curated;
    } catch (_) {
      // A corrupted bank must never block reading Scripture.
    }

    final aiBackend = ai;
    if (aiBackend == null) return null;
    try {
      if (!await isOnline()) return null;
      if (!await mayUseAi()) return null;
      final result = await aiBackend.study(request);
      if (result != null) {
        await recordAiUse();
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}