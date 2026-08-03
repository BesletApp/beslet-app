import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/audio_bible_service.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/providers/audio_player_provider.dart';
import '../../../core/providers/soul_log_provider.dart';
import '../../../core/emotional/mood_content.dart';

class AudioPlayerBar extends ConsumerWidget {
  final bool isAm;
  final String? bookId;
  final int? chapterNum;

  const AudioPlayerBar({super.key, this.isAm = false, this.bookId, this.chapterNum});

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

  static const List<double> _speeds = [0.75, 1.0, 1.25, 1.5];

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

  void _toggleOrStart(WidgetRef ref) {
    final notifier = ref.read(audioPlayerProvider.notifier);
    final playerState = ref.read(audioPlayerProvider);
    if (playerState.chapter != null && playerState.verseTexts.isNotEmpty) {
      notifier.togglePlayPause();
      return;
    }
    final bookId = this.bookId;
    final chapterNum = this.chapterNum;
    if (bookId == null || chapterNum == null) return;
    final book = ScriptureService.bookMap[bookId];
    final info = AudioChapterInfo(
      bookId: bookId,
      chapter: chapterNum,
      reference: '${book?.nameEn ?? bookId} $chapterNum',
      bookName: book?.nameEn ?? bookId,
      isAmharic: isAm,
    );
    notifier.play(info);
  }

  String _chapterLabel(bool isAm, AudioPlayerState s) {
    final ch = s.chapter;
    if (ch == null) return '';
    return '${ScriptureService.getBookName(ch.bookId, isAm)} ${ch.chapter}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(audioPlayerProvider);
    final c = AppColors.of(context);
    final isAm = this.isAm;
    final mood = ref.watch(todaySoulLogProvider).valueOrNull?.mood;

    final hasChapter =
        playerState.chapter != null && playerState.verseTexts.isNotEmpty;
    final canStart = !hasChapter && bookId != null && chapterNum != null;

    final sentence = _livingSentence(mood, isAm);
    final size = _sentenceSize(mood);
    final alpha = _sentenceBaseAlpha(mood);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: hasChapter || canStart
              ? () => _toggleOrStart(ref)
              : null,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              sentence,
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: size,
                fontStyle: FontStyle.italic,
                color: c.primary.withValues(alpha: alpha),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        if (playerState.state == AudioState.loading)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Row(children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.audioBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isAm ? 'እየጫነ ነው...' : 'Loading...',
                style: TextStyle(fontSize: 11, color: c.textMuted),
              ),
            ]),
          )
        else if (playerState.state == AudioState.error &&
            playerState.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Text(
              playerState.error!,
              style: TextStyle(fontSize: 11, color: c.error),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        else if (hasChapter)
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _chapterLabel(isAm, playerState),
                        style: TextStyle(
                          fontSize: 11,
                          color: c.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${playerState.currentVerse + 1}/${playerState.totalVerses}',
                      style: TextStyle(fontSize: 11, color: c.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _miniButton(
                        c,
                        Icons.skip_previous,
                        () => ref
                            .read(audioPlayerProvider.notifier)
                            .previousVerse()),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _toggleOrStart(ref),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          playerState.state == AudioState.playing
                              ? Icons.pause_circle
                              : Icons.play_circle,
                          size: 30,
                          color: c.audioBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _miniButton(
                        c,
                        Icons.skip_next,
                        () => ref
                            .read(audioPlayerProvider.notifier)
                            .nextVerse()),
                    if (playerState.sourceType == AudioSourceType.tts) ...[
                      const SizedBox(width: 12),
                      _speedChip(ref, playerState, c),
                    ],
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _miniButton(ThemePalette c, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 22, color: c.textSecondary),
      ),
    );
  }

  Widget _speedChip(WidgetRef ref, AudioPlayerState s, ThemePalette c) {
    return InkWell(
      onTap: () {
        final idx = _speeds.indexOf(s.speed);
        final next = _speeds[(idx + 1) % _speeds.length];
        ref.read(audioPlayerProvider.notifier).setSpeed(next);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '${s.speed}x',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: c.primary,
          ),
        ),
      ),
    );
  }
}
