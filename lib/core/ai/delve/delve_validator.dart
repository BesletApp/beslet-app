import 'delve_models.dart';
import 'delve_prompt.dart';
import '../study/book_meta.dart';
import '../study/study_models.dart';

/// Turns a raw Gemini deep-study payload into a validated [DelveResult], or
/// null.
///
/// This is the honesty gate between the model and the reader, and it mirrors
/// the Study validator's contract exactly:
///  - a banned phrase anywhere (spiritual authority, dependency, revelation
///    claims, denominational posturing, hype) rejects the *entire* deep note —
///    a note that tells the reader what God wants must never appear at all;
///  - shape/type checks, hard length caps, and script consistency are applied
///    per block — a bloated or wrong-language block is dropped while the honest
///    rest of the note survives;
///  - structured observations must stay inside the studied passage;
///  - historical entries must carry a known label and an honest confidence
///    category;
///  - terms must carry a meaning and a recognized language;
///  - cross-references are checked against the deterministic canon; invalid,
///    reasonless, or out-of-canon ones are dropped, and only canonical
///    app-resolved labels render;
///  - documented interpretations are split into honest tiers and never
///    presented above their tier.
///
/// A rejected (null) result becomes the gracefully explained "unavailable"
/// deep note; a deep note the validator cannot stand behind is never shown.
///
/// [`StudyValidator`] (the first-pass honesty gate) is deliberately untouched:
/// the deep study is a separate layer with its own validator.
class DelveValidator {
  /// The deterministic canon every reference is checked against — reused
  /// read-only from the Study layer.
  final StudyCanon canon;

  const DelveValidator({required this.canon});

  DelveResult? validate({
    required Map<String, dynamic> raw,
    required DelveRequest request,
  }) {
    final isAm = request.isAmharic;
    final reference = request.reference;

    final allTexts = _collectAllTexts(raw);
    for (final text in allTexts) {
      if (_hasBannedPhrase(text, isAm)) return null;
    }

    final sections = <DelveSection>[];

    // 1. Expanded historical background — prose plus evidence-categorized
    // entries, deeper than the study's first pass.
    final history = _map(raw['expandedHistory']);
    final historyText = _clean(history?['text']);
    final historyEntries = _validatedHistoryEntries(history, isAm);
    if (_acceptProse(historyText, isAm, DelveLengthBudget.expandedHistoryMax,
        allowSteps: false)) {
      sections.add(DelveSection(
        kind: DelveSectionKind.expandedHistory,
        en: isAm ? '' : historyText,
        am: isAm ? historyText : '',
        historyEntries: historyEntries,
      ));
    } else if (historyEntries.isNotEmpty) {
      // The prose was dropped (empty, wrong script, or over budget) but the
      // labeled entries are still honest material; keep them alone.
      sections.add(DelveSection(
        kind: DelveSectionKind.expandedHistory,
        historyEntries: historyEntries,
      ));
    }

    // 2. Literary analysis — movement and structure, allowed to trace the
    // passage's movement in labeled steps.
    final literary = _clean(_map(raw['literaryAnalysis'])?['text']);
    if (_acceptProse(literary, isAm, DelveLengthBudget.literaryAnalysisMax,
        allowSteps: true)) {
      sections.add(DelveSection(
        kind: DelveSectionKind.literaryAnalysis,
        en: isAm ? '' : literary,
        am: isAm ? literary : '',
      ));
    }

    // 3. Original-language analysis — a short guiding prose plus the terms.
    final language = _map(raw['originalLanguage']);
    final languageText = _clean(language?['text']);
    final terms = _validatedTerms(language, isAm);
    if (_acceptProse(languageText, isAm,
        DelveLengthBudget.originalLanguageProseMax, allowSteps: false)) {
      sections.add(DelveSection(
        kind: DelveSectionKind.originalLanguage,
        en: isAm ? '' : languageText,
        am: isAm ? languageText : '',
        terms: terms,
      ));
    } else if (terms.isNotEmpty) {
      sections.add(DelveSection(
        kind: DelveSectionKind.originalLanguage,
        terms: terms,
      ));
    }

    // 4. Expanded cross-reference study — canon-validated references only.
    final references = _validatedReferences(raw['expandedCrossReferences'], isAm);
    if (references.isNotEmpty) {
      sections.add(DelveSection(
        kind: DelveSectionKind.expandedCrossReferences,
        references: references,
      ));
    }

    // 5. Historically documented interpretations — tiered, attributed when
    // known, never above their honest tier.
    final interpretations =
        _validatedInterpretations(raw['documentedInterpretations'], isAm);
    if (interpretations.isNotEmpty) {
      sections.add(DelveSection(
        kind: DelveSectionKind.documentedInterpretations,
        interpretations: interpretations,
      ));
    }

    // 6. Structured observations — verse-anchored, inside the passage.
    final observations = _validatedObservations(
        _map(raw['structuredObservations']), isAm, reference);
    if (observations.isNotEmpty) {
      sections.add(DelveSection(
        kind: DelveSectionKind.structuredObservations,
        observations: observations,
      ));
    }

    if (sections.isEmpty) return null;

    return DelveResult(
      reference: reference,
      source: DelveSource.gemini,
      sections: sections,
      cachedAt: DateTime.now(),
      isAvailable: true,
    );
  }

  /// A text block must be in the reader's script and stay under the hard cap.
  /// Empty or failing blocks are dropped (preserve silence) — a single bad
  /// block does not sink an otherwise honest deep note.
  bool _acceptText(String text, bool isAm, int budget) {
    if (text.isEmpty) return false;
    if (_hasGeEz(text) != isAm) return false;
    if (_wordCount(text) > budget * DelveLengthBudget.hardRejectFactor) {
      return false;
    }
    return true;
  }

  /// A prose block must pass the plain checks and a well-formed hierarchy:
  /// real "• " bullet rows, and labeled movement steps only where the block
  /// may carry them ([allowSteps]) — never more than [StudyFormat.maxSteps].
  bool _acceptProse(String text, bool isAm, int budget,
      {required bool allowSteps}) {
    if (!_acceptText(text, isAm, budget)) return false;
    if (text.isEmpty) return true;
    var steps = 0;
    final stepRe = StudyFormat.step(isAm);
    final headingAttempt = StudyFormat.stepHeadingAttempt(isAm);
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (stepRe.hasMatch(line)) {
        if (!allowSteps) return false;
        steps++;
        if (steps > StudyFormat.maxSteps) return false;
        continue;
      }
      if (headingAttempt.hasMatch(line)) return false;
      if (line.startsWith('•') && !StudyFormat.bullet.hasMatch(line)) {
        return false;
      }
    }
    return true;
  }

  /// Validates the evidence-categorized historical entries. An entry needs a
  /// recognized label, a recognized confidence category, and in-script text
  /// under the per-entry cap; invalid entries are dropped, at most
  /// [DelveLengthBudget.maxHistoryEntries] survive.
  List<DelveHistoryEntry> _validatedHistoryEntries(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['entries']);
    if (items.isEmpty) return const [];
    final out = <DelveHistoryEntry>[];
    for (final item in items) {
      if (out.length >= DelveLengthBudget.maxHistoryEntries) break;
      final m = _map(item);
      if (m == null) continue;
      final label = StudyHistoryLabel.values
          .where((l) => l.name == m['label'])
          .firstOrNull;
      if (label == null) continue;
      final category = StudyHistoryCategory.values
          .where((c) => c.name == m['category'])
          .firstOrNull;
      if (category == null) continue;
      final text = _clean(m['text']);
      if (!_acceptProse(text, isAm, DelveLengthBudget.historyEntryMax,
          allowSteps: false)) {
        continue;
      }
      out.add(DelveHistoryEntry(
        category: category,
        label: label,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }
    return out;
  }

  /// Validates the verse-anchored structured observations. An observation needs
  /// start/end verses inside the studied passage covering 1–3 contiguous
  /// verses, plus in-script text under the cap; invalid observations are
  /// dropped, at most [DelveLengthBudget.maxObservations] survive.
  List<DelveObservation> _validatedObservations(
      dynamic raw, bool isAm, StudyReference reference) {
    final items = _list(_map(raw)?['observations']);
    if (items.isEmpty) return const [];
    final out = <DelveObservation>[];
    for (final item in items) {
      if (out.length >= DelveLengthBudget.maxObservations) break;
      final m = _map(item);
      if (m == null) continue;
      final start = m['startVerse'];
      final end = m['endVerse'];
      if (start is! int || end is! int) continue;
      if (start < reference.startVerse || end > reference.endVerse) continue;
      if (end < start || end - start > 2) continue;
      final text = _clean(m['text']);
      if (!_acceptProse(text, isAm, DelveLengthBudget.observationMax,
          allowSteps: false)) {
        continue;
      }
      out.add(DelveObservation(
        startVerse: start,
        endVerse: end,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }
    return out;
  }

  /// Validates the important original-language terms. A term needs a non-empty
  /// word within the hard cap, a meaning in the reader's script under the cap,
  /// and a recognized language label; invalid terms are dropped, at most
  /// [DelveLengthBudget.maxTerms] survive.
  List<DelveTerm> _validatedTerms(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['terms']);
    if (items.isEmpty) return const [];
    const knownLanguages = {
      'hebrew', 'aramaic', 'greek', 'amharic', 'english', 'geez', 'ge\'ez',
    };
    final out = <DelveTerm>[];
    for (final item in items) {
      if (out.length >= DelveLengthBudget.maxTerms) break;
      final m = _map(item);
      if (m == null) continue;
      final term = _clean(m['term']);
      if (term.isEmpty) continue;
      if (term.runes.length > DelveLengthBudget.termMax) continue;
      final language = _clean(m['language']);
      if (language.isNotEmpty && !knownLanguages.contains(language)) continue;
      final transliteration = _clean(m['transliteration']);
      final meaning = _clean(m['meaning']);
      if (meaning.isEmpty) continue;
      if (_hasGeEz(meaning) != isAm) continue;
      if (_wordCount(meaning) > DelveLengthBudget.termMeaningMax) continue;
      final t = DelveTerm(
        term: term,
        language: language,
        transliteration: transliteration.isEmpty ? null : transliteration,
        verseNumber: m['verseNumber'] is int ? m['verseNumber'] as int : null,
        en: isAm ? '' : meaning,
        am: isAm ? meaning : '',
      );
      out.add(t);
    }
    return out;
  }

  /// Validates the expanded cross-reference list against the deterministic
  /// canon. Invalid, reasonless, wrong-script, oversized, or out-of-canon
  /// references are dropped; up to [DelveLengthBudget.maxCrossReferences] valid
  /// ones survive.
  List<StudyCrossReference> _validatedReferences(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['items']);
    if (items.isEmpty) return const [];
    final out = <StudyCrossReference>[];
    for (final item in items) {
      if (out.length >= DelveLengthBudget.maxCrossReferences) break;
      final m = _map(item);
      if (m == null) continue;
      final bookId = m['bookId'];
      final chapter = m['chapter'];
      final startVerse = m['startVerse'];
      final endVerseRaw = m['endVerse'];
      if (bookId is! String || chapter is! int || startVerse is! int) continue;
      final canonicalBookId = canon.resolveBookId(bookId);
      if (canonicalBookId == null) continue;
      final endVerse = endVerseRaw is int ? endVerseRaw : startVerse;
      final reason = _clean(m['reason']);
      if (reason.isEmpty ||
          _wordCount(reason) > DelveLengthBudget.referenceReasonMax ||
          _hasGeEz(reason) != isAm) {
        continue;
      }
      final priorityRaw = m['priority'];
      final priority = priorityRaw is int ? priorityRaw : 0;
      if (priority < 0 || priority > 2) continue;
      if (!canon.validReference(
        bookId: canonicalBookId,
        chapter: chapter,
        startVerse: startVerse,
        endVerse: endVerse,
        isAmharic: isAm,
      )) {
        continue;
      }
      out.add(StudyCrossReference(
        bookId: canonicalBookId,
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

  /// Validates the historically documented interpretations. An interpretation
  /// needs a recognized tier, in-script text under the cap, and an optional
  /// attribution under its own cap; invalid items are dropped, at most
  /// [DelveLengthBudget.maxInterpretations] survive. A claim in a lower tier is
  /// never presented as a higher one.
  List<DelveInterpretation> _validatedInterpretations(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['items']);
    if (items.isEmpty) return const [];
    final out = <DelveInterpretation>[];
    for (final item in items) {
      if (out.length >= DelveLengthBudget.maxInterpretations) break;
      final m = _map(item);
      if (m == null) continue;
      final tier = StudyTier.values
          .where((t) => t.name == m['tier'])
          .firstOrNull;
      if (tier == null) continue;
      final text = _clean(m['text']);
      if (!_acceptProse(text, isAm, DelveLengthBudget.interpretationMax,
          allowSteps: false)) {
        continue;
      }
      final attributed = _clean(m['attributedTo']);
      if (_wordCount(attributed) > DelveLengthBudget.attributionMax) continue;
      out.add(DelveInterpretation(
        tier: tier,
        attributedTo: attributed.isEmpty ? null : attributed,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }
    return out;
  }

  /// Collects every text the model produced (all blocks, entries, terms,
  /// references, interpretations, observations) for the whole-result banned-
  /// phrase guard.
  List<String> _collectAllTexts(Map<String, dynamic> raw) {
    final out = <String>[];
    void add(dynamic v) {
      final t = _clean(v);
      if (t.isNotEmpty) out.add(t);
    }

    final history = _map(raw['expandedHistory']);
    if (history != null) {
      add(history['text']);
      for (final item in _list(history['entries'])) {
        add(_map(item)?['text']);
      }
    }
    add(_map(raw['literaryAnalysis'])?['text']);
    final language = _map(raw['originalLanguage']);
    if (language != null) {
      add(language['text']);
      for (final term in _list(language['terms'])) {
        add(_map(term)?['meaning']);
        add(_map(term)?['transliteration']);
      }
    }
    for (final item in _list(_map(raw['expandedCrossReferences'])?['items'])) {
      add(_map(item)?['reason']);
    }
    for (final item in _list(_map(raw['documentedInterpretations'])?['items'])) {
      add(_map(item)?['text']);
      add(_map(item)?['attributedTo']);
    }
    for (final item in _list(_map(raw['structuredObservations'])?['observations'])) {
      add(_map(item)?['text']);
    }
    return out;
  }

  /// Phrases that turn a deep note into a substitute for God, another
  /// "helper", or a pitch to come back. English and Amharic forms both checked.
  /// This mirrors the Study validator's list so the two gates never disagree.
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
      'you are meant to',
      'god has a plan for you',
      'god gave you this passage',
      'today god',
      'denominational posturing',
      'the church teaches',
      'our tradition says',
      'we believe that',
      'catholic church',
      'orthodox church',
      'protestants believe',
      'catholics believe',
      'orthodox believe',
      'denominations teach',
      'denominational',
      'life-changing',
      'mind-blowing',
      'so powerful',
      'amazing truth',
      'this debunks',
      'this refutes',
      'proves them wrong',
      'you will be blown away',
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
      'የካቶሊክ ቤተ ክርስቲያን', // the catholic church
      'የኦርቶዶክስ ቤተ ክርስቲያን', // the orthodox church
      'ቤተ ክርስቲያን ያስተምራል', // the church teaches
      'እኛ ፕሮቴስታንቶች', // we protestants
      'ሌላ ትምህርት ይሰጣል', // (another tradition) teaches otherwise
    ];
    for (final p in isAm ? phrasesAm : phrasesEn) {
      if (lower.contains(p.toLowerCase())) return true;
    }
    return false;
  }

  /// Rough word count (Amharic tokens approximate; the point is to catch
  /// runaway prose, not to be exact).
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