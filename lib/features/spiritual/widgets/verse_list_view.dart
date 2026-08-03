import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/scripture_provider.dart';
import '../../../core/providers/reading_preferences_provider.dart';

class VerseListView extends ConsumerWidget {
  final ScriptureChapter? chapter;
  final int? currentVerseIndex;
  final bool isAm;
  final void Function(ScriptureVerse verse, int verseIndex)? onVerseTap;
  final Map<int, String> highlightedVerseColors;

  const VerseListView({
    super.key,
    this.chapter,
    this.currentVerseIndex,
    this.isAm = false,
    this.onVerseTap,
    this.highlightedVerseColors = const {},
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter = this.chapter;
    final c = AppColors.of(context);
    final isAm = this.isAm;
    final fontSize = ref.watch(fontSizeProvider);
    final lineSpacing = ref.watch(lineSpacingProvider);

    if (chapter == null || chapter.verses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined, size: 32, color: c.textMuted.withValues(alpha: 0.4)),
            SizedBox(height: AppSpacing.sm),
            Text(
              isAm ? 'ምዕራፉን በመጫን ላይ...' : 'Loading chapter...',
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary.withValues(alpha: 0.4)),
            ),
          ],
        ),
      );
    }

    final verses = chapter.verses;
    final current = currentVerseIndex;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: verses.length,
      itemBuilder: (context, index) {
        final verse = verses[index];
        final isCurrent = current != null && index == current;
        final colorId = highlightedVerseColors[verse.number];
        final highlightColor = colorId != null ? highlightColorFor(colorId) : null;

        return InkWell(
          onTap: onVerseTap != null ? () => onVerseTap!(verse, index) : null,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            margin: EdgeInsets.only(top: index > 0 && (index % 10 == 0) ? AppSpacing.sm : 0),
            decoration: BoxDecoration(
              color: highlightColor != null
                  ? highlightColor.withValues(alpha: 0.18)
                  : isCurrent
                      ? AppColors.audioBlue.withValues(alpha: 0.08)
                      : null,
              border: Border(
                left: highlightColor != null
                    ? BorderSide(color: highlightColor, width: 3)
                    : BorderSide.none,
                bottom: isCurrent
                    ? const BorderSide(color: AppColors.audioBlue, width: 2)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${verse.number}',
                    style: TextStyle(
                      fontFamily: 'Inter', fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: highlightColor ?? c.textPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    verse.text,
                    style: (isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium).copyWith(
                      fontSize: fontSize,
                      height: isAm ? lineSpacing + 0.1 : lineSpacing,
                      color: isCurrent
                          ? c.textPrimary
                          : c.textPrimary.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
