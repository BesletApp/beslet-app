import 'voice_journal_models.dart';
import 'voice_journal_prompt.dart';

/// Turns a raw Gemini organized-journal payload into a validated
/// [VoiceJournalResult], or null.
///
/// This is the honesty gate between the model and the reader, and it enforces
/// the "editor, not author" contract mechanically where it can:
///  - a banned phrase anywhere (directives, preaching, revelation claims, hype)
///    rejects the *entire* journal — organized words that tell the reader what
///    God wants must never appear at all;
///  - type/script checks and hard length caps are applied per section — a
///    bloated or wrong-language section is dropped while the honest rest of the
///    journal survives;
///  - every grouped section must be drawn from the reader's words: a
///    token-overlap guard drops any section whose vocabulary is not
///    substantially the transcript's (the model authored, not edited);
///  - the "one sentence to remember" must be a near-verbatim excerpt of the
///    transcript — a manufactured quote is dropped;
///  - the organized journal must not dwarf the transcript — an editor never
///    inflates the reader's words.
///
/// A rejected (null) result becomes the gracefully explained "unavailable"
/// state; an organized journal the validator cannot stand behind is never shown.
class VoiceJournalValidator {
  const VoiceJournalValidator();

  VoiceJournalResult? validate({
    required Map<String, dynamic> raw,
    required VoiceJournalRequest request,
  }) {
    final isAm = request.isAmharic;
    final transcript = request.transcript.trim();
    if (transcript.isEmpty) return null;

    final transcriptTokens = _tokens(transcript);

    final allTexts = _collectAllTexts(raw);
    for (final text in allTexts) {
      if (_hasBannedPhrase(text, isAm)) return null;
    }

    final sectionCeiling =
        VoiceJournalLengthBudget.sectionCeilingFor(transcriptTokens.length);
    final overallCeiling =
        VoiceJournalLengthBudget.overallCeilingFor(transcriptTokens.length);

    final sections = <VoiceNoteSection>[];
    for (final kind in VoiceNoteSectionKind.values) {
      final rawText = _clean(raw[kind.name]);
      if (rawText.isEmpty) continue;
      final text = _cleanForKind(rawText, isAm);
      if (text.isEmpty) continue;
      if (_hasGeEz(text) != isAm) continue;

      if (kind == VoiceNoteSectionKind.sentenceToRemember) {
        // The quote guard: the sentence must be a near-verbatim excerpt.
        if (!_isNearSubstring(text, transcriptTokens)) continue;
        if (_tokenCount(text) > VoiceJournalLengthBudget.sentenceToRememberMaxWords) {
          continue;
        }
      } else {
        if (_tokenCount(text) > sectionCeiling * VoiceJournalLengthBudget.hardRejectFactor) {
          continue;
        }
        // The editorial guard: the section's vocabulary must be the reader's.
        if (!_shareVolume(text, transcriptTokens)) continue;
      }

      sections.add(VoiceNoteSection(
        kind: kind,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }

    if (sections.isEmpty) return null;

    final organizedWords = sections.fold<int>(0, (sum, s) => sum + _tokenCount(s.textFor(isAm)));
    if (organizedWords > overallCeiling * VoiceJournalLengthBudget.hardRejectFactor) {
      return null;
    }

    return VoiceJournalResult(
      source: VoiceJournalSource.gemini,
      sections: sections,
      cachedAt: DateTime.now(),
      isAvailable: true,
    );
  }

  /// Normalizes a section: for the quote, keep it near the reader's wording
  /// (strip wrapper quotes a model may have added); for grouped sections, tidy
  /// bullets a model may have prefixed onto a list.
  String _cleanForKind(String text, bool isAm) {
    var t = text.trim();
    t = t.replaceFirst(RegExp(r'^[»›»•\-*\s]+'), '').trim();
    if (t.length >= 2) {
      final open = _quoteCharsFor(isAm).left;
      final close = _quoteCharsFor(isAm).right;
      if (t.startsWith(open) && t.endsWith(close)) {
        t = t.substring(1, t.length - 1).trim();
      }
    }
    return t;
  }

  ({String left, String right}) _quoteCharsFor(bool isAm) =>
      isAm ? (left: '\u201C', right: '\u201D') : (left: '"', right: '"');

  /// Collects every string the model produced for the whole-result banned-phrase
  /// guard.
  List<String> _collectAllTexts(Map<String, dynamic> raw) {
    final out = <String>[];
    for (final kind in VoiceNoteSectionKind.values) {
      final t = _clean(raw[kind.name]);
      if (t.isNotEmpty) out.add(t);
    }
    return out;
  }

  /// The leader first: the sentence must appear within the transcript as a
  /// near-contiguous run of the reader's word sequence.
  bool _isNearSubstring(String sentence, List<String> transcriptTokens) {
    final sTokens = _tokens(sentence);
    if (sTokens.isEmpty) return false;
    if (transcriptTokens.length < sTokens.length) return false;
    outer:
    for (var i = 0; i + sTokens.length <= transcriptTokens.length; i++) {
      for (var j = 0; j < sTokens.length; j++) {
        if (_sameToken(transcriptTokens[i + j], sTokens[j])) continue;
        continue outer;
      }
      return true;
    }
    for (var i = 0; i + sTokens.length <= transcriptTokens.length; i++) {
      var mismatches = 0;
      for (var j = 0; j < sTokens.length; j++) {
        if (!_sameToken(transcriptTokens[i + j], sTokens[j])) mismatches++;
      }
      if (mismatches == 1) return true;
    }
    return false;
  }

  /// True when a grouped section shares a meaningful share of its vocabulary
  /// with the reader's transcript (the model edited rather than authored).
  bool _shareVolume(String text, List<String> transcriptTokens) {
    final sectionTokens = _tokens(text);
    if (sectionTokens.isEmpty) return false;
    final transcriptSet = transcriptTokens.toSet();
    var shared = 0;
    for (final token in sectionTokens) {
      if (transcriptSet.contains(token)) shared++;
    }
    return shared / sectionTokens.length >= 0.5;
  }

  bool _sameToken(String a, String b) => _fold(a) == _fold(b);

  String _fold(String token) {
    var t = token.toLowerCase();
    t = t.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
    if (t.isEmpty) return token.toLowerCase();
    return t;
  }

  List<String> _tokens(String text) {
    final cleaned = _clean(text);
    if (cleaned.isEmpty) return const [];
    return cleaned
        .split(RegExp(r'\s+'))
        .where((t) => _fold(t).isNotEmpty)
        .toList();
  }

  int _tokenCount(String text) => _tokens(text).length;

  /// Phrases that turn an organized journal into a substitute for God, a
  /// coach, or a pitch. English and Amharic forms both checked. Mirrors the
  /// Study/Delve gates' vocabulary so the app's honesty contract is consistent.
  bool _hasBannedPhrase(String text, bool isAm) {
    final lower = text.toLowerCase();
    const phrasesEn = [
      'you should',
      'you need to',
      'you must',
      'i suggest you',
      'consider',
      'god wants you',
      'god is telling you',
      'god told you',
      'god is saying to you',
      'god has a plan for you',
      'god is doing',
      'god did this',
      'god gave you',
      'ask me',
      'come back',
      'let me help',
      'i can help',
      'remember to',
      'try to',
      'i recommend',
      'takeaway',
      'lesson for you',
      'your lesson',
      'life-changing',
      'mind-blowing',
      'amazing',
      'incredible',
      'powerful',
      'revelation',
      'word of knowledge',
      'the spirit moved you',
    ];
    const phrasesAm = [
      'ልትጸልይ', // you should pray
      'ልታደርግ', // you should do
      'አንተ ይገባህ', // you need to
      'አንቺ ይገብሽ', // you need to (f)
      'እግዚአብሔር ይፈልጋል', // God wants
      'እግዚአብሔር ይነግርሃል', // God is telling you
      'እግዚአብሔር የሚልህ', // God is saying to you
      'እግዚአብሔር ለአንተ', // God for you
      'ትምህርት ነው', // it is a lesson
      'ትምህርትህ', // your lesson
      'መገለጥ', // revelation
      'ተመለስ', // come back
      'ጠይቀኝ', // ask me
    ];
    for (final p in isAm ? phrasesAm : phrasesEn) {
      if (lower.contains(p.toLowerCase())) return true;
    }
    return false;
  }

  bool _hasGeEz(String text) {
    for (final rune in text.runes) {
      if ((rune >= 0x1200 && rune <= 0x137F) ||
          (rune >= 0x2D80 && rune <= 0x2DDF) ||
          (rune >= 0xAB00 && rune <= 0xAB2F)) {
        return true;
      }
    }
    return false;
  }

  String _clean(dynamic v) {
    if (v is! String) return '';
    final t = v.trim();
    return t.isEmpty ? '' : t;
  }
}