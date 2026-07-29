import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/scripture_provider.dart';
import '../../../core/providers/reading_preferences_provider.dart';

class VerseListView extends ConsumerStatefulWidget {
  final ScriptureChapter? chapter;
  final int? currentVerseIndex;
  final bool isAm;
  final void Function(int verseIndex)? onVerseTap;
  final Widget? trailing;
  final int? pendingKeepIndex;
  final int? keptVerseIndex;
  final ValueChanged<int?>? onKeepPendingChanged;
  final void Function(int verseNumber, String text)? onKeepConfirmed;
  final void Function(int verseNumber, String text)? onReflectionRequested;
  final ValueChanged<bool>? onReflectionAvailable;

  const VerseListView({
    super.key,
    this.chapter,
    this.currentVerseIndex,
    this.isAm = false,
    this.onVerseTap,
    this.trailing,
    this.pendingKeepIndex,
    this.keptVerseIndex,
    this.onKeepPendingChanged,
    this.onKeepConfirmed,
    this.onReflectionRequested,
    this.onReflectionAvailable,
  });

  @override
  ConsumerState<VerseListView> createState() => _VerseListViewState();
}

class _VerseListViewState extends ConsumerState<VerseListView> {
  final _itemKeys = <int, GlobalKey>{};
  int? _focusedVerse;
  Timer? _longPressTimer;
  bool _showReflectionPrompt = false;

  @override
  void didUpdateWidget(VerseListView old) {
    super.didUpdateWidget(old);
    if (widget.pendingKeepIndex != old.pendingKeepIndex) {
      _longPressTimer?.cancel();
      if (_showReflectionPrompt) {
        setState(() => _showReflectionPrompt = false);
        widget.onReflectionAvailable?.call(false);
      }
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final c = AppColors.of(context);
    final isAm = widget.isAm;
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
    final current = widget.currentVerseIndex;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: verses.length + (widget.trailing != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (widget.trailing != null && index == verses.length) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: widget.trailing,
          );
        }

        final verse = verses[index];
        final isCurrent = current != null && index == current;
        final isFocused = _focusedVerse == index && !isCurrent;
        final isPending = widget.pendingKeepIndex == index;
        final isKept = widget.keptVerseIndex == index;

        final itemKey = _itemKeys.putIfAbsent(index, () => GlobalKey());
        return Container(
          key: itemKey,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          margin: EdgeInsets.only(top: index > 0 && (index % 10 == 0) ? AppSpacing.sm : 0),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.audioBlue.withValues(alpha: 0.08)
                : isKept
                    ? c.primary.withValues(alpha: 0.1)
                    : isPending
                        ? c.primary.withValues(alpha: 0.04)
                        : null,
          ),
          child: GestureDetector(
            onLongPress: () {
              widget.onKeepPendingChanged?.call(index);
              _longPressTimer?.cancel();
              _longPressTimer = Timer(const Duration(milliseconds: 500), () {
                if (!mounted) return;
                setState(() => _showReflectionPrompt = true);
                widget.onReflectionAvailable?.call(true);
              });
            },
            onTap: () {
              if (widget.pendingKeepIndex == index) {
                _longPressTimer?.cancel();
                if (_showReflectionPrompt) {
                  setState(() => _showReflectionPrompt = false);
                  widget.onReflectionAvailable?.call(false);
                  widget.onReflectionRequested?.call(verse.number, verse.text);
                } else {
                  widget.onKeepConfirmed?.call(verse.number, verse.text);
                }
                return;
              }
              setState(() {
                _focusedVerse = _focusedVerse == index ? null : index;
              });
              widget.onVerseTap?.call(index);
            },
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
                      color: c.textPrimary.withValues(alpha: 0.6),
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
                      color: isFocused || isCurrent
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
