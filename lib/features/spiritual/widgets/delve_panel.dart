import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/delve/delve_models.dart';
import '../../../core/ai/delve/delve_provider.dart';
import '../../../core/ai/study/study_models.dart';
import '../../../core/ai/study/study_provider.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../core/providers/scripture_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/settings/widgets/gemini_key_dialog.dart';
import '../../../l10n/app_localizations.dart';

/// The "Delve Deeper" sheet: a separate, on-demand second pass over the same
/// passage. It runs only when the reader asks for it, keeps its own cache and
/// its own daily allowance, and renders six fixed blocks — expanded historical
/// background, literary analysis, original-language analysis, expanded
/// cross-references, documented interpretations, and structured observations.
///
/// The Study workbook is never changed by this panel: it is a sibling sheet
/// opened from the small action at the very bottom of the study note.
class DelvePanel extends ConsumerStatefulWidget {
  final DelveRequest request;

  const DelvePanel({super.key, required this.request});

  @override
  ConsumerState<DelvePanel> createState() => _DelvePanelState();
}

class _DelvePanelState extends ConsumerState<DelvePanel> {
  late Future<DelveResult> _future;

  /// Kept so a returned sheet that was scrolled keeps its scroll position.
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<DelveResult> _load({bool force = false, bool bypassDisk = false}) async {
    final service = await ref.read(delveServiceProvider.future);
    final genre = widget.request.genre ??
        ref
            .read(studyIntroLibraryProvider)
            .valueOrNull
            ?.introFor(widget.request.reference.bookId)
            ?.genre;
    final request = genre == null
        ? widget.request
        : DelveRequest(
            reference: widget.request.reference,
            isAmharic: widget.request.isAmharic,
            verseTexts: widget.request.verseTexts,
            genre: genre,
          );
    return force
        ? service.refresh(request, bypassDisk: bypassDisk)
        : service.delve(request);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
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
              Icon(Icons.manage_search, size: 18, color: c.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.request.reference.referenceFor(widget.request.isAmharic),
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
            child: FutureBuilder<DelveResult>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return _buildLoading(c, l);
                }
                final result = snapshot.data;
                if (result == null) {
                  return _buildUnavailable(c, l, DelveUnavailability.server);
                }
                developer.log(
                    'delve: panel render: sections=${result.sections.length} '
                    'isAvailable=${result.isAvailable} '
                    'unavail=${result.unavailability.name} '
                    'limitReached=${result.limitReached}',
                    name: 'delve');
                if (result.limitReached ||
                    result.unavailability == DelveUnavailability.capped) {
                  return _buildLimit(c, l);
                }
                if (!result.isAvailable ||
                    result.unavailability != DelveUnavailability.none) {
                  return _buildUnavailable(c, l, result.unavailability);
                }
                return _buildContent(c, l, result);
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
          l.delveLoading,
          style: TextStyle(color: c.textSecondary, fontSize: 13),
        ),
      ]),
    );
  }

  /// The "free deep-study sessions used" state: a calm explanation with the
  /// choice to add a personal Gemini key (which continues in place).
  Widget _buildLimit(ThemePalette c, AppLocalizations l) {
    final hasKey = ref.read(userKeyPresentProvider).valueOrNull ?? false;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.auto_stories_outlined, size: 40,
                color: c.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.delveLimitTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(color: c.primary),
            ),
            const SizedBox(height: 8),
            Text(
              l.delveLimitBody,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!hasKey)
              FilledButton(
                onPressed: _addApiKeyAndRetry,
                child: Text(l.studyLimitAddKey),
              ),
          ],
        ),
      ),
    );
  }

  /// The calm "deeper study is unavailable — reason" state. The reason is
  /// always shown; when a personal key would help, the reader can add one and
  /// the deep study continues in place.
  Widget _buildUnavailable(
      ThemePalette c, AppLocalizations l, DelveUnavailability reason) {
    final hasKey = ref.read(userKeyPresentProvider).valueOrNull ?? false;
    final showAddKey = !hasKey && _keyWouldHelp(reason);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.info_outline, size: 40,
                color: c.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l.delveUnavailableTitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelLarge.copyWith(color: c.primary),
            ),
            const SizedBox(height: 8),
            Text(
              _reasonText(l, reason),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            if (showAddKey)
              FilledButton(
                onPressed: _addApiKeyAndRetry,
                child: Text(l.studyLimitAddKey),
              ),
          ],
        ),
      ),
    );
  }

  static bool _keyWouldHelp(DelveUnavailability reason) =>
      reason == DelveUnavailability.rateLimited ||
      reason == DelveUnavailability.authInvalid ||
      reason == DelveUnavailability.server ||
      reason == DelveUnavailability.timeout;

  static String _reasonText(AppLocalizations l, DelveUnavailability reason) {
    switch (reason) {
      case DelveUnavailability.offline:
        return l.studyReasonOffline;
      case DelveUnavailability.rateLimited:
        return l.studyReasonRateLimited;
      case DelveUnavailability.timeout:
        return l.studyReasonTimeout;
      case DelveUnavailability.authInvalid:
        return l.studyReasonAuthInvalid;
      case DelveUnavailability.server:
        return l.studyReasonServer;
      case DelveUnavailability.contentRejected:
        return l.studyReasonContentRejected;
      case DelveUnavailability.capped:
      case DelveUnavailability.none:
        return l.delveUnavailableTitle;
    }
  }

  Future<void> _addApiKeyAndRetry() async {
    final action = await showGeminiKeyDialog(context);
    if (!mounted) return;
    if (action == 'saved') {
      setState(() => _future = _load(force: true, bypassDisk: true));
    }
  }

  /// The canonical order of the deep study's six blocks. Whatever order the
  /// backend returned, the panel always renders in this fixed order.
  static const List<DelveSectionKind> _canonicalOrder = [
    DelveSectionKind.expandedHistory,
    DelveSectionKind.literaryAnalysis,
    DelveSectionKind.originalLanguage,
    DelveSectionKind.expandedCrossReferences,
    DelveSectionKind.documentedInterpretations,
    DelveSectionKind.structuredObservations,
  ];

  Widget _buildContent(ThemePalette c, AppLocalizations l, DelveResult result) {
    final byKind = <DelveSectionKind, DelveSection>{
      for (final s in result.sections) s.kind: s,
    };
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      children: [
        _buildPassage(c),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: _buildSourcePill(c, l),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final kind in _canonicalOrder) ...[
          if (byKind[kind] case final section?) ...[
            _DelveSectionCard(
              title: _titleFor(l, kind),
              isAm: widget.request.isAmharic,
              child: _buildSectionBody(c, l, section),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
        _buildAuthorityFooter(c, l),
        const SizedBox(height: AppSpacing.lg),
      ],
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
                      style: (widget.request.isAmharic
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

  Widget _buildSourcePill(ThemePalette c, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 12, color: c.textMuted),
          const SizedBox(width: 5),
          Text(
            l.delveSourceLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: c.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionBody(
      ThemePalette c, AppLocalizations l, DelveSection section) {
    switch (section.kind) {
      case DelveSectionKind.expandedHistory:
        return _buildHistoryBody(c, l, section);
      case DelveSectionKind.originalLanguage:
        return _buildLanguageBody(c, l, section);
      case DelveSectionKind.expandedCrossReferences:
        return _buildReferencesBody(c, section);
      case DelveSectionKind.documentedInterpretations:
        return _buildInterpretationsBody(c, l, section);
      case DelveSectionKind.structuredObservations:
        return _buildObservationsBody(c, section);
      case DelveSectionKind.literaryAnalysis:
        return _buildArticle(c, section.textFor(widget.request.isAmharic));
    }
  }

  Widget _buildHistoryBody(
      ThemePalette c, AppLocalizations l, DelveSection section) {
    final prose = section.textFor(widget.request.isAmharic);
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
            _buildArticle(c, entry.textFor(widget.request.isAmharic)),
            const SizedBox(height: 10),
          ],
        ],
      ],
    );
  }

  Widget _buildLanguageBody(
      ThemePalette c, AppLocalizations l, DelveSection section) {
    final prose = section.textFor(widget.request.isAmharic);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (prose.isNotEmpty) _buildArticle(c, prose),
        if (section.terms.isNotEmpty) ...[
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
          for (final term in section.terms) ...[
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
            Text(
              term.meaningFor(widget.request.isAmharic),
              style: (widget.request.isAmharic
                      ? AppTextStyles.amharicBody
                      : AppTextStyles.bodyMedium)
                  .copyWith(color: c.textPrimary, height: 1.6),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }

  Widget _buildReferencesBody(ThemePalette c, DelveSection section) {
    final refs = section.references;
    if (refs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ref in refs) ...[
          _DelveReferenceRow(
            label: ref.referenceFor(widget.request.isAmharic),
            reason: ref.reasonFor(widget.request.isAmharic),
            isAm: widget.request.isAmharic,
            onTap: () => _openReference(context, ref),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _openReference(BuildContext context, StudyCrossReference ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      ),
      builder: (_) => _DelveReferenceViewer(
          reference: ref, isAm: widget.request.isAmharic),
    );
  }

  Widget _buildInterpretationsBody(
      ThemePalette c, AppLocalizations l, DelveSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final interpretation in section.interpretations) ...[
          Text(
            _tierLabel(l, interpretation.tier),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          _buildArticle(c, interpretation.textFor(widget.request.isAmharic)),
          if (interpretation.attributionFor(widget.request.isAmharic)
              case final attribution?) ...[
            const SizedBox(height: 4),
            Text(
              '${l.delveInterpretationAttribution} $attribution',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: c.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildObservationsBody(ThemePalette c, DelveSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final observation in section.observations) ...[
          Text(
            _verseLabel(observation, widget.request.isAmharic),
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: c.primary,
            ),
          ),
          const SizedBox(height: 4),
          _buildArticle(c, observation.textFor(widget.request.isAmharic)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  static String _verseLabel(DelveObservation observation, bool isAm) {
    if (observation.startVerse == observation.endVerse) {
      return isAm
          ? 'ቁ. ${observation.startVerse}'
          : 'v. ${observation.startVerse}';
    }
    return isAm
        ? 'ቁ. ${observation.startVerse}–${observation.endVerse}'
        : 'v. ${observation.startVerse}–${observation.endVerse}';
  }

  /// Renders prose with the study-note hierarchy (short paragraphs, "• "
  /// bullets, and "Step N — " / "ደረጃ N — " movement steps).
  Widget _buildArticle(ThemePalette c, String text) {
    final style = (widget.request.isAmharic
            ? AppTextStyles.amharicBody
            : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    final blocks = _articleBlocks(text);
    if (blocks.length == 1 && !blocks.single.isBullet && !blocks.single.isStep) {
      return Text(blocks.single.text, style: style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < blocks.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == blocks.length - 1 ? 0 : 8),
            child: _buildArticleBlock(c, blocks[i], style),
          ),
      ],
    );
  }

  Widget _buildArticleBlock(
      ThemePalette c, _DelveArticleBlock block, TextStyle style) {
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

  List<_DelveArticleBlock> _articleBlocks(String text) {
    final isAm = widget.request.isAmharic;
    final out = <_DelveArticleBlock>[];
    final stepRe = StudyFormat.step(isAm);
    var paragraph = <String>[];
    var openStep = false;
    var stepNumber = 0;
    var stepBody = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      final joined = paragraph.join(' ').trim();
      paragraph = [];
      if (joined.isEmpty) return;
      out.add(_DelveArticleBlock(joined));
    }

    void flushStep() {
      if (!openStep) return;
      final joined = stepBody.join(' ').trim();
      stepBody = [];
      openStep = false;
      if (joined.isEmpty) return;
      out.add(_DelveArticleBlock(joined, stepNumber: stepNumber));
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
          out.add(_DelveArticleBlock(body, isBullet: true));
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

  Widget _buildAuthorityFooter(ThemePalette c, AppLocalizations l) {
    return Text(
      l.studyAuthorityFooter,
      textAlign: TextAlign.center,
      style: TextStyle(color: c.textMuted, fontSize: 11, height: 1.5),
    );
  }

  static String _titleFor(AppLocalizations l, DelveSectionKind kind) {
    switch (kind) {
      case DelveSectionKind.expandedHistory:
        return l.delveSectionHistory;
      case DelveSectionKind.literaryAnalysis:
        return l.delveSectionLiterary;
      case DelveSectionKind.originalLanguage:
        return l.delveSectionLanguage;
      case DelveSectionKind.expandedCrossReferences:
        return l.delveSectionCrossRefs;
      case DelveSectionKind.documentedInterpretations:
        return l.delveSectionInterpretations;
      case DelveSectionKind.structuredObservations:
        return l.delveSectionObservations;
    }
  }

  static String _historyLabel(AppLocalizations l, StudyHistoryLabel label) {
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

  static String _historyCategory(
      AppLocalizations l, StudyHistoryCategory category) {
    switch (category) {
      case StudyHistoryCategory.established:
        return l.studyHistoryEstablished;
      case StudyHistoryCategory.probable:
        return l.studyHistoryProbable;
      case StudyHistoryCategory.debated:
        return l.studyHistoryDebated;
    }
  }

  static String _tierLabel(AppLocalizations l, StudyTier tier) {
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

/// One rendered piece of deep-study prose.
class _DelveArticleBlock {
  final String text;
  final bool isBullet;
  final int? stepNumber;

  const _DelveArticleBlock(this.text, {this.isBullet = false, this.stepNumber});

  bool get isStep => stepNumber != null;
}

/// A single collapsible deep-study block.
class _DelveSectionCard extends StatefulWidget {
  final String title;
  final bool isAm;
  final Widget child;

  const _DelveSectionCard({
    required this.title,
    required this.isAm,
    required this.child,
  });

  @override
  State<_DelveSectionCard> createState() => _DelveSectionCardState();
}

class _DelveSectionCardState extends State<_DelveSectionCard> {
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
                  message:
                      _expanded ? l.studyCollapseSection : l.studyExpandSection,
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
/// the in-sheet viewer that reads the passage from the app's Bible.
class _DelveReferenceRow extends StatelessWidget {
  final String label;
  final String reason;
  final bool isAm;
  final VoidCallback onTap;

  const _DelveReferenceRow({
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

/// In-sheet viewer for a deep-study cross-referenced passage. Reads the text
/// from the app's own Bible data; the AI never supplies verse text.
class _DelveReferenceViewer extends ConsumerWidget {
  final StudyCrossReference reference;
  final bool isAm;

  const _DelveReferenceViewer({required this.reference, required this.isAm});

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