import 'package:beslet_app/core/providers/audio_player_provider.dart';
import 'package:beslet_app/core/providers/soul_log_provider.dart';
import 'package:beslet_app/core/services/audio_bible_service.dart';
import 'package:beslet_app/features/spiritual/widgets/audio_player_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAudioPlayer extends AudioPlayerNotifier {
  final List<String> calls = [];
  AudioPlayerState _state = const AudioPlayerState();
  bool playing = false;

  @override
  AudioPlayerState build() => _state;

  void setState_(AudioPlayerState s) {
    _state = s;
    state = s;
  }

  @override
  Future<void> play(AudioChapterInfo info) async {
    calls.add('play:${info.bookId}:${info.chapter}');
    setState_(AudioPlayerState(
      state: AudioState.playing,
      chapter: info,
      currentVerse: 0,
      totalVerses: 1,
      verseTexts: const ['text'],
      verseNumbers: const ['1'],
      sourceType: AudioSourceType.recorded,
    ));
  }

  @override
  Future<void> togglePlayPause() async {
    calls.add('toggle');
    setState_(AudioPlayerState(
      state: playing ? AudioState.paused : AudioState.playing,
      chapter: _state.chapter,
      verseTexts: _state.verseTexts,
    ));
    playing = !playing;
  }

  @override
  void stop() {
    calls.add('stop');
    setState_(const AudioPlayerState());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_RecordingAudioPlayer> pumpBar(
    WidgetTester tester, {
    _RecordingAudioPlayer? player,
    String? bookId = 'psalms',
    int? chapterNum = 91,
  }) async {
    final p = player ?? _RecordingAudioPlayer();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlayerProvider.overrideWith(() => p),
          todaySoulLogProvider.overrideWith((ref) async => null),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AudioPlayerBar(
              isAm: false,
              bookId: bookId,
              chapterNum: chapterNum,
            ),
          ),
        ),
      ),
    );
    return p;
  }

  testWidgets('a stale loaded chapter is replaced, not toggled, when the screen '
      'chapter differs', (tester) async {
    final p = _RecordingAudioPlayer();
    await pumpBar(tester, player: p, bookId: 'psalms', chapterNum: 91);
    // Player already holds Genesis 3 from a previous chapter.
    p.setState_(AudioPlayerState(
      state: AudioState.playing,
      chapter: const AudioChapterInfo(
        bookId: 'genesis',
        chapter: 3,
        reference: 'Genesis 3',
        bookName: 'Genesis',
      ),
      currentVerse: 0,
      totalVerses: 1,
      verseTexts: const ['text'],
      verseNumbers: const ['1'],
      sourceType: AudioSourceType.recorded,
    ));
    await tester.pump();

    // The bar shows the stale chapter (playing => pause icon), but tapping
    // must start the on-screen chapter (psalms 91) rather than pausing the
    // stale Genesis audio.
    await tester.tap(find.byIcon(Icons.pause_circle));
    await tester.pump();

    expect(p.calls, contains('play:psalms:91'));
    expect(p.calls, isNot(contains('toggle')));
  });

  testWidgets('a loaded chapter matching the screen chapter toggles play/pause',
      (tester) async {
    final p = _RecordingAudioPlayer();
    await pumpBar(tester, player: p, bookId: 'psalms', chapterNum: 91);
    p.setState_(AudioPlayerState(
      state: AudioState.playing,
      chapter: const AudioChapterInfo(
        bookId: 'psalms',
        chapter: 91,
        reference: 'Psalms 91',
        bookName: 'Psalms',
      ),
      currentVerse: 0,
      totalVerses: 1,
      verseTexts: const ['text'],
      verseNumbers: const ['1'],
      sourceType: AudioSourceType.recorded,
    ));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.pause_circle));
    await tester.pump();

    expect(p.calls, contains('toggle'));
    expect(p.calls, isNot(contains('play:psalms:91')));
  });
}