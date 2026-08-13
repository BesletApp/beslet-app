import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/daily_verse_service.dart';
import '../services/scripture_service.dart';

/// The day's Thread verse with its text resolved verbatim from the bundled
/// Bible (1962 Amharic / WEB English) — the same source the reader displays.
/// This is the single place consumers read today's verse text from.
final todayDailyVerseProvider = FutureProvider<Scripture>((ref) {
  return DailyVerseService.today();
});

/// Any reference resolved from the bundled Bible (prayer postures,
/// notification pools). Emits a Scripture with empty text when the reference
/// cannot be verified, never fabricated wording.
final verseForReferenceProvider =
    FutureProvider.family<Scripture, String>((ref, reference) {
  return DailyVerseService.resolveReference(reference);
});
