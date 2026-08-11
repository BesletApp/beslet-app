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
    return service.study(widget.request);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      children: [
        _buildPassage(c),
        const SizedBox(height: AppSpacing.lg),
        for (final section in result.sections.where((s) => !s.isEmpty)) ...[
          _buildSection(c, l, section),
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

  Widget _buildSection(ThemePalette c, AppLocalizations l, StudySection section) {
    if (section.kind == StudySectionKind.context) {
      return _buildContextSection(c, l, section);
    }
    if (section.kind == StudySectionKind.biblicalConnections) {
      return _buildReferenceSection(c, section);
    }
    if (section.kind == StudySectionKind.whatCanBeUnderstood) {
      return _buildTieredSection(c, l, section);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titleFor(l, section.kind),
          style: AppTextStyles.labelLarge.copyWith(
            color: c.primary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          section.textFor(widget.isAm),
          style: (widget.isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium)
              .copyWith(color: c.textPrimary, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildContextSection(
      ThemePalette c, AppLocalizations l, StudySection section) {
    final body = (widget.isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    final behind = section.textFor(widget.isAm);
    final inText = section.subTextFor(widget.isAm);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titleFor(l, section.kind),
          style: AppTextStyles.labelLarge.copyWith(
            color: c.primary,
            fontSize: 13,
          ),
        ),
        if (behind.isNotEmpty) ...[
          const SizedBox(height: 6),
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
          Text(behind, style: body),
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
          Text(inText, style: body),
        ],
      ],
    );
  }

  Widget _buildReferenceSection(ThemePalette c, StudySection section) {
    final refs = section.references;
    if (refs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titleFor(AppLocalizations.of(context)!, section.kind),
          style: AppTextStyles.labelLarge.copyWith(
            color: c.primary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
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
  Widget _buildTieredSection(
      ThemePalette c, AppLocalizations l, StudySection section) {
    final body = (widget.isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium)
        .copyWith(color: c.textPrimary, height: 1.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titleFor(l, section.kind),
          style: AppTextStyles.labelLarge.copyWith(
            color: c.primary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
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
          Text(block.textFor(widget.isAm), style: body),
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
