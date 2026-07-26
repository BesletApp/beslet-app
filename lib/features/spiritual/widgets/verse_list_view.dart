import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/audio_player_provider.dart';
import '../../../core/services/audio_bible_service.dart';

class VerseListView extends ConsumerStatefulWidget {
  final bool isAm;

  const VerseListView({super.key, this.isAm = false});

  @override
  ConsumerState<VerseListView> createState() => _VerseListViewState();
}

class _VerseListViewState extends ConsumerState<VerseListView> {
  final _itemKeys = <int, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final verses = playerState.verseTexts;
    final numbers = playerState.verseNumbers;
    final c = AppColors.of(context);
    final isAm = widget.isAm;

    if (verses.isEmpty) {
      if (playerState.state == AudioState.error) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(children: [
            Icon(Icons.wifi_off, size: 32, color: c.textMuted.withValues(alpha: 0.4)),
            SizedBox(height: AppSpacing.sm),
            Text(
              isAm ? 'በይነመረብ አልተገኘም' : 'No internet connection',
              style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              isAm ? 'እባክዎ ይገናኙና እንደገና ይሞክሩ' : 'Please connect and try again',
              style: AppTextStyles.bodySmall.copyWith(color: c.textMuted),
            ),
          ]),
        );
      }
      return const SizedBox.shrink();
    }

    final current = playerState.currentVerse;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (current < verses.length) {
        final ctx = _itemKeys[current]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut, alignment: 0.1);
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
            child: Text(
              playerState.chapter?.reference ?? '',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary),
            ),
          ),
          Divider(height: 1, color: c.border),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final isCurrent = index == current;
              final verse = verses[index];
              final number = index < numbers.length ? numbers[index] : '${index + 1}';

              final itemKey = _itemKeys.putIfAbsent(index, () => GlobalKey());
              return Container(
                key: itemKey,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                margin: EdgeInsets.only(top: index > 0 && index % 5 == 0 ? AppSpacing.xs : 0),
                color: isCurrent ? AppColors.audioBlue.withValues(alpha: 0.08) : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        number,
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
                        verse,
                        style: (isAm ? AppTextStyles.amharicBody : AppTextStyles.bodyMedium).copyWith(
                          fontSize: 13,
                          height: isAm ? 1.7 : 1.6,
                          color: isCurrent ? c.textPrimary : c.textPrimary.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
