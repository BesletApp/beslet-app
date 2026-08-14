import 'study_local_bank.dart';
import 'study_models.dart';

/// The study backend seam. Phase 1 ships only [LocalStudyBackend]; a Gemini
/// backend plugs in behind the same interface without the UI changing.
abstract class StudyBackend {
  Future<StudyResult?> study(StudyRequest request);
}

/// The curated offline backend: answers from the bundled bank, returns null
/// when the passage has no note (the service turns that into the quiet
/// "needs connection" fallback).
class LocalStudyBackend implements StudyBackend {
  final StudyLocalBank bank;

  const LocalStudyBackend(this.bank);

  @override
  Future<StudyResult?> study(StudyRequest request) async {
    final reference = request.reference;
    final entry = bank.entryFor(
      reference.bookId,
      reference.chapter,
      reference.startVerse,
    );
    if (entry == null) return null;
    return StudyResult(
      reference: reference,
      source: StudySource.localBank,
      sections: entry.sections,
      anchor: entry.anchor,
      cachedAt: DateTime.now(),
      isAvailable: true,
    );
  }
}
