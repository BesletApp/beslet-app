import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bible_journey_service.dart';
import '../services/bible_text_service.dart';
import '../services/bible_seed_service.dart';
import '../services/scripture_service.dart';

/// True once the bundled bilingual Bible has been seeded into the text cache
/// on first launch, making the whole canon readable offline.
final bibleSeededProvider = FutureProvider<bool>((ref) async {
  return BibleSeedService.isSeeded();
});

class ScriptureVerse {
  final int number;
  final String text;
  const ScriptureVerse({required this.number, required this.text});
}

class ScriptureChapter {
  final String bookId;
  final int chapter;
  final bool isAmharic;
  final List<ScriptureVerse> verses;

  const ScriptureChapter({
    required this.bookId,
    required this.chapter,
    required this.isAmharic,
    required this.verses,
  });

  bool get isEmpty => verses.isEmpty;
  int get totalVerses => verses.length;
}

final scriptureProvider = FutureProvider.family<ScriptureChapter?, ({String bookId, int chapter, bool isAmharic})>(
  (ref, params) async {
    final verses = await BibleTextService.fetchChapter(
      params.bookId,
      params.chapter,
      isAmharic: params.isAmharic,
    );
    if (verses.isEmpty) return null;
    return ScriptureChapter(
      bookId: params.bookId,
      chapter: params.chapter,
      isAmharic: params.isAmharic,
      verses: verses.map((v) => ScriptureVerse(number: v.verse, text: v.text)).toList(),
    );
  },
);

/// Today's suggested reading: the NT plan chapter, or the Day's Thread verse
/// as a graceful fallback. Shown on Home and the Bible screen so the journey
/// always has a gentle "next".
class TodayReadingPlan {
  final String bookId;
  final int chapter;
  final String labelEn;
  final String labelAm;

  const TodayReadingPlan({
    required this.bookId,
    required this.chapter,
    required this.labelEn,
    required this.labelAm,
  });
}

final todayReadingPlanProvider = Provider<TodayReadingPlan>((ref) {
  final plan = ScriptureService.ntPlanFor(DateTime.now());
  if (plan != null) {
    final book = plan.book;
    final label = '${book.nameEn} ${plan.chapter}';
    return TodayReadingPlan(
      bookId: plan.bookId,
      chapter: plan.chapter,
      labelEn: label,
      labelAm: '${book.nameAm} ${plan.chapter}',
    );
  }
  final verse = ScriptureService.threadVerseFor(DateTime.now());
  final parsed = ScriptureService.parseReference(verse.reference);
  if (parsed != null) {
    return TodayReadingPlan(
      bookId: parsed.bookId,
      chapter: parsed.chapter,
      labelEn: verse.reference,
      labelAm: ScriptureService.amharicReference(verse.reference),
    );
  }
  return const TodayReadingPlan(
    bookId: 'genesis',
    chapter: 1,
    labelEn: 'Genesis 1',
    labelAm: 'ዘፍጥረት 1',
  );
});

/// State provider for the active Bible reading journey.
/// Loaded at startup via BibleJourneyService.initialize().
final bibleJourneyProvider = StateProvider<BibleJourneyPlan?>((ref) => null);

/// Today's suggested reading: the active journey's assigned chapter(s), or the
/// NT plan chapter, or the Day's Thread verse as a graceful fallback.
/// Shown on Home and the Bible screen so the journey always has a gentle "next".
final todayBiblePlanProvider = Provider<TodayReadingPlan>((ref) {
  final journey = ref.watch(bibleJourneyProvider);
  if (journey != null && !journey.paused && !journey.completed) {
    final chapters = ScriptureService.generatePlanChapters(journey.type, journey.bookId);
    final assignment = ScriptureService.getTodayAssignment(chapters, journey.pace, journey.currentDayIndex);
    if (assignment != null) {
      final labelEn = assignment.startChapter == assignment.endChapter
          ? '${assignment.book.nameEn} ${assignment.startChapter}'
          : '${assignment.book.nameEn} ${assignment.startChapter}–${assignment.endChapter}';
      final labelAm = assignment.startChapter == assignment.endChapter
          ? '${assignment.book.nameAm} ${assignment.startChapter}'
          : '${assignment.book.nameAm} ${assignment.startChapter}–${assignment.endChapter}';
      return TodayReadingPlan(
        bookId: assignment.bookId,
        chapter: assignment.startChapter,
        labelEn: labelEn,
        labelAm: labelAm,
      );
    }
  }
  // Fallback to existing behavior: NT plan -> thread verse -> Genesis 1
  final plan = ScriptureService.ntPlanFor(DateTime.now());
  if (plan != null) {
    final book = plan.book;
    final label = '${book.nameEn} ${plan.chapter}';
    return TodayReadingPlan(
      bookId: plan.bookId,
      chapter: plan.chapter,
      labelEn: label,
      labelAm: '${book.nameAm} ${plan.chapter}',
    );
  }
  final verse = ScriptureService.threadVerseFor(DateTime.now());
  final parsed = ScriptureService.parseReference(verse.reference);
  if (parsed != null) {
    return TodayReadingPlan(
      bookId: parsed.bookId,
      chapter: parsed.chapter,
      labelEn: verse.reference,
      labelAm: ScriptureService.amharicReference(verse.reference),
    );
  }
  return const TodayReadingPlan(
    bookId: 'genesis',
    chapter: 1,
    labelEn: 'Genesis 1',
    labelAm: 'ዘፍጥረት 1',
  );
});
