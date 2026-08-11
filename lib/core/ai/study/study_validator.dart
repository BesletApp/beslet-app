import 'book_meta.dart';
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
///  - cross-references are checked against the deterministic canon; invalid,
///    reasonless, or out-of-canon ones are dropped, only canonical app-resolved
///    labels render;
///  - interpretation is split into labeled tiers, and the reflection must be
///    a single open-ended question, never a directive.
///
/// A rejected (null) result becomes the quiet "unavailable" fallback; a note
/// the validator cannot stand behind is never shown.
class StudyValidator {
  /// The deterministic canon every reference is checked against.
  final StudyCanon canon;

  const StudyValidator({required this.canon});

  StudyResult? validate({required Map<String, dynamic> raw, required StudyRequest request}) {
    final isAm = request.isAmharic;

    final allTexts = _collectAllTexts(raw);
    for (final text in allTexts) {
      if (_hasBannedPhrase(text, isAm)) return null;
    }

    final sections = <StudySection>[];

    final setting = _clean(_map(raw['setting'])?['text']);
    if (_acceptText(setting, isAm, StudyLengthBudget.settingMax)) {
      sections.add(_textSection(StudySectionKind.setting, setting, isAm));
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

    final whatTextSays = _clean(_map(raw['whatTextSays'])?['text']);
    if (_acceptText(whatTextSays, isAm, StudyLengthBudget.whatTextSaysMax)) {
      sections.add(
          _textSection(StudySectionKind.whatTextSays, whatTextSays, isAm));
    }

    final meaningBackground = _clean(_map(raw['meaningBackground'])?['text']);
    final terms = _validatedTerms(_map(raw['meaningBackground']), isAm);
    if (_acceptText(
        meaningBackground, isAm, StudyLengthBudget.meaningBackgroundMax)) {
      sections.add(StudySection(
        kind: StudySectionKind.meaningBackground,
        en: isAm ? '' : meaningBackground,
        am: isAm ? meaningBackground : '',
        terms: terms,
      ));
    } else if (terms.isNotEmpty) {
      // The text was dropped (empty, wrong script, or over budget) but the
      // terms are still honest material; keep them under the same section.
      sections.add(StudySection(
        kind: StudySectionKind.meaningBackground,
        terms: terms,
      ));
    }

    final references = _validatedReferences(raw['biblicalConnections'], isAm);
    if (references.isNotEmpty) {
      sections.add(
          StudySection(kind: StudySectionKind.biblicalConnections, references: references));
    }

    final blocks = _validatedBlocks(raw['whatCanBeUnderstood'], isAm);
    if (blocks.isNotEmpty) {
      sections.add(
          StudySection(kind: StudySectionKind.whatCanBeUnderstood, blocks: blocks));
    }

    final reflection = _clean(_map(raw['reflection'])?['text']);
    if (_acceptText(reflection, isAm, StudyLengthBudget.reflectionMax) &&
        _isSingleQuestion(reflection)) {
      sections.add(_textSection(StudySectionKind.reflection, reflection, isAm));
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

  StudySection _textSection(StudySectionKind kind, String text, bool isAm) =>
      StudySection(
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

  /// The reflection must be a single open-ended question — a directive or a
  /// run-on list would change the reader's posture toward the text.
  bool _isSingleQuestion(String text) {
    final t = text.trim();
    if (t.isEmpty) return false;
    // ASCII, Arabic (U+061F), fullwidth (U+FF1F), and Ethiopic (U+1367)
    // question marks.
    const marks = ['?', '\u061F', '\uFF1F', '፧'];
    if (!marks.any(t.endsWith)) return false;
    var count = 0;
    for (final m in marks) {
      count += m.allMatches(t).length;
    }
    return count == 1;
  }

  /// Validates the tiered "what can be understood" blocks. A block needs a
  /// recognized tier and in-script text under the per-block cap; invalid
  /// blocks are dropped, and never more than [StudyLengthBudget.maxTierBlocks]
  /// survive. The model never upgrades a claim to a stronger tier than it can
  /// honestly hold.
  List<StudyTieredBlock> _validatedBlocks(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['blocks']);
    if (items.isEmpty) return const [];
    final out = <StudyTieredBlock>[];
    for (final item in items) {
      if (out.length >= StudyLengthBudget.maxTierBlocks) break;
      final m = _map(item);
      if (m == null) continue;
      final tier = StudyTier.values
          .where((t) => t.name == m['tier'])
          .firstOrNull;
      if (tier == null) continue;
      final text = _clean(m['text']);
      if (!_acceptText(text, isAm, StudyLengthBudget.tierBlockMax)) continue;
      out.add(StudyTieredBlock(
        tier: tier,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }
    return out;
  }

  /// Validates the important-terms / original-language list attached to
  /// "meaning and background". A term needs a non-empty word within the hard
  /// cap, a meaning in the reader's script under the per-term cap, and a
  /// recognized language label; invalid terms are dropped, and never more than
  /// [StudyLengthBudget.maxTerms] survive. The term's word stays in its own
  /// script — it is not subject to the reader-script check.
  List<StudyTerm> _validatedTerms(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['terms']);
    if (items.isEmpty) return const [];
    const knownLanguages = {
      'hebrew', 'aramaic', 'greek', 'amharic', 'english', 'geez', 'ge\'ez',
    };
    final out = <StudyTerm>[];
    for (final item in items) {
      if (out.length >= StudyLengthBudget.maxTerms) break;
      final m = _map(item);
      if (m == null) continue;
      final term = _clean(m['term']);
      if (term.isEmpty) continue;
      if (term.runes.length > StudyLengthBudget.termMax) continue;
      final language = _clean(m['language']);
      if (language.isNotEmpty && !knownLanguages.contains(language)) continue;
      final transliteration = _clean(m['transliteration']);
      final meaning = _clean(m['meaning']);
      if (meaning.isEmpty) continue;
      if (_hasGeEz(meaning) != isAm) continue;
      if (_wordCount(meaning) > StudyLengthBudget.termMeaningMax) continue;
      final t = StudyTerm(
        term: term,
        language: language,
        transliteration: transliteration.isEmpty ? null : transliteration,
        en: isAm ? '' : meaning,
        am: isAm ? meaning : '',
      );
      out.add(t);
    }
    return out;
  }

  /// Validates the cross-reference list against the deterministic canon.
  /// Invalid, reasonless, wrong-script, oversized, or out-of-canon references
  /// are dropped; up to [StudyLengthBudget.maxCrossReferences] valid ones
  /// survive. Never invents a reference that does not exist.
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
      final priorityRaw = m['priority'];
      final priority = priorityRaw is int ? priorityRaw : 0;
      if (priority < 0 || priority > 2) continue;
      if (!canon.validReference(
        bookId: bookId,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        isAmharic: isAm,
      )) {
        continue;
      }
      out.add(StudyCrossReference(
        bookId: bookId,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        en: isAm ? '' : reason,
        am: isAm ? reason : '',
        priority: priority,
      ));
    }
    return out;
  }

  /// Collects every text the model produced (all sections, both context
  /// halves, tiered blocks, and cross-reference reasons) for the whole-result
  /// banned-phrase guard. A banned phrase in any of them rejects the entire
  /// note.
  List<String> _collectAllTexts(Map<String, dynamic> raw) {
    final out = <String>[];
    void add(dynamic v) {
      final t = _clean(v);
      if (t.isNotEmpty) out.add(t);
    }

    add(_map(raw['setting'])?['text']);
    add(_map(raw['whatTextSays'])?['text']);
    final context = _map(raw['context']);
    if (context != null) {
      add(context['behindTheText']);
      add(context['inTheText']);
    }
    add(_map(raw['meaningBackground'])?['text']);
    for (final term in _list(_map(raw['meaningBackground'])?['terms'])) {
      add(_map(term)?['meaning']);
      add(_map(term)?['transliteration']);
    }
    add(_map(raw['reflection'])?['text']);
    for (final item in _list(_map(raw['biblicalConnections'])?['items'])) {
      add(_map(item)?['reason']);
    }
    for (final block in _list(_map(raw['whatCanBeUnderstood'])?['blocks'])) {
      add(_map(block)?['text']);
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
