import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/audio_bible_service.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/providers/audio_player_provider.dart';
import '../../../core/providers/reading_preferences_provider.dart';
import 'journal_sheet.dart';

class VerseActionSheet extends ConsumerWidget {
  final String bookId;
  final int chapter;
  final int verseNumber;
  final String text;
  final String reference;
  final bool isAm;
  final int verseIndex;

  const VerseActionSheet({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verseNumber,
    required this.text,
    required this.reference,
    required this.isAm,
    required this.verseIndex,
  });

  void _toggleHighlight(WidgetRef ref, String colorId) {
    final current = ref.read(highlightsProvider);
    final idx = current.indexWhere((h) =>
        h.bookId == bookId && h.chapter == chapter && h.verse == verseNumber);
    final next = List<HighlightedVerse>.of(current);
    if (colorId.isEmpty) {
      if (idx >= 0) next.removeAt(idx);
    } else {
      final entry = HighlightedVerse(
        bookId: bookId,
        chapter: chapter,
        verse: verseNumber,
        text: text,
        isAm: isAm,
        colorId: colorId,
      );
      if (idx >= 0) {
        next[idx] = entry;
      } else {
        next.insert(0, entry);
      }
    }
    ref.read(highlightsProvider.notifier).state = next;
    ReadingPreferences.saveAllHighlights(next);
  }

  void _copy(BuildContext context, WidgetRef ref, {required bool withReference}) {
    final data = withReference ? '$text ($reference)' : text;
    Clipboard.setData(ClipboardData(text: data));
    final c = AppColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(isAm ? 'ተገልብጧል' : 'Copied'),
      backgroundColor: c.success,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  void _share() {
    SharePlus.instance.share(ShareParams(text: '$text ($reference)', subject: reference));
  }

  Future<void> _playFromHere(WidgetRef ref, BuildContext context) async {
    final notifier = ref.read(audioPlayerProvider.notifier);
    final state = ref.read(audioPlayerProvider);
    if (state.chapter != null &&
        state.verseTexts.isNotEmpty &&
        state.chapter!.bookId == bookId &&
        state.chapter!.chapter == chapter &&
        state.chapter!.isAmharic == isAm) {
      await notifier.seekToVerse(verseIndex);
    } else {
      final book = ScriptureService.bookMap[bookId];
      await notifier.play(AudioChapterInfo(
        bookId: bookId,
        chapter: chapter,
        reference: '${book?.nameEn ?? bookId} $chapter',
        bookName: book?.nameEn ?? bookId,
        isAmharic: isAm,
      ));
      await notifier.seekToVerse(verseIndex);
    }
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final highlights = ref.watch(highlightsProvider);
    final currentColor = highlights
        .firstWhere(
          (h) => h.bookId == bookId && h.chapter == chapter && h.verse == verseNumber,
          orElse: () => HighlightedVerse(
            bookId: bookId, chapter: chapter, verse: verseNumber, text: text, isAm: isAm),
        )
        .colorId;

    return Container(
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(reference, style: AppTextStyles.labelLarge.copyWith(color: c.primary)),
            const SizedBox(height: 8),
            Text(
              text,
              style: (isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium)
                  .copyWith(color: c.textPrimary, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              isAm ? 'ማጉላት' : 'Highlight',
              style: TextStyle(fontSize: 11, color: c.textMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final h in highlightColors)
                  _swatch(context, ref, h.id, h.color, currentColor == h.id),
                _swatch(context, ref, '', Colors.transparent, currentColor == '',
                    clear: true),
              ],
            ),
            const SizedBox(height: 20),
            Row(children: [
              _action(context, ref, Icons.copy, isAm ? 'ቅዳ' : 'Copy',
                  () => _copy(context, ref, withReference: false)),
              const SizedBox(width: AppSpacing.sm),
              _action(context, ref, Icons.link, isAm ? 'ከማጣቀሻ' : 'Copy + ref',
                  () => _copy(context, ref, withReference: true)),
              const SizedBox(width: AppSpacing.sm),
              _action(context, ref, Icons.share, isAm ? 'አጋራ' : 'Share', _share),
              const SizedBox(width: AppSpacing.sm),
              _action(context, ref, Icons.play_arrow, isAm ? 'አጫውት' : 'Play',
                  () => _playFromHere(ref, context)),
              const SizedBox(width: AppSpacing.sm),
              _action(context, ref, Icons.edit_outlined, isAm ? 'ጻፍ' : 'Write',
                  () => _openJournal(context)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _swatch(BuildContext context, WidgetRef ref, String id, Color color,
      bool selected, {bool clear = false}) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => _toggleHighlight(ref, id),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: clear ? Colors.transparent : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? c.textPrimary
                : clear
                    ? c.border
                    : Colors.transparent,
            width: selected ? 2.5 : 1.5,
          ),
        ),
        child: clear
            ? Icon(Icons.close, size: 14, color: c.textMuted)
            : null,
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, IconData icon, String label,
      VoidCallback onTap) {
    final c = AppColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: c.textPrimary),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(fontSize: 10, color: c.textSecondary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _openJournal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      sheetAnimationStyle: AnimationStyle(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
      builder: (_) => JournalSheet(
        reference: reference,
        verseText: text,
        verseId: '${bookId}_$verseNumber',
      ),
    );
  }
}
