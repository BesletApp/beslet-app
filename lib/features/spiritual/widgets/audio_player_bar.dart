import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/audio_bible_service.dart';
import '../../../core/providers/audio_player_provider.dart';
import '../../../core/providers/soul_log_provider.dart';
import '../../../core/emotional/mood_content.dart';

class AudioPlayerBar extends ConsumerStatefulWidget {
  final bool isAm;

  const AudioPlayerBar({super.key, this.isAm = false});

  @override
  ConsumerState<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends ConsumerState<AudioPlayerBar> {
  static const Map<int, double> _moodFontSize = {
    1: 18.0,
    2: 17.0,
    3: 16.0,
    4: 16.0,
    5: 16.0,
  };
  static const Map<int, double> _moodAlpha = {
    1: 0.85,
    2: 0.90,
    3: 1.0,
    4: 1.0,
    5: 1.0,
  };

  bool _departing = false;
  double _memorialOpacity = 0.0;
  String? _lastChapterKey;
  bool _overlayVisible = false;
  Timer? _overlayTimer;

  double _sentenceSize(int? mood) => _moodFontSize[mood] ?? 16.0;
  double _sentenceBaseAlpha(int? mood) => _moodAlpha[mood] ?? 1.0;

  String _livingSentence(int? mood, bool isAm) {
    if (mood != null && MoodContent.livingSentence.containsKey(mood)) {
      return isAm
          ? MoodContent.livingSentence[mood]!.am
          : MoodContent.livingSentence[mood]!.en;
    }
    return isAm
        ? 'ጸጥ ብለህ እርሱ አምላክ መሆኑን እወቅ።'
        : 'Be still, and know that He is God.';
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(audioPlayerProvider, _onAudioStateChange);

    final playerState = ref.watch(audioPlayerProvider);
    final c = AppColors.of(context);
    final isAm = widget.isAm;
    final mood = ref.watch(todaySoulLogProvider).valueOrNull?.mood;

    final chapterKey = playerState.chapter != null
        ? '${playerState.chapter!.bookId}:${playerState.chapter!.chapter}'
        : null;

    if (chapterKey != _lastChapterKey) {
      _lastChapterKey = chapterKey;
      _departing = false;
      _memorialOpacity = 0.0;
      _overlayVisible = false;
      _overlayTimer?.cancel();
    }

    final sentence = _livingSentence(mood, isAm);
    final size = _sentenceSize(mood);
    final baseAlpha = _sentenceBaseAlpha(mood);
    final displayAlpha = _departing ? 0.4 : baseAlpha;

    final hasChapter =
        playerState.chapter != null && playerState.verseTexts.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: hasChapter ? _onSentenceTap : null,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: AnimatedOpacity(
              opacity: displayAlpha,
              duration: const Duration(milliseconds: 1500),
              child: Text(
                sentence,
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: _overlayVisible ? size - 2 : size,
                  fontStyle: FontStyle.italic,
                  color: c.primary.withValues(alpha: displayAlpha),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        if (_overlayVisible)
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
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
                    _startOverlayTimer();
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
        if (_departing)
          AnimatedOpacity(
            opacity: _memorialOpacity,
            duration: const Duration(milliseconds: 800),
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                isAm
                    ? 'ይህ ይቀመጣል።'
                    : 'This remains.',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: c.textMuted,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _onAudioStateChange(AudioPlayerState? prev, AudioPlayerState next) {
    final wasActive = prev?.state == AudioState.playing ||
        prev?.state == AudioState.paused;
    final nowActive = next.state == AudioState.playing ||
        next.state == AudioState.paused;

    if (wasActive && !nowActive && next.state == AudioState.stopped) {
      if (!_departing) {
        _departing = true;
        _overlayVisible = false;
        _overlayTimer?.cancel();
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) setState(() => _memorialOpacity = 1.0);
        });
      }
    }

    if (nowActive || next.state == AudioState.loading) {
      if (_departing) {
        setState(() {
          _departing = false;
          _memorialOpacity = 0.0;
        });
      }
    }
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 12), () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  void _onSentenceTap() {
    if (_departing) {
      ref.read(audioPlayerProvider.notifier).seekToVerse(0);
      ref.read(audioPlayerProvider.notifier).togglePlayPause();
      setState(() {
        _departing = false;
        _overlayVisible = true;
      });
      _startOverlayTimer();
      return;
    }

    ref.read(audioPlayerProvider.notifier).togglePlayPause();
    setState(() => _overlayVisible = true);
    _startOverlayTimer();
  }
}
