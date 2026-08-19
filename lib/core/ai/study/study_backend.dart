import 'study_local_bank.dart';
import 'study_models.dart';

/// The study backend seam. A Gemini backend plugs in behind the same interface
/// without the UI changing. Every attempt returns a [StudyAttempt] — a real
/// note, an explicit [StudyAttempt.nothing] for "this layer has nothing", or a
/// concrete unavailability reason — so a failure can never silently masquerade
/// as an answer.
abstract class StudyBackend {
  Future<StudyAttempt> study(StudyRequest request);
}

/// The curated offline backend: answers from the bundled bank, returns
/// [StudyAttempt.nothing] when the passage has no note (the composer moves on
/// to the next layer of its chain).
class LocalStudyBackend implements StudyBackend {
  final StudyLocalBank bank;

  const LocalStudyBackend(this.bank);

  @override
  Future<StudyAttempt> study(StudyRequest request) async {
    final reference = request.reference;
    final entry = bank.entryFor(
      reference.bookId,
      reference.chapter,
      reference.startVerse,
    );
    if (entry == null) return const StudyAttempt.nothing();
    return StudyAttempt.available(StudyResult(
      reference: reference,
      source: StudySource.localBank,
      sections: entry.sections,
      anchor: entry.anchor,
      cachedAt: DateTime.now(),
      isAvailable: true,
    ));
  }
}
