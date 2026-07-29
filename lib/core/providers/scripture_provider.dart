import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/bible_text_service.dart';

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
