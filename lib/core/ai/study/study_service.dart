import 'study_backend.dart';
import 'study_models.dart';

/// Orchestrates a study lookup: cache first, then the backend, then the quiet
/// unavailable fallback. Every step is non-blocking and can never raise to the
/// caller.
class StudyService {
  final StudyBackend backend;
  final Future<String?> Function(String key) readCache;
  final Future<void> Function(String key, String value) writeCache;

  const StudyService({
    required this.backend,
    required this.readCache,
    required this.writeCache,
  });

  /// The key includes the prompt version so a note generated under an older
  /// prompt or schema is never served from cache.
  String cacheKeyFor(StudyRequest request) =>
      'study_v${studyPromptVersion}_${request.reference.cacheKey}_${request.isAmharic ? 'am' : 'en'}';

  Future<StudyResult> study(StudyRequest request) async {
    final key = cacheKeyFor(request);

    try {
      final cached = await readCache(key);
      if (cached != null) {
        final result = StudyResult.tryParse(cached, request.reference);
        if (result != null) return result;
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
      return StudyResult.unavailable(reference: request.reference);
    }

    try {
      await writeCache(key, result.toJsonString());
    } catch (_) {
      // Persisting is optional.
    }
    return result;
  }
}
