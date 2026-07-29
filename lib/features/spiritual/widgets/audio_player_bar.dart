import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/audio_bible_service.dart';
import '../../../core/providers/audio_player_provider.dart';

class AudioPlayerBar extends ConsumerStatefulWidget {
  final bool isAm;

  const AudioPlayerBar({super.key, this.isAm = false});

  @override
  ConsumerState<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends ConsumerState<AudioPlayerBar> {
  bool _overlayVisible = false;

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(audioPlayerProvider);
    final c = AppColors.of(context);

    final hasChapter =
        playerState.chapter != null && playerState.verseTexts.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_overlayVisible)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(1),
                    child: LinearProgressIndicator(
                      value: playerState.verseTexts.isNotEmpty
                          ? (playerState.currentVerse + 1) /
                              playerState.verseTexts.length
                          : 0,
                      minHeight: 2,
                      backgroundColor: c.border,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.audioBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .togglePlayPause();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      playerState.state == AudioState.playing
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      size: 24,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (hasChapter && !_overlayVisible)
          InkWell(
            onTap: () {
              ref.read(audioPlayerProvider.notifier).togglePlayPause();
              setState(() => _overlayVisible = true);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                playerState.state == AudioState.playing
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 24,
                color: c.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}
