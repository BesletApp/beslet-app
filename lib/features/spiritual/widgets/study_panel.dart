import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/study/study_models.dart';
import '../../../core/ai/study/study_provider.dart';
import '../../../core/ai/study/study_sources.dart';
import '../../../core/providers/scripture_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<StudyResult> _load() async {
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
    return service.study(request);
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
                if (result == null || !result.isAvailable) {
                  return _buildOffline(c, l);
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

  Widget _buildContent(ThemePalette c, AppLocalizations l, StudyResult result,
      StudySourceRegistry? sources) {
    final sections = _canonicalSections(result);
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      children: [
        _buildPassage(c),
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

  /// The panel's canonical 8-step scaffold: the passage is step one, then the
  /// seven sections in the order the app guarantees. Whatever order the
  /// backend returned, the panel always renders the sections in this fixed
  /// order — a backend that misorders a note cannot scramble the reader's path
  /// through it.
  static const List<StudySectionKind> _canonicalSectionOrder = [
    StudySectionKind.setting,
    StudySectionKind.context,
    StudySectionKind.whatTextSays,
    StudySectionKind.meaningBackground,
    StudySectionKind.biblicalConnections,
    StudySectionKind.whatCanBeUnderstood,
    StudySectionKind.reflection,
  ];

  /// Merges the backend's sections with the panel's own canonical order and
  /// with the offline cross-reference index, then drops empty sections.
  ///
  /// The canonical merge is done here, panel-side, so the reader sees one
  /// stable note regardless of which backend produced it: the offline index's
  /// validated connections are folded into `biblicalConnections` whenever they
  /// add something the backend did not already supply, and everything renders
  /// in the app's canonical sequence. Empty sections preserve silence — no
  /// section is padded to fit a slot.
  List<StudySection> _canonicalSections(StudyResult result) {
    final byKind = <StudySectionKind, StudySection>{
      for (final s in result.sections) s.kind: s,
    };
    final scaffold = <StudySection>[];
    for (final kind in _canonicalSectionOrder) {
      if (kind == StudySectionKind.biblicalConnections) {
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
      kind: StudySectionKind.biblicalConnections,
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

  /// The body of a section, without its title (the collapsible card supplies
  /// the title). Long prose is split into short paragraphs for breathing room.
  Widget _buildSectionBody(
      ThemePalette c, AppLocalizations l, StudySection section) {
    if (section.kind == StudySectionKind.context) {
      return _buildContextBody(c, l, section);
    }
    if (section.kind == StudySectionKind.biblicalConnections) {
      return _buildReferencesBody(c, section);
    }
    if (section.kind == StudySectionKind.whatCanBeUnderstood) {
      return _buildTieredBody(c, l, section);
    }
    if (section.kind == StudySectionKind.reflection) {
      return _buildReflectionBody(c, l, section);
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

  /// The reflection: one or two open questions, then — when the note carries
  /// one — the quiet "the passage itself says" line that anchors what was read.
  /// Both are observations; neither ever tells the reader what to do.
  Widget _buildReflectionBody(
      ThemePalette c, AppLocalizations l, StudySection section) {
    final text = section.textFor(widget.isAm);
    final takeaway = section.takeawayFor(widget.isAm);
    final style = (widget.isAm
            ? AppTextStyles.amharicBody
            : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (text.isNotEmpty) _buildArticle(c, text),
        if (takeaway != null && takeaway.isNotEmpty) ...[
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
            takeaway,
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

  Widget _buildContextBody(
      ThemePalette c, AppLocalizations l, StudySection section) {
    final behind = section.textFor(widget.isAm);
    final inText = section.subTextFor(widget.isAm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (behind.isNotEmpty) ...[
          Text(
            l.studyContextBehind,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          _buildArticle(c, behind),
        ],
        if (inText != null) ...[
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
          _buildArticle(c, inText),
        ],
      ],
    );
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
      case StudySectionKind.setting:
        return l.studySectionSetting;
      case StudySectionKind.context:
        return l.studySectionContext;
      case StudySectionKind.whatTextSays:
        return l.studySectionWhatTextSays;
      case StudySectionKind.meaningBackground:
        return l.studySectionMeaningBackground;
      case StudySectionKind.biblicalConnections:
        return l.studySectionBiblicalConnections;
      case StudySectionKind.whatCanBeUnderstood:
        return l.studySectionWhatCanBeUnderstood;
      case StudySectionKind.reflection:
        return l.studySectionReflection;
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
