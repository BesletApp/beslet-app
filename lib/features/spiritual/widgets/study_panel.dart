import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/study/study_models.dart';
import '../../../core/ai/study/study_provider.dart';
import '../../../core/ai/study/study_sources.dart';
import '../../../core/providers/scripture_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/settings/widgets/gemini_key_dialog.dart';
import '../../../l10n/app_localizations.dart';

/// The near-full-screen study note. Opens on a verse (from the action sheet)
/// or a selected passage (from the selection bar). Renders the passage text,
/// the sections the note actually carries, and the quiet authority footer.
/// Empty sections preserve silence — the model is never padded.
class StudyPanel extends ConsumerStatefulWidget {
  final StudyRequest request;
  final bool isAm;

  const StudyPanel({super.key, required this.request, required this.isAm});

  @override
  ConsumerState<StudyPanel> createState() => _StudyPanelState();
}

class _StudyPanelState extends ConsumerState<StudyPanel> {
  late Future<StudyResult> _future;

  /// Whether the "free AI sessions used" banner is still shown. Once dismissed
  /// (Continue with Offline Study) it stays hidden for this open; after the
  /// reader adds their own key a fresh resolution replaces the note entirely.
  bool _showLimitBanner = true;

  /// Whether the "AI study is unavailable — reason" banner is still shown. Same
  /// dismiss-one-open behavior as the limit banner.
  bool _showUnavailable = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudyResult> _load({bool force = false, bool bypassDisk = false}) async {
    final service = await ref.read(studyServiceProvider.future);
    // The service provider resolves the intro library, so by this point the
    // genre is available (or the panel's test override left it untouched).
    final genre = ref
        .read(studyIntroLibraryProvider)
        .valueOrNull
        ?.introFor(widget.request.reference.bookId)
        ?.genre;
    final request = genre == null
        ? widget.request
        : StudyRequest(
            reference: widget.request.reference,
            isAmharic: widget.request.isAmharic,
            verseTexts: widget.request.verseTexts,
            genre: genre,
          );
    // force = a fresh resolution (bypasses the in-memory cache) so adding a
    // personal API key continues the study in place, not from a stale result.
    // bypassDisk also clears any persisted note so the fresh user-key run is
    // never shadowed by old content.
    return force
        ? service.refresh(request, bypassDisk: bypassDisk)
        : service.study(request);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    final sources = ref.watch(studySourcesProvider).valueOrNull;
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(children: [
              Icon(Icons.menu_book, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.request.reference.referenceFor(widget.isAm),
                  style: AppTextStyles.labelLarge.copyWith(color: c.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: c.textSecondary, size: 20),
                tooltip: l.studyCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FutureBuilder<StudyResult>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _buildLoading(c, l);
                }
                final result = snapshot.data;
                if (result == null) {
                  return _buildOffline(c, l);
                }
                if (result.limitReached ||
                    result.unavailability == StudyUnavailability.capped) {
                  return _buildLimited(c, l, result, sources);
                }
                if (result.unavailability != StudyUnavailability.none ||
                    !result.isAvailable) {
                  return _buildUnavailable(c, l, result, sources);
                }
                return _buildContent(c, l, result, sources);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(ThemePalette c, AppLocalizations l) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
        const SizedBox(height: 16),
        Text(
          l.studyLoading,
          style: TextStyle(color: c.textSecondary, fontSize: 13),
        ),
      ]),
    );
  }

  Widget _buildOffline(ThemePalette c, AppLocalizations l) {
    final reference = widget.request.reference.referenceFor(widget.isAm);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
      children: [
        Text(
          reference,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelLarge.copyWith(color: c.primary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Icon(Icons.wifi_off, size: 40, color: c.textMuted.withValues(alpha: 0.3)),
        const SizedBox(height: AppSpacing.md),
        Text(
          l.studyOfflineNote,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  /// Shown when the app's free daily AI allowance is reached: a calm
  /// explanation with the choice to keep reading offline or add a personal
  /// Gemini key, above whatever note is available (the offline assembly, or
  /// the quiet empty view when there is no offline material).
  Widget _buildLimited(ThemePalette c, AppLocalizations l, StudyResult result,
      StudySourceRegistry? sources) {
    final noteAvailable = result.isAvailable && result.sections.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showLimitBanner) ...[
          _LimitBanner(
            isAm: widget.isAm,
            onContinueOffline: () => setState(() => _showLimitBanner = false),
            onAddKey: _addApiKeyAndRetry,
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          child: noteAvailable
              ? _buildContent(c, l, result, sources)
              : _buildOffline(c, l),
        ),
      ],
    );
  }

  /// Opens the shared Gemini-key dialog; once a key is verified and saved the
  /// study re-runs through the service's `refresh` path (bypassing memory AND
  /// the disk cache) so it continues in place — no reopen, no restart.
  Future<void> _addApiKeyAndRetry() async {
    final action = await showGeminiKeyDialog(context);
    if (!mounted) return;
    if (action == 'saved') {
      setState(() => _future = _load(force: true, bypassDisk: true));
    }
  }

  /// Shown whenever AI study was unavailable for a reason other than the daily
  /// cap: a clear "why" banner above whatever offline content exists. The
  /// reason is never hidden and the offline note is always labeled, so a
  /// fallback can never masquerade as a generated AI study. `_showUnavailable`
  /// lets the reader dismiss the banner once (Continue with Offline Study)
  /// without losing the note underneath.
  Widget _buildUnavailable(ThemePalette c, AppLocalizations l,
      StudyResult result, StudySourceRegistry? sources) {
    final noteAvailable = result.isAvailable && result.sections.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showUnavailable) ...[
          _UnavailableBanner(
            isAm: widget.isAm,
            reason: result.unavailability,
            onContinueOffline: () =>
                setState(() => _showUnavailable = false),
            onAddKey: _addApiKeyAndRetry,
          ),
          const SizedBox(height: 4),
        ],
        Expanded(
          child: noteAvailable
              ? _buildContent(c, l, result, sources)
              : _buildOffline(c, l),
        ),
      ],
    );
  }

  Widget _buildContent(ThemePalette c, AppLocalizations l, StudyResult result,
      StudySourceRegistry? sources) {
    final sections = _canonicalSections(result);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      children: [
        _buildPassage(c),
        const SizedBox(height: 8),
        _buildSourceLabel(c, l, result.source),
        if (result.anchor != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildAnchorCard(c, l, result.anchor!),
        ],
        const SizedBox(height: AppSpacing.lg),
        for (final section in sections) ...[
          _StudySectionCard(
            title: _titleFor(l, section.kind),
            isAm: widget.isAm,
            child: _buildSectionBody(c, l, section),
          ),
          if (sources != null && section.sourceIds.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildSources(c, l, sources, section.sourceIds),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildAuthorityFooter(c, l),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  /// The memory anchor card: a key image, a key word, and a one-sentence
  /// statement of the passage's central movement. All observations — the panel
  /// never renders an anchor the validator did not stand behind.
  Widget _buildAnchorCard(
      ThemePalette c, AppLocalizations l, StudyAnchor anchor) {
    final style = (widget.isAm
            ? AppTextStyles.amharicBody
            : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.tips_and_updates_outlined, size: 16, color: c.primary),
            const SizedBox(width: 6),
            Text(
              l.studyAnchor,
              style: AppTextStyles.labelLarge.copyWith(
                  color: c.primary, fontSize: 12),
            ),
          ]),
          const SizedBox(height: 8),
          if (anchor.imageFor(widget.isAm).isNotEmpty)
            Text(anchor.imageFor(widget.isAm),
                style: style.copyWith(fontWeight: FontWeight.w600)),
          if (anchor.keywordFor(widget.isAm).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(anchor.keywordFor(widget.isAm),
                style: style.copyWith(fontStyle: FontStyle.italic)),
          ],
          if (anchor.sentenceFor(widget.isAm).isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(anchor.sentenceFor(widget.isAm), style: style),
          ],
        ],
      ),
    );
  }

  /// The panel's canonical scaffold: the passage is step one, then the eight
  /// sections in the order the app guarantees. Whatever order the backend
  /// returned, the panel always renders the sections in this fixed order — a
  /// backend that misorders a note cannot scramble the reader's path through
  /// it.
  static const List<StudySectionKind> _canonicalSectionOrder = [
    StudySectionKind.passageOverview,
    StudySectionKind.historicalBackground,
    StudySectionKind.literaryContext,
    StudySectionKind.verseByVerse,
    StudySectionKind.originalLanguage,
    StudySectionKind.scriptureInterconnections,
    StudySectionKind.explicitTeachings,
    StudySectionKind.questionsToCarry,
  ];

  /// Merges the backend's sections with the panel's own canonical order and
  /// with the offline cross-reference index, then drops empty sections.
  ///
  /// The canonical merge is done here, panel-side, so the reader sees one
  /// stable note regardless of which backend produced it: the offline index's
  /// validated connections are folded into `scriptureInterconnections`
  /// whenever they add something the backend did not already supply, and
  /// everything renders in the app's canonical sequence. Empty sections
  /// preserve silence — no section is padded to fit a slot.
  List<StudySection> _canonicalSections(StudyResult result) {
    final byKind = <StudySectionKind, StudySection>{
      for (final s in result.sections) s.kind: s,
    };
    final scaffold = <StudySection>[];
    for (final kind in _canonicalSectionOrder) {
      if (kind == StudySectionKind.scriptureInterconnections) {
        final merged = _connectionsSection(byKind[kind]);
        if (merged != null && !merged.isEmpty) scaffold.add(merged);
        continue;
      }
      final section = byKind[kind];
      if (section == null || section.isEmpty) continue;
      scaffold.add(section);
    }
    return scaffold;
  }

  /// Builds the connections step of the scaffold. Folds the offline
  /// cross-reference index into the backend's section, or supplies the slot
  /// from the index alone when the backend returned nothing — the connections
  /// step is never left blank when the app has validated material for it.
  StudySection? _connectionsSection(StudySection? backendSection) {
    final offline = ref
        .watch(studyCrossRefProvider)
        .valueOrNull
        ?.crossReferencesFor(
          widget.request.reference.bookId,
          widget.request.reference.chapter,
          widget.request.reference.startVerse,
        ) ??
        const <StudyCrossReference>[];

    if (backendSection == null && offline.isEmpty) return null;

    final seen = <String>{};
    final merged = <StudyCrossReference>[];
    void add(StudyCrossReference r) {
      final key = '${r.bookId}:${r.chapter}:${r.startVerse}:${r.endVerse}';
      if (seen.add(key)) merged.add(r);
    }

    if (backendSection != null) {
      for (final r in backendSection.references) {
        add(r);
      }
    }
    for (final r in offline) {
      add(r);
    }
    merged.sort((a, b) => a.priority.compareTo(b.priority));
    return StudySection(
      kind: StudySectionKind.scriptureInterconnections,
      references: merged,
      sourceIds: backendSection?.sourceIds ?? const [],
    );
  }

  /// The curated sources a section draws on, named quietly under the section.
  /// Labels come only from the app's own bundled registry — never the model.
  Widget _buildSources(ThemePalette c, AppLocalizations l,
      StudySourceRegistry registry, List<String> sourceIds) {
    final titles = <String>[];
    for (final id in sourceIds) {
      final info = registry.sourceFor(id);
      if (info != null) titles.add(info.titleFor(widget.isAm));
    }
    if (titles.isEmpty) return const SizedBox.shrink();
    return Text.rich(
      TextSpan(
        text: '${l.studySectionSources}: ',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c.textMuted,
        ),
        children: [
          TextSpan(
            text: titles.join(' · '),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: c.textMuted,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildPassage(ThemePalette c) {
    final texts = widget.request.verseTexts;
    final single = widget.request.reference.verseCount == 1;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < texts.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == texts.length - 1 ? 0 : 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      single ? '' : '${widget.request.reference.startVerse + i}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: c.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      texts[i],
                      style: (widget.isAm
                              ? AppTextStyles.amharicBody
                              : AppTextStyles.bodyMedium)
                          .copyWith(color: c.textPrimary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// A quiet, always-visible provenance pill: readers can always tell an
  /// AI-generated note from an offline note, so a fallback is never silent.
  Widget _buildSourceLabel(
      ThemePalette c, AppLocalizations l, StudySource source) {
    final isAi = source == StudySource.gemini;
    final label = isAi ? l.studySourceAi : l.studySourceOffline;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAi ? Icons.auto_awesome : Icons.book_outlined,
              size: 12,
              color: c.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The body of a section, without its title (the collapsible card supplies
  /// the title). Long prose is split into short paragraphs for breathing room.
  Widget _buildSectionBody(
      ThemePalette c, AppLocalizations l, StudySection section) {
    if (section.kind == StudySectionKind.historicalBackground) {
      return _buildHistoryBody(c, l, section);
    }
    if (section.kind == StudySectionKind.verseByVerse) {
      return _buildVerseByVerseBody(c, section);
    }
    if (section.kind == StudySectionKind.scriptureInterconnections) {
      return _buildReferencesBody(c, section);
    }
    if (section.kind == StudySectionKind.explicitTeachings) {
      return _buildTieredBody(c, l, section);
    }
    if (section.kind == StudySectionKind.questionsToCarry) {
      return _buildConsiderBody(c, l, section);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.textFor(widget.isAm).isNotEmpty)
          _buildArticle(c, section.textFor(widget.isAm)),
        if (section.terms.isNotEmpty) _buildTermsBlock(c, l, section.terms),
      ],
    );
  }

  /// The questions to carry: one or two open questions, then — when the note
  /// carries one — the quiet "the passage itself says" line that anchors what
  /// was read. Both are observations; neither ever tells the reader what to do.
  Widget _buildConsiderBody(
      ThemePalette c, AppLocalizations l, StudySection section) {
    final text = section.textFor(widget.isAm);
    final threads = section.subTextFor(widget.isAm);
    final style = (widget.isAm
            ? AppTextStyles.amharicBody
            : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty) _buildArticle(c, text),
        if (threads != null && threads.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l.studyTakeaway,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            threads,
            style: style.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  /// Renders prose with the study-note hierarchy: short paragraphs, "• " bullet
  /// rows (U+2022), and labeled movement steps ("Step N — ", "ደረጃ N — ")
  /// rendered as numbered steps. Anything else renders as a plain paragraph,
  /// so the note always stays calm and readable.
  Widget _buildArticle(ThemePalette c, String text) {
    final style = (widget.isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    final blocks = _articleBlocks(text);
    if (blocks.length == 1 &&
        !blocks.single.isBullet &&
        !blocks.single.isStep) {
      return Text(blocks.single.text, style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(
                bottom: i == blocks.length - 1 ? 0 : 8),
            child: _buildArticleBlock(c, blocks[i], style),
          ),
      ],
    );
  }

  Widget _buildArticleBlock(
      ThemePalette c, _ArticleBlock block, TextStyle style) {
    if (block.isStep) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: c.primary, shape: BoxShape.circle),
            child: Text(
              '${block.stepNumber}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(block.text, style: style)),
        ],
      );
    }
    if (block.isBullet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 14,
            child: Text(
              '•',
              textAlign: TextAlign.center,
              style: style.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Text(block.text, style: style)),
        ],
      );
    }
    return Text(block.text, style: style);
  }

  /// Turns a section's prose into renderable blocks. Blank lines close steps
  /// and paragraphs; a step header opens a numbered step that gathers the lines
  /// until the next header or blank line; a "• " line is a bullet row. Only
  /// the validated [StudyFormat] markers are honored.
  List<_ArticleBlock> _articleBlocks(String text) {
    final out = <_ArticleBlock>[];
    final stepRe = StudyFormat.step(widget.isAm);
    var paragraph = <String>[];
    var openStep = false;
    var stepNumber = 0;
    var stepBody = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      final joined = paragraph.join(' ').trim();
      paragraph = [];
      if (joined.isEmpty) return;
      out.add(_ArticleBlock(joined));
    }

    void flushStep() {
      if (!openStep) return;
      final joined = stepBody.join(' ').trim();
      stepBody = [];
      openStep = false;
      if (joined.isEmpty) return;
      out.add(_ArticleBlock(joined, stepNumber: stepNumber));
    }

    for (final rawLine in text.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushParagraph();
        flushStep();
        continue;
      }
      final stepMatch = stepRe.firstMatch(line);
      if (stepMatch != null) {
        flushParagraph();
        flushStep();
        openStep = true;
        stepNumber = int.parse(stepMatch.group(1)!);
        final body = stepMatch.group(2)!.trim();
        if (body.isNotEmpty) stepBody.add(body);
        continue;
      }
      final bulletMatch = StudyFormat.bullet.firstMatch(line);
      if (bulletMatch != null) {
        final body = bulletMatch.group(1)!.trim();
        if (openStep) {
          stepBody.add(body);
        } else {
          flushParagraph();
          out.add(_ArticleBlock(body, isBullet: true));
        }
        continue;
      }
      if (openStep) {
        stepBody.add(line);
      } else {
        paragraph.add(line);
      }
    }
    flushParagraph();
    flushStep();
    return out;
  }

  /// The important-terms / original-language block: each word in its own
  /// script, its transliteration, and its meaning in the reader's language.
  Widget _buildTermsBlock(
      ThemePalette c, AppLocalizations l, List<StudyTerm> terms) {
    final meaningStyle = (widget.isAm
            ? AppTextStyles.amharicBody
            : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Text(
          l.studyKeyTerms,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: c.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        for (final term in terms) ...[
          Text.rich(
            TextSpan(
              text: term.term,
              style: AppTextStyles.labelLarge.copyWith(
                color: c.textPrimary,
                fontSize: 13,
              ),
              children: [
                if (term.transliteration != null &&
                    term.transliteration!.trim().isNotEmpty) ...[
                  TextSpan(
                    text: '  ${term.transliteration!.trim()}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(term.meaningFor(widget.isAm), style: meaningStyle),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildHistoryBody(
      ThemePalette c, AppLocalizations l, StudySection section) {
    final prose = section.textFor(widget.isAm);
    final inTheText = section.subTextFor(widget.isAm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prose.isNotEmpty) _buildArticle(c, prose),
        if (section.historyEntries.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final entry in section.historyEntries) ...[
            Text(
              '${_historyLabel(l, entry.label)} — ${_historyCategory(l, entry.category)}',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 4),
            _buildArticle(c, entry.textFor(widget.isAm)),
            const SizedBox(height: 10),
          ],
        ],
        if (inTheText != null) ...[
          const SizedBox(height: 10),
          Text(
            l.studyContextInText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          _buildArticle(c, inTheText),
        ],
      ],
    );
  }

  Widget _buildVerseByVerseBody(ThemePalette c, StudySection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final observation in section.verseObservations) ...[
          Text(
            _verseLabel(observation),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 4),
          _buildArticle(c, observation.textFor(widget.isAm)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  String _verseLabel(StudyVerseObservation observation) {
    if (observation.startVerse == observation.endVerse) {
      return widget.isAm
          ? 'ቁ. ${observation.startVerse}'
          : 'v. ${observation.startVerse}';
    }
    return widget.isAm
        ? 'ቁ. ${observation.startVerse}–${observation.endVerse}'
        : 'v. ${observation.startVerse}–${observation.endVerse}';
  }

  Widget _buildReferencesBody(ThemePalette c, StudySection section) {
    final refs = section.references;
    if (refs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ref in refs) ...[
          _ReferenceRow(
            label: ref.referenceFor(widget.isAm),
            reason: ref.reasonFor(widget.isAm),
            isAm: widget.isAm,
            onTap: () => _openReference(context, ref),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  /// Opens the in-sheet viewer for a cross-reference. The passage text always
  /// comes from the app's own Bible data — the AI only ever supplies the
  /// reference and its reason, never Scripture text.
  void _openReference(BuildContext context, StudyCrossReference ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      builder: (_) => _CrossReferenceViewer(reference: ref, isAm: widget.isAm),
    );
  }

  /// The "what can be understood" section: three labeled tiers that separate
  /// what the text clearly says from reasonable readings and genuine disputes.
  Widget _buildTieredBody(
      ThemePalette c, AppLocalizations l, StudySection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in section.blocks) ...[
          Text(
            _tierLabel(l, block.tier),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          _buildArticle(c, block.textFor(widget.isAm)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildAuthorityFooter(ThemePalette c, AppLocalizations l) {
    return Text(
      l.studyAuthorityFooter,
      textAlign: TextAlign.center,
      style: TextStyle(color: c.textMuted, fontSize: 11, height: 1.5),
    );
  }

  String _titleFor(AppLocalizations l, StudySectionKind kind) {
    switch (kind) {
      case StudySectionKind.passageOverview:
        return l.studySectionPassageOverview;
      case StudySectionKind.historicalBackground:
        return l.studySectionHistoricalBackground;
      case StudySectionKind.literaryContext:
        return l.studySectionLiteraryContext;
      case StudySectionKind.verseByVerse:
        return l.studySectionVerseByVerse;
      case StudySectionKind.originalLanguage:
        return l.studySectionOriginalLanguage;
      case StudySectionKind.scriptureInterconnections:
        return l.studySectionScriptureInterconnections;
      case StudySectionKind.explicitTeachings:
        return l.studySectionExplicitTeachings;
      case StudySectionKind.questionsToCarry:
        return l.studySectionQuestionsToCarry;
    }
  }

  String _historyLabel(AppLocalizations l, StudyHistoryLabel label) {
    switch (label) {
      case StudyHistoryLabel.author:
        return l.studyHistoryAuthor;
      case StudyHistoryLabel.audience:
        return l.studyHistoryAudience;
      case StudyHistoryLabel.date:
        return l.studyHistoryDate;
      case StudyHistoryLabel.place:
        return l.studyHistoryPlace;
      case StudyHistoryLabel.occasion:
        return l.studyHistoryOccasion;
      case StudyHistoryLabel.culturalSetting:
        return l.studyHistoryCulturalSetting;
    }
  }

  String _historyCategory(AppLocalizations l, StudyHistoryCategory category) {
    switch (category) {
      case StudyHistoryCategory.established:
        return l.studyHistoryEstablished;
      case StudyHistoryCategory.probable:
        return l.studyHistoryProbable;
      case StudyHistoryCategory.debated:
        return l.studyHistoryDebated;
    }
  }

  String _tierLabel(AppLocalizations l, StudyTier tier) {
    switch (tier) {
      case StudyTier.clearlyStated:
        return l.studyTierClearlyStated;
      case StudyTier.supportedUnderstanding:
        return l.studyTierSupportedUnderstanding;
      case StudyTier.disputed:
        return l.studyTierDisputed;
    }
  }
}

/// One rendered piece of a section's prose: a plain paragraph, a bullet row,
/// or a numbered movement step. Built by `_StudyPanelState._articleBlocks`.
class _ArticleBlock {
  final String text;
  final bool isBullet;
  final int? stepNumber;

  const _ArticleBlock(this.text, {this.isBullet = false, this.stepNumber});

  bool get isStep => stepNumber != null;
}

/// A single collapsible study section. The header shows the section title and
/// a chevron; tapping it expands or collapses the body. Everything is expanded
/// by default — collapsing is a reader convenience, never a way to hide
/// content.
class _StudySectionCard extends StatefulWidget {
  final String title;
  final bool isAm;
  final Widget child;

  const _StudySectionCard({
    required this.title,
    required this.isAm,
    required this.child,
  });

  @override
  State<_StudySectionCard> createState() => _StudySectionCardState();
}

class _StudySectionCardState extends State<_StudySectionCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: c.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Tooltip(
                  message: _expanded ? l.studyCollapseSection : l.studyExpandSection,
                  child: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          widget.child,
        ],
      ],
    );
  }
}

/// A single canonical cross-reference with its short reason. Tapping it opens
/// the in-sheet viewer that reads the actual passage from the app's Bible.
/// The panel never fabricates a reference — it is validated against the canon
/// before it renders.
class _ReferenceRow extends StatelessWidget {
  final String label;
  final String reason;
  final bool isAm;
  final VoidCallback onTap;

  const _ReferenceRow({
    required this.label,
    required this.reason,
    required this.isAm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.menu_book, size: 14, color: c.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(color: c.primary, fontSize: 12),
                  ),
                ),
                Icon(Icons.chevron_right, size: 16, color: c.textMuted),
              ]),
              if (reason.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: (isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium)
                      .copyWith(color: c.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// In-sheet viewer for a cross-referenced passage. Reads the chapter from the
/// app's own Bible data (offline bundle or cache) and renders only the verses
/// the reference covers. The AI never supplies verse text — only the reference
/// and its reason reach this viewer.
class _CrossReferenceViewer extends ConsumerWidget {
  final StudyCrossReference reference;
  final bool isAm;

  const _CrossReferenceViewer({required this.reference, required this.isAm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    final chapter = ref.watch(scriptureProvider((
      bookId: reference.bookId,
      chapter: reference.chapter,
      isAmharic: isAm,
    )));

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
            child: Row(children: [
              Icon(Icons.menu_book, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reference.referenceFor(isAm),
                  style: AppTextStyles.labelLarge.copyWith(color: c.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: c.textSecondary, size: 20),
                tooltip: l.studyCancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ]),
          ),
          Expanded(
            child: chapter.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
              error: (_, _) => _unavailable(c, l),
              data: (data) {
                if (data == null || data.isEmpty) return _unavailable(c, l);
                final verses = data.verses
                    .where((v) =>
                        v.number >= reference.startVerse &&
                        v.number <= reference.endVerse)
                    .toList();
                if (verses.isEmpty) return _unavailable(c, l);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
                  children: [
                    for (var i = 0; i < verses.length; i++)
                      Padding(
                        padding:
                            EdgeInsets.only(bottom: i == verses.length - 1 ? 0 : 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 28,
                              child: Text(
                                '${verses[i].number}',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: c.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                verses[i].text,
                                style: (isAm
                                        ? AppTextStyles.amharicBody
                                        : AppTextStyles.bodyMedium)
                                    .copyWith(color: c.textPrimary, height: 1.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _unavailable(ThemePalette c, AppLocalizations l) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l.studyReferenceUnavailable,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}

/// The calm "free AI sessions used" card shown above the study note when the
/// app's daily allowance is exhausted. Plainly distinguishes the two options —
/// Offline Study (still available) vs. a personal Gemini API key (AI continues)
/// — without guilt, pressure, or gamification.
class _LimitBanner extends ConsumerWidget {
  final bool isAm;
  final VoidCallback onContinueOffline;
  final VoidCallback onAddKey;

  const _LimitBanner({
    required this.isAm,
    required this.onContinueOffline,
    required this.onAddKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_stories_outlined, size: 16, color: c.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l.studyLimitTitle,
                style: AppTextStyles.labelLarge.copyWith(
                    color: c.primary, fontSize: 13),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            l.studyLimitBody,
            style: (isAm
                    ? AppTextStyles.amharicBody
                    : AppTextStyles.bodySmall)
                .copyWith(color: c.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onContinueOffline,
                  child: Text(l.studyLimitOffline,
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onAddKey,
                  child: Text(l.studyLimitAddKey,
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The calm "AI study is unavailable — reason" card shown above the offline
/// note whenever a study failed for any reason other than the daily cap. This
/// is the non-silent fallback: the reader is always told *why* AI was
/// unavailable and can continue with the clearly-labeled offline note, or add
/// their own Gemini key when that would help.
class _UnavailableBanner extends ConsumerWidget {
  final bool isAm;
  final StudyUnavailability reason;
  final VoidCallback onContinueOffline;
  final VoidCallback onAddKey;

  const _UnavailableBanner({
    required this.isAm,
    required this.reason,
    required this.onContinueOffline,
    required this.onAddKey,
  });

  /// Whether a personal Gemini key could plausibly resolve this failure.
  static bool _keyWouldHelp(StudyUnavailability reason) =>
      reason == StudyUnavailability.rateLimited ||
      reason == StudyUnavailability.authInvalid ||
      reason == StudyUnavailability.server ||
      reason == StudyUnavailability.timeout ||
      reason == StudyUnavailability.contentRejected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    final text = _reasonText(l, reason);
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.info_outline, size: 16, color: c.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l.studyUnavailableTitle,
                style: AppTextStyles.labelLarge.copyWith(
                    color: c.textPrimary, fontSize: 13),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(
            text,
            style: (isAm
                    ? AppTextStyles.amharicBody
                    : AppTextStyles.bodySmall)
                .copyWith(color: c.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onContinueOffline,
                  child: Text(l.studyLimitOffline,
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
              if (_keyWouldHelp(reason)) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onAddKey,
                    child: Text(l.studyLimitAddKey,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _reasonText(AppLocalizations l, StudyUnavailability reason) {
    switch (reason) {
      case StudyUnavailability.offline:
        return l.studyReasonOffline;
      case StudyUnavailability.rateLimited:
        return l.studyReasonRateLimited;
      case StudyUnavailability.timeout:
        return l.studyReasonTimeout;
      case StudyUnavailability.authInvalid:
        return l.studyReasonAuthInvalid;
      case StudyUnavailability.server:
        return l.studyReasonServer;
      case StudyUnavailability.contentRejected:
        return l.studyReasonContentRejected;
      case StudyUnavailability.none:
      case StudyUnavailability.capped:
        return l.studyUnavailableTitle;
    }
  }
}
