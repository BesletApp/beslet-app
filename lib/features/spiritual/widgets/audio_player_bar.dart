import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/audio_bible_service.dart';
import '../../../core/providers/audio_player_provider.dart';

class AudioPlayerBar extends ConsumerStatefulWidget {
  final bool compact;
  final bool isAm;

  const AudioPlayerBar({super.key, this.compact = false, this.isAm = false});

  @override
  ConsumerState<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends ConsumerState<AudioPlayerBar> {
  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final isAm = widget.isAm;

    if (playerState.state == AudioState.loading) {
      return _buildContainer(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.audioBlue,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isAm ? 'በማዘጋጀት ላይ...' : 'Loading...',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (playerState.state == AudioState.error) {
      return _buildContainer(
        child: Row(
          children: [
            const Icon(Icons.wifi_off, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                playerState.error ??
                    (isAm ? 'ገመድ አልተገኘም' : 'No internet connection'),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (playerState.state == AudioState.stopped && playerState.chapter == null) {
      return _buildContainer(
        child: Row(
          children: [
            const Icon(Icons.play_circle_outline,
                size: 18, color: AppColors.audioBlue),
            const SizedBox(width: 8),
            Text(
              isAm ? 'ለማዳመጥ ይንኩ' : 'Tap play to listen',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final chapter = playerState.chapter!;
    final isPlaying = playerState.state == AudioState.playing;
    final isRecorded = playerState.sourceType == AudioSourceType.recorded;

    if (isRecorded) {
      return _buildRecordedPlayer(playerState, chapter, isPlaying, isAm);
    }

    return _buildTtsPlayer(playerState, chapter, isPlaying, isAm);
  }

  Widget _buildRecordedPlayer(
    AudioPlayerState playerState,
    AudioChapterInfo chapter,
    bool isPlaying,
    bool isAm,
  ) {
    final total = playerState.totalVerses;
    final current = playerState.currentVerse;
    final progress = total > 0 ? (current + 1) / total : 0.0;

    return _buildContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 18, color: AppColors.audioBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter.reference,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.compact)
                Text(
                  '${current + 1}/$total',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.audioBlue),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconButton(Icons.skip_previous, 'Previous verse',
                    () => ref.read(audioPlayerProvider.notifier).previousVerse()),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.audioBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 28,
                      color: const Color(0xFF0A0A0A),
                    ),
                    onPressed: () =>
                        ref.read(audioPlayerProvider.notifier).togglePlayPause(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 16),
                _iconButton(Icons.skip_next, 'Next verse',
                    () => ref.read(audioPlayerProvider.notifier).nextVerse()),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              isAm ? 'የተቀዳ ድምጽ' : 'Pre-recorded audio',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTtsPlayer(
    AudioPlayerState playerState,
    AudioChapterInfo chapter,
    bool isPlaying,
    bool isAm,
  ) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return _buildContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                  size: 18, color: AppColors.audioBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter.reference,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.compact)
                Text(
                  '${playerState.currentVerse + 1}/${playerState.totalVerses}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMuted, fontSize: 11),
                ),
            ],
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: playerState.totalVerses > 0
                    ? (playerState.currentVerse + 1) / playerState.totalVerses
                    : 0,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.audioBlue),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _iconButton(Icons.skip_previous, 'Previous verse',
                    () => ref.read(audioPlayerProvider.notifier).previousVerse()),
                const SizedBox(width: 8),
                _iconButton(Icons.replay_10, '-15s',
                    () => ref.read(audioPlayerProvider.notifier).previousVerse()),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.audioBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 28,
                      color: const Color(0xFF0A0A0A),
                    ),
                    onPressed: () =>
                        ref.read(audioPlayerProvider.notifier).togglePlayPause(),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
                const SizedBox(width: 16),
                _iconButton(Icons.forward_30, '+15s',
                    () => ref.read(audioPlayerProvider.notifier).nextVerse()),
                const SizedBox(width: 8),
                _iconButton(Icons.skip_next, 'Next verse',
                    () => ref.read(audioPlayerProvider.notifier).nextVerse()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...speeds.map((s) {
                  final active = s == playerState.speed;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(audioPlayerProvider.notifier).setSpeed(s),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: active ? AppColors.audioBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active ? AppColors.audioBlue : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '${s}x',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? const Color(0xFF0A0A0A)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String tooltip, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, size: 20, color: AppColors.textSecondary),
      onPressed: onPressed,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
