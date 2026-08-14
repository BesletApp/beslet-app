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
///  - verse-by-verse observations must stay inside the studied passage;
///  - historical entries must carry a known label and an honest confidence
///    category;
///  - cross-references are checked against the deterministic canon; invalid,
///    reasonless, or out-of-canon ones are dropped, only canonical app-resolved
///    labels render;
///  - interpretation is split into labeled tiers, and the consider question
///    must be an open-ended question, never a directive.
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

    // 1. Passage overview — three to five bullet facts.
    final overview = _clean(_map(raw['passageOverview'])?['text']);
    if (_acceptProse(overview, isAm, StudyLengthBudget.passageOverviewMax,
        allowSteps: false)) {
      sections.add(_textSection(StudySectionKind.passageOverview, overview, isAm));
    }

    // 2. Historical background — prose plus evidence-categorized entries.
    final history = _map(raw['historicalBackground']);
    final historyText = _clean(history?['text']);
    final historyEntries = _validatedHistoryEntries(history, isAm);
    if (_acceptProse(historyText, isAm,
        StudyLengthBudget.historicalBackgroundMax, allowSteps: false)) {
      sections.add(StudySection(
        kind: StudySectionKind.historicalBackground,
        en: isAm ? '' : historyText,
        am: isAm ? historyText : '',
        historyEntries: historyEntries,
      ));
    } else if (historyEntries.isNotEmpty) {
      // The prose was dropped (empty, wrong script, or over budget) but the
      // labeled entries are still honest material; keep them alone.
      sections.add(StudySection(
        kind: StudySectionKind.historicalBackground,
        historyEntries: historyEntries,
      ));
    }

    // 3. Literary context — what surrounds the passage and what it
    // communicates, allowed to trace its movement in labeled steps.
    final literary = _clean(_map(raw['literaryContext'])?['text']);
    if (_acceptProse(literary, isAm, StudyLengthBudget.literaryContextMax,
        allowSteps: true)) {
      sections.add(
          _textSection(StudySectionKind.literaryContext, literary, isAm));
    }

    // 4. Verse by verse — observations anchored to verses inside the passage.
    final observations = _validatedObservations(
        _map(raw['verseByVerse']), isAm, request.reference);
    if (observations.isNotEmpty) {
      sections.add(StudySection(
        kind: StudySectionKind.verseByVerse,
        verseObservations: observations,
      ));
    }

    // 5. Original language — prose plus the important terms.
    final language = _map(raw['originalLanguage']);
    final languageText = _clean(language?['text']);
    final terms = _validatedTerms(language, isAm);
    if (_acceptProse(languageText, isAm,
        StudyLengthBudget.originalLanguageMax, allowSteps: false)) {
      sections.add(StudySection(
        kind: StudySectionKind.originalLanguage,
        en: isAm ? '' : languageText,
        am: isAm ? languageText : '',
        terms: terms,
      ));
    } else if (terms.isNotEmpty) {
      // The text was dropped (empty, wrong script, or over budget) but the
      // terms are still honest material; keep them under the same section.
      sections.add(StudySection(
        kind: StudySectionKind.originalLanguage,
        terms: terms,
      ));
    }

    // 6. Scripture alongside Scripture — canon-validated cross-references.
    final references = _validatedReferences(raw['scriptureInterconnections'], isAm);
    if (references.isNotEmpty) {
      sections.add(StudySection(
          kind: StudySectionKind.scriptureInterconnections,
          references: references));
    }

    // 7. What is clear / what requires care — labeled tiers.
    final blocks = _validatedBlocks(raw['explicitTeachings'], isAm);
    if (blocks.isNotEmpty) {
      sections.add(StudySection(
          kind: StudySectionKind.explicitTeachings, blocks: blocks));
    }

    // 8. Questions to carry — one or two open questions plus optional threads.
    final questionsMap = _map(raw['questionsToCarry']);
    final questionText = _clean(questionsMap?['text']);
    if (_acceptText(questionText, isAm, StudyLengthBudget.questionsMax) &&
        _isConsider(questionText)) {
      final threads = _validatedThreads(_clean(questionsMap?['threads']), isAm);
      sections.add(StudySection(
        kind: StudySectionKind.questionsToCarry,
        en: isAm ? '' : questionText,
        am: isAm ? questionText : '',
        enSub: isAm ? null : threads,
        amSub: isAm ? threads : null,
      ));
    }

    if (sections.isEmpty) return null;

    return StudyResult(
      reference: request.reference,
      source: StudySource.gemini,
      sections: sections,
      anchor: _validatedAnchor(_map(raw['anchor']), isAm),
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

  /// A prose section must pass the plain checks and a well-formed hierarchy:
  /// bullets are real "• " rows, and labeled movement steps are allowed only
  /// where the section may carry them ([allowSteps]) — and never more than
  /// [StudyFormat.maxSteps]. Malformed markers (a dash bullet, a broken step
  /// heading, a runaway step list) drop the section; the honest rest survives.
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

  /// The optional threads line nested on the consider questions. When absent
  /// it stays silent; when present it must be in the reader's script, under
  /// the cap, and an observation — never a question and never a directive (the
  /// global banned-phrase pass already rules out second-person commands).
  String? _validatedThreads(String text, bool isAm) {
    if (text.isEmpty) return null;
    if (_hasGeEz(text) != isAm) return null;
    if (_wordCount(text) > StudyLengthBudget.threadsMax) return null;
    if (_isConsider(text)) return null;
    return text;
  }

  /// The consider questions must be one or two open-ended questions — a
  /// directive or a run-on list would change the reader's posture toward the
  /// text.
  bool _isConsider(String text) {
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
    return count >= 1 && count <= 2;
  }

  /// Validates the evidence-categorized historical entries. An entry needs a
  /// recognized label, a recognized confidence category, and in-script text
  /// under the per-entry cap; invalid entries are dropped, and never more than
  /// [StudyLengthBudget.maxHistoryEntries] survive. The model never presents a
  /// reconstruction as an established fact.
  List<StudyHistoryEntry> _validatedHistoryEntries(dynamic raw, bool isAm) {
    final items = _list(_map(raw)?['entries']);
    if (items.isEmpty) return const [];
    final out = <StudyHistoryEntry>[];
    for (final item in items) {
      if (out.length >= StudyLengthBudget.maxHistoryEntries) break;
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
      if (!_acceptProse(text, isAm, StudyLengthBudget.historyEntryMax,
          allowSteps: false)) {
        continue;
      }
      out.add(StudyHistoryEntry(
        category: category,
        label: label,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }
    return out;
  }

  /// Validates the verse-anchored observations. An observation needs
  /// start/end verses inside the studied passage covering 1–3 contiguous
  /// verses, plus in-script text under the per-observation cap; invalid
  /// observations are dropped, and never more than
  /// [StudyLengthBudget.maxVerseObservations] survive.
  List<StudyVerseObservation> _validatedObservations(
      dynamic raw, bool isAm, StudyReference reference) {
    final items = _list(_map(raw)?['observations']);
    if (items.isEmpty) return const [];
    final out = <StudyVerseObservation>[];
    for (final item in items) {
      if (out.length >= StudyLengthBudget.maxVerseObservations) break;
      final m = _map(item);
      if (m == null) continue;
      final start = m['startVerse'];
      final end = m['endVerse'];
      if (start is! int || end is! int) continue;
      if (start < reference.startVerse || end > reference.endVerse) continue;
      if (end < start || end - start > 2) continue;
      final text = _clean(m['text']);
      if (!_acceptProse(text, isAm, StudyLengthBudget.verseObservationMax,
          allowSteps: false)) {
        continue;
      }
      out.add(StudyVerseObservation(
        startVerse: start,
        endVerse: end,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }
    return out;
  }

  /// Validates the tiered "what is clear" blocks. A block needs a recognized
  /// tier and in-script text under the per-block cap; invalid blocks are
  /// dropped, and never more than [StudyLengthBudget.maxTierBlocks] survive.
  /// The model never upgrades a claim to a stronger tier than it can honestly
  /// hold.
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
      if (!_acceptProse(text, isAm, StudyLengthBudget.tierBlockMax,
          allowSteps: false)) {
        continue;
      }
      out.add(StudyTieredBlock(
        tier: tier,
        en: isAm ? '' : text,
        am: isAm ? text : '',
      ));
    }
    return out;
  }

  /// Validates the important-terms / original-language list. A term needs a
  /// non-empty word within the hard cap, a meaning in the reader's script
  /// under the per-term cap, and a recognized language label; invalid terms
  /// are dropped, and never more than [StudyLengthBudget.maxTerms] survive.
  /// The term's word stays in its own script — it is not subject to the
  /// reader-script check.
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
        verseNumber: m['verseNumber'] is int ? m['verseNumber'] as int : null,
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
      final canonicalBookId = canon.resolveBookId(bookId);
      if (canonicalBookId == null) continue;
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

  /// Validates the memory anchor. Each element must be in the reader's script,
  /// under its cap, and an observation (never a question); anything invalid is
  /// nulled, and an anchor with nothing left is omitted.
  StudyAnchor? _validatedAnchor(dynamic raw, bool isAm) {
    if (raw == null) return null;
    String keep(String text, int cap) {
      if (text.isEmpty) return '';
      if (_hasGeEz(text) != isAm) return '';
      if (_wordCount(text) > cap) return '';
      if (_isConsider(text)) return '';
      return text;
    }

    final anchor = StudyAnchor(
      imageEn: isAm ? '' : keep(_clean(raw['image']), StudyLengthBudget.anchorImageMax),
      imageAm: isAm ? keep(_clean(raw['image']), StudyLengthBudget.anchorImageMax) : '',
      keywordEn: isAm ? '' : keep(_clean(raw['keyword']), StudyLengthBudget.anchorKeywordMax),
      keywordAm: isAm ? keep(_clean(raw['keyword']), StudyLengthBudget.anchorKeywordMax) : '',
      sentenceEn: isAm ? '' : keep(_clean(raw['sentence']), StudyLengthBudget.anchorSentenceMax),
      sentenceAm: isAm ? keep(_clean(raw['sentence']), StudyLengthBudget.anchorSentenceMax) : '',
    );
    return anchor.isEmpty ? null : anchor;
  }

  /// Collects every text the model produced (all sections, historical entries,
  /// verse observations, tiered blocks, terms, threads, anchor, and
  /// cross-reference reasons) for the whole-result banned-phrase guard. A
  /// banned phrase in any of them rejects the entire note.
  List<String> _collectAllTexts(Map<String, dynamic> raw) {
    final out = <String>[];
    void add(dynamic v) {
      final t = _clean(v);
      if (t.isNotEmpty) out.add(t);
    }

    add(_map(raw['passageOverview'])?['text']);
    final history = _map(raw['historicalBackground']);
    if (history != null) {
      add(history['text']);
      for (final item in _list(history['entries'])) {
        add(_map(item)?['text']);
      }
    }
    add(_map(raw['literaryContext'])?['text']);
    final verses = _map(raw['verseByVerse']);
    if (verses != null) {
      for (final item in _list(verses['observations'])) {
        add(_map(item)?['text']);
      }
    }
    final language = _map(raw['originalLanguage']);
    if (language != null) {
      add(language['text']);
      for (final term in _list(language['terms'])) {
        add(_map(term)?['meaning']);
        add(_map(term)?['transliteration']);
      }
    }
    final questionsMap = _map(raw['questionsToCarry']);
    add(questionsMap?['text']);
    add(questionsMap?['threads']);
    for (final item in _list(_map(raw['scriptureInterconnections'])?['items'])) {
      add(_map(item)?['reason']);
    }
    for (final block in _list(_map(raw['explicitTeachings'])?['blocks'])) {
      add(_map(block)?['text']);
    }
    final anchor = _map(raw['anchor']);
    if (anchor != null) {
      add(anchor['image']);
      add(anchor['keyword']);
      add(anchor['sentence']);
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
      // Denominational posturing — the note must never take sides or lean on a
      // tradition's authority; a reader from any background must meet only the
      // text.
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
      // Hype — promotional language trades on excitement instead of the text.
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
      // Denominational posturing.
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
