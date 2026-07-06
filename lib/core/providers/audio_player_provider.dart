import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_bible_service.dart';

class AudioPlayerState {
  final AudioState state;
  final AudioChapterInfo? chapter;
  final int currentVerse;
  final int totalVerses;
  final List<String> verseTexts;
  final List<String> verseNumbers;
  final String? error;
  final double speed;
  final AudioSourceType sourceType;
  final int totalDurationMs;

  const AudioPlayerState({
    this.state = AudioState.stopped,
    this.chapter,
    this.currentVerse = 0,
    this.totalVerses = 0,
    this.verseTexts = const [],
    this.verseNumbers = const [],
    this.error,
    this.speed = 1.0,
    this.sourceType = AudioSourceType.tts,
    this.totalDurationMs = 0,
  });

  bool get isActive =>
      state == AudioState.playing ||
      state == AudioState.paused ||
      state == AudioState.loading;
}

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  final AudioBibleService _service = AudioBibleService();

  @override
  AudioPlayerState build() {
    _service.onStateChanged = () {
      _updateState();
    };
    _service.onCompleted = () {
      _updateState();
    };
    ref.onDispose(() => _service.dispose());
    return const AudioPlayerState();
  }

  void _updateState() {
    state = AudioPlayerState(
      state: _service.state,
      chapter: _service.currentChapter,
      currentVerse: _service.currentVerseIndex,
      totalVerses: _service.totalVerses,
      verseTexts: _service.currentVerseTexts,
      verseNumbers: _service.currentVerseNumbers,
      error: _service.errorMessage,
      speed: state.speed,
      sourceType: _service.sourceType,
      totalDurationMs: _service.totalDurationMs,
    );
  }

  Future<void> play(AudioChapterInfo info) async {
    await _service.playChapter(info);
    _updateState();
  }

  Future<void> prepare(AudioChapterInfo info) async {
    await _service.loadChapter(info);
    _updateState();
  }

  Future<void> togglePlayPause() async {
    await _service.togglePlayPause();
    _updateState();
  }

  Future<void> nextVerse() async {
    await _service.nextVerse();
    _updateState();
  }

  Future<void> previousVerse() async {
    await _service.previousVerse();
    _updateState();
  }

  Future<void> seekToVerse(int index) async {
    await _service.seekToVerse(index);
    _updateState();
  }

  Future<void> setSpeed(double speed) async {
    await _service.setSpeed(speed);
    state = AudioPlayerState(
      state: _service.state,
      chapter: _service.currentChapter,
      currentVerse: _service.currentVerseIndex,
      totalVerses: _service.totalVerses,
      verseTexts: _service.currentVerseTexts,
      verseNumbers: _service.currentVerseNumbers,
      error: _service.errorMessage,
      speed: speed,
      sourceType: _service.sourceType,
      totalDurationMs: _service.totalDurationMs,
    );
  }

  void stop() {
    _service.stop();
    _updateState();
  }
}

final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(
  AudioPlayerNotifier.new,
);
