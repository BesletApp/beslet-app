import 'package:flutter/foundation.dart';

import 'bundled_bible_reader.dart';
import 'scripture_service.dart';

/// Resolves the day's verse text entirely from the bundled Bible — the same
/// 1962 Amharic / WEB English the reader shows — while preserving The Day's
/// Thread (one fixed reference per calendar day).
///
/// Validation layer: a reference is only delivered when every requested verse
/// exists and carries non-empty text in BOTH languages. On failure the failure
/// is logged and the resolver steps to the next reference in the canon (up to
/// a full loop), so a gap in the bundle can never surface a broken or
/// paraphrased verse.
class DailyVerseService {
  DailyVerseService._();

  /// The verse shown today: resolved text, verified, from the bundled Bible.
  static Future<Scripture> today() => resolveDay(DateTime.now());

  /// Resolves the verse for a calendar day using the deterministic thread.
  static Future<Scripture> resolveDay(DateTime day) async {
    final canonDay = ScriptureService.threadVerseFor(day);
    for (var i = 0; i < ScriptureService.verses.length; i++) {
      final candidate =
          ScriptureService.threadVerseFor(day.add(Duration(days: i)));
      final resolved = await _resolve(candidate);
      if (resolved != null) return resolved;
    }
    // Every reference failed verification; never fabricate text. Return the
    // canon reference with an empty body so the caller can fall back silently.
    return Scripture(reference: canonDay.reference, text: '');
  }

  /// Resolves an arbitrary reference (prayer postures, notification pools).
  static Future<Scripture> resolveReference(String reference) async {
    final candidate = _canonByReference(reference) ??
        Scripture(reference: reference, text: '');
    final resolved = await _resolve(candidate);
    if (resolved != null) return resolved;
    return Scripture(reference: reference, text: '');
  }

  static Scripture? _canonByReference(String reference) {
    for (final s in ScriptureService.verses) {
      if (s.reference == reference) return s;
    }
    return null;
  }

  static Future<Scripture?> _resolve(Scripture candidate) async {
    final range = ScriptureService.referenceRange(candidate.reference);
    if (range == null) {
      _log('unparsable reference ${candidate.reference}');
      return null;
    }
    final en = <String>[];
    final am = <String>[];
    for (final verseNo in range.verses) {
      final enText = await BundledBibleReader.instance.textFor(
        range.bookId,
        range.chapter,
        verseNo,
        isAmharic: false,
      );
      final amText = await BundledBibleReader.instance.textFor(
        range.bookId,
        range.chapter,
        verseNo,
        isAmharic: true,
      );
      if (enText == null ||
          amText == null ||
          enText.trim().isEmpty ||
          amText.trim().isEmpty) {
        _log('unverified verse ${range.bookId} ${range.chapter}:$verseNo '
            '(${candidate.reference}) — selecting another reference');
        return null;
      }
      en.add(enText.trim());
      am.add(amText.trim());
    }
    return Scripture(
      reference: candidate.reference,
      text: en.join(' '),
      textAm: am.join(' '),
    );
  }

  static void _log(String message) {
    debugPrint('[DailyVerse] $message');
  }
}