import '../../services/scripture_service.dart';
import 'study_models.dart';
import 'study_prompt.dart';

/// Turns a raw Gemini study payload into a validated [StudyResult], or null.
///
/// This is the honesty gate between the model and the reader:
///  - a banned phrase anywhere (spiritual authority, dependency, or
///    self-promotion) rejects the *entire* result — a note that tells the
///    reader what God wants must never appear at all;
///  - shape/type checks, hard length caps, and script consistency are applied
///    per section — a bloated or wrong-language section is dropped while the
///    honest rest of the note survives;
///  - cross-references are checked against the real canon; invalid or
///    reasonless ones are dropped, only canonical app-resolved labels render.
///
/// A rejected (null) result becomes the quiet "unavailable" fallback; a note
/// the validator cannot stand behind is never shown.
class StudyValidator {
  const StudyValidator();

  StudyResult? validate({required Map<String, dynamic> raw, required StudyRequest request}) {
    final isAm = request.isAmharic;

    final allTexts = _collectAllTexts(raw);
    for (final text in allTexts) {
      if (_hasBannedPhrase(text, isAm)) return null;
    }

    final sections = <StudySection>[];

    final summary = _clean(_map(raw['summary'])?['text']);
    if (_acceptText(summary, isAm, StudyLengthBudget.summaryMax)) {
      sections.add(_textSection(StudySectionKind.summary, summary, isAm));
    }

    final context = _map(raw['context']);
    if (context != null) {
      final behind = _clean(context['behindTheText']);
      final inText = _clean(context['inTheText']);
      if (behind.isNotEmpty || inText.isNotEmpty) {
        if (_acceptText(behind, isAm, StudyLengthBudget.contextBehindMax) &&
            _acceptText(inText, isAm, StudyLengthBudget.contextInMax)) {
          sections.add(StudySection(
            kind: StudySectionKind.context,
            en: isAm ? '' : behind,
            am: isAm ? behind : '',
            enSub: isAm ? null : (inText.isEmpty ? null : inText),
            amSub: isAm ? (inText.isEmpty ? null : inText) : null,
          ));
        }
      }
    }

    final observations = _clean(_map(raw['observations'])?['text']);
    if (_acceptText(observations, isAm, StudyLengthBudget.observationsMax)) {
      sections.add(_textSection(StudySectionKind.observations, observations, isAm));
    }

    final teachings = _clean(_map(raw['teachings'])?['text']);
    if (_acceptText(teachings, isAm, StudyLengthBudget.teachingsMax)) {
      sections.add(_textSection(StudySectionKind.teachings, teachings, isAm));
    }

    final reflection = _clean(_map(raw['reflection'])?['text']);
    if (_acceptText(reflection, isAm, StudyLengthBudget.reflectionMax)) {
      sections.add(_textSection(StudySectionKind.reflection, reflection, isAm));
    }

    final references = _validatedReferences(raw['crossReferences'], isAm);
    if (references.isNotEmpty) {
      sections.add(StudySection(kind: StudySectionKind.crossReferences, references: references));
    }

    if (sections.isEmpty) return null;

    return StudyResult(
      reference: request.reference,
      source: StudySource.gemini,
      sections: sections,
      cachedAt: DateTime.now(),
      isAvailable: true,
    );
  }

  StudySection _textSection(StudySectionKind kind, String text, bool isAm) => StudySection(
        kind: kind,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      );

  /// A text section must be in the reader's script and stay under the hard
  /// cap. Empty or failing sections are dropped (preserve silence) — a single
  /// bad section does not sink an otherwise honest note.
  bool _acceptText(String text, bool isAm, int budget) {
    if (text.isEmpty) return false;
    if (_hasGeEz(text) != isAm) return false;
    if (_wordCount(text) > budget * StudyLengthBudget.hardRejectFactor) return false;
    return true;
  }

  /// Validates the cross-reference list against the real canon. Invalid,
  /// reasonless, wrong-script, or oversized references are dropped; up to
  /// [StudyLengthBudget.maxCrossReferences] valid ones survive. Never invents
  /// a reference that does not exist.
  List<StudyCrossReference> _validatedReferences(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['items']);
    if (items.isEmpty) return const [];
    final out = <StudyCrossReference>[];
    for (final item in items) {
      if (out.length >= StudyLengthBudget.maxCrossReferences) break;
      final m = _map(item);
      if (m == null) continue;
      final bookId = m['bookId'];
      final chapter = m['chapter'];
      final startVerse = m['startVerse'];
      final endVerseRaw = m['endVerse'];
      if (bookId is! String || chapter is! int || startVerse is! int) continue;
      final endVerse = endVerseRaw is int ? endVerseRaw : startVerse;
      final reason = _clean(m['reason']);
      if (reason.isEmpty ||
          _wordCount(reason) > StudyLengthBudget.referenceReasonMax ||
          _hasGeEz(reason) != isAm) {
        continue;
      }
      final book = ScriptureService.bookMap[bookId];
      if (book == null) continue;
      if (chapter < 1 || chapter > book.chapters) continue;
      if (startVerse < 1 || endVerse < startVerse) continue;
      out.add(StudyCrossReference(
        bookId: bookId,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        en: isAm ? '' : reason,
        am: isAm ? reason : '',
      ));
    }
    return out;
  }

  /// Collects every text the model produced (main sections, both context
  /// halves, and cross-reference reasons) for the whole-result banned-phrase
  /// guard. A banned phrase in any of them rejects the entire note.
  List<String> _collectAllTexts(Map<String, dynamic> raw) {
    final out = <String>[];
    void add(dynamic v) {
      final t = _clean(v);
      if (t.isNotEmpty) out.add(t);
    }

    add(_map(raw['summary'])?['text']);
    final context = _map(raw['context']);
    if (context != null) {
      add(context['behindTheText']);
      add(context['inTheText']);
    }
    add(_map(raw['observations'])?['text']);
    add(_map(raw['teachings'])?['text']);
    add(_map(raw['reflection'])?['text']);
    for (final item in _list(_map(raw['crossReferences'])?['items'])) {
      add(_map(item)?['reason']);
    }
    return out;
  }

  /// Phrases that turn a note into a substitute for God, another "helper", or
  /// a pitch to come back. English and Amharic forms both checked.
  bool _hasBannedPhrase(String text, bool isAm) {
    final lower = text.toLowerCase();
    const phrasesEn = [
      'you should',
      'you need to',
      'you must',
      'god wants you',
      'god is telling you',
      'god told you',
      'god is saying to you',
      'pray this prayer',
      'pray this',
      'ask me',
      'come back',
      'turn to me',
      'let me help',
      'i can help',
      'you can always come',
    ];
    const phrasesAm = [
      'እግዚአብሔር ይፈልጋል', // God wants
      'እግዚአብሔር ይነግርሃል', // God is telling you
      'ልትጸልይ', // you should pray
      'ልታደርግ', // you should do
      'አንተ ይገባህ', // you need to
      'አንቺ ይገብሽ', // you need to (f)
      'ተመለስ', // come back
      'ጠይቀኝ', // ask me
    ];
    for (final p in isAm ? phrasesAm : phrasesEn) {
      if (lower.contains(p.toLowerCase())) return true;
    }
    return false;
  }

  /// Rough word count. For Amharic (phrasal, space-separated tokens) this is
  /// an approximation; the point is to catch runaway prose, not to be exact.
  int _wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// True when the string contains Ethiopic (Ge'ez) script characters.
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

  Map<String, dynamic>? _map(dynamic v) =>
      v is Map<String, dynamic> ? v : (v is Map ? Map<String, dynamic>.from(v) : null);

  List<dynamic> _list(dynamic v) => v is List ? v : const [];

  String _clean(dynamic v) {
    if (v is! String) return '';
    final t = v.trim();
    return t.isEmpty ? '' : t;
  }
}