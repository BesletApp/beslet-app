import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final verses = playerState.verseTexts;
    final numbers = playerState.verseNumbers;
    final isAm = widget.isAm;

    if (verses.isEmpty) {
      if (playerState.state == AudioState.error) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Icon(Icons.wifi_off, size: 32, color: AppColors.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              isAm ? 'በይነመረብ አልተገኘም' : 'No internet connection',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              isAm ? 'እባክዎ ይገናኙና እንደገና ይሞክሩ' : 'Please connect and try again',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
            ),
          ]),
        );
      }
      return const SizedBox.shrink();
    }

    final current = playerState.currentVerse;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients && current < verses.length) {
        final offset = (current * 56.0).clamp(0.0, _scrollCtrl.position.maxScrollExtent);
        if (_scrollCtrl.offset != offset) {
          _scrollCtrl.animateTo(offset, duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Text(
              playerState.chapter?.reference ?? '',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: verses.length,
              itemBuilder: (context, index) {
                final isCurrent = index == current;
                final verse = verses[index];
                final number = index < numbers.length ? numbers[index] : '${index + 1}';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  color: isCurrent ? AppColors.audioBlue.withValues(alpha: 0.08) : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        margin: const EdgeInsets.only(top: 1),
                        child: Text(
                          number,
                          style: TextStyle(
                            fontFamily: 'Inter', fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isCurrent ? AppColors.audioBlue : AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          verse,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontSize: 13,
                            color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
