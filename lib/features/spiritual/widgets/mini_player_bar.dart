import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/audio_player_provider.dart';
import '../../../core/services/audio_bible_service.dart';

class MiniPlayerBar extends ConsumerStatefulWidget {
  const MiniPlayerBar({super.key});

  @override
  ConsumerState<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends ConsumerState<MiniPlayerBar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);

    if (!playerState.isActive) return const SizedBox.shrink();

    final chapter = playerState.chapter;
    if (chapter == null) return const SizedBox.shrink();

    final isPlaying = playerState.state == AudioState.playing;
    final total = playerState.totalVerses;
    final current = playerState.currentVerse;
    final progress = total > 0 ? (current + 1) / total : 0.0;

    if (_collapsed) {
      return GestureDetector(
        onTap: () => setState(() => _collapsed = false),
        child: Container(
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(children: [
            Expanded(
              child: ClipRRect(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.audioBlue),
                  minHeight: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.play_arrow, size: 12, color: AppColors.audioBlue),
            ),
          ]),
        ),
      );
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.audioBlue),
              minHeight: 2,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(Icons.play_circle_fill, size: 16, color: AppColors.audioBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    chapter.reference,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (total > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${current + 1}/$total',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () =>
                      ref.read(audioPlayerProvider.notifier).togglePlayPause(),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.textMuted),
                  onPressed: () => setState(() => _collapsed = true),
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                const SizedBox(width: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
