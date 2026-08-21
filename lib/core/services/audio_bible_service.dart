import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'scripture_service.dart';
import 'wordproject_bible_service.dart';
import 'ebible_web_audio_service.dart';
import 'bible_text_service.dart';

enum AudioSourceType { tts, recorded }

enum AudioState { stopped, playing, paused, loading, error }

class AudioChapterInfo {
  final String bookId;
  final int chapter;
  final String reference;
  final String bookName;
  final bool isAmharic;

  const AudioChapterInfo({
    required this.bookId,
    required this.chapter,
    required this.reference,
    required this.bookName,
    this.isAmharic = false,
  });
}

class AudioBibleService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;
  String? _initLanguage;
  bool _isAmharic = false;
  int _currentVerseIndex = 0;
  List<String> _currentVerses = [];
  List<String> _currentVerseNumbers = [];
  AudioChapterInfo? _currentChapter;
  AudioState _state = AudioState.stopped;
  String? _errorMessage;
  AudioSourceType _sourceType = AudioSourceType.tts;
  int _totalDurationMs = 0;
  int _estimatedVerseDurationMs = 0;

  AudioSourceType get sourceType => _sourceType;
  AudioState get state => _state;
  String? get errorMessage => _errorMessage;
  AudioChapterInfo? get currentChapter => _currentChapter;
  int get currentVerseIndex => _currentVerseIndex;
  int get totalVerses => _currentVerses.length;
  List<String> get currentVerseTexts => _currentVerses;
  List<String> get currentVerseNumbers => _currentVerseNumbers;
  int get totalDurationMs => _totalDurationMs;

  void Function()? onStateChanged;
  void Function()? onCompleted;
  bool naturallyCompleted = false;

  AudioBibleService() {
    _audioPlayer.onDurationChanged.listen((duration) {
      _totalDurationMs = duration.inMilliseconds;
      if (_currentVerses.isNotEmpty) {
        _estimatedVerseDurationMs = _totalDurationMs ~/ _currentVerses.length;
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (_sourceType == AudioSourceType.recorded &&
          _state == AudioState.playing &&
          _estimatedVerseDurationMs > 0 &&
          _currentVerses.isNotEmpty) {
        final estimatedIndex =
            (position.inMilliseconds / _estimatedVerseDurationMs).floor();
        final newIndex = estimatedIndex.clamp(0, _currentVerses.length - 1);
        if (newIndex != _currentVerseIndex) {
          _currentVerseIndex = newIndex;
          onStateChanged?.call();
        }
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (_sourceType == AudioSourceType.recorded) {
        _state = AudioState.stopped;
        naturallyCompleted = true;
        onStateChanged?.call();
        onCompleted?.call();
      }
    });
  }

  Future<void> _init({String language = 'en-US'}) async {
    if (_initialized && _initLanguage == language) return;
    await _tts.stop();
    await _audioPlayer.stop();
    _initialized = false;
    _initLanguage = language;
    _isAmharic = language == 'am-ET';
    if (_isAmharic) {
      // Amharic is never read aloud by TTS — only recorded narration is
      // played for Amharic, so the TTS engine is left unconfigured.
      return;
    }
    try {
      await _tts.setLanguage(language);
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.52);
    await _tts.setPitch(0.9);
    await _tts.setVolume(1.0);
    try {
      final voices = await _tts.getVoices;
      final chosen = voices != null ? selectTtsVoice(voices, language) : null;
      if (chosen != null) {
        final ok = await _tts.setVoice({
          'name': chosen['name'],
          'locale': chosen['locale'],
        });
        debugPrint('AudioBible: voice = ${chosen['name']} (${chosen['locale']}) quality=${chosen['quality']} ok=$ok');
      }
    } catch (e) {
      debugPrint('AudioBible: voice selection failed: $e');
    }
    _tts.setCompletionHandler(() {
      if (_sourceType != AudioSourceType.tts) return;
      if (_state != AudioState.playing) return;
      if (_currentVerseIndex < _currentVerses.length - 1) {
        _currentVerseIndex++;
        _speakCurrentVerse();
      } else {
        _state = AudioState.stopped;
        naturallyCompleted = true;
        onStateChanged?.call();
        onCompleted?.call();
      }
    });
    _initialized = true;
  }

  Future<void> _fetchChapterText(AudioChapterInfo info) async {
    try {
      final verses = await BibleTextService.fetchChapter(
        info.bookId,
        info.chapter,
        isAmharic: info.isAmharic,
      );
      if (verses.isNotEmpty) {
        _currentVerseNumbers = verses.map((v) => v.verse.toString()).toList();
        _currentVerses = verses.map((v) => v.text).toList();
      } else {
        _errorMessage = info.isAmharic
            ? 'Amharic text not available for this chapter'
            : 'Failed to load chapter text';
        _state = AudioState.error;
        onStateChanged?.call();
      }
    } catch (_) {
      _errorMessage = 'Connect to the internet to listen to Bible audio';
      _state = AudioState.error;
      onStateChanged?.call();
    }

    if (_errorMessage != null) {
      List<BibleVerse>? cached = await BibleTextService.tryCache(info.bookId, info.chapter, isAmharic: info.isAmharic);
      if (cached == null || cached.isEmpty) {
        cached = await BibleTextService.tryCache(info.bookId, info.chapter, isAmharic: !info.isAmharic);
      }
      if (cached != null && cached.isNotEmpty) {
        _currentVerseNumbers = cached.map((v) => v.verse.toString()).toList();
        _currentVerses = cached.map((v) => v.text).toList();
        _errorMessage = null;
        _state = AudioState.stopped;
        onStateChanged?.call();
      }
    }
  }

  Future<void> loadChapter(AudioChapterInfo info) async {
    final lang = info.isAmharic ? 'am-ET' : 'en-US';
    await _init(language: lang);
    _currentChapter = info;
    _currentVerseIndex = 0;
    _currentVerses = [];
    _currentVerseNumbers = [];
    _state = AudioState.loading;
    _errorMessage = null;
    _sourceType = AudioSourceType.tts;
    onStateChanged?.call();

    try {
      await _fetchChapterText(info);
      if (_errorMessage != null) return;
      _state = AudioState.stopped;
      onStateChanged?.call();
    } catch (e) {
      _errorMessage = 'Connect to the internet to listen to Bible audio';
      _state = AudioState.error;
      onStateChanged?.call();
    }
  }

  Future<void> playChapter(AudioChapterInfo info) async {
    if (_currentChapter?.bookId == info.bookId && _currentChapter?.chapter == info.chapter && _currentVerses.isNotEmpty) {
      _state = AudioState.loading;
      onStateChanged?.call();
      await _tts.stop();
      await _audioPlayer.stop();
      naturallyCompleted = false;
      if (await _tryPlayRecorded(info)) return;
      if (info.isAmharic) {
        _errorMessage = 'Amharic audio not available for this chapter';
        _state = AudioState.error;
        onStateChanged?.call();
        return;
      }
      await _playTtsAudio();
      return;
    }

    final lang = info.isAmharic ? 'am-ET' : 'en-US';
    await _init(language: lang);
    _currentChapter = info;
    _currentVerseIndex = 0;
    _currentVerses = [];
    _currentVerseNumbers = [];
    _state = AudioState.loading;
    _errorMessage = null;
    _sourceType = AudioSourceType.tts;
    onStateChanged?.call();

    try {
      await _fetchChapterText(info);
      if (_errorMessage != null) return;
      if (_currentVerses.isEmpty) {
        _errorMessage = 'This chapter has no text available';
        _state = AudioState.error;
        onStateChanged?.call();
        return;
      }
      if (await _tryPlayRecorded(info)) return;
      if (info.isAmharic) {
        _errorMessage = 'Amharic audio not available for this chapter';
        _state = AudioState.error;
        onStateChanged?.call();
        return;
      }
      await _playTtsAudio();
    } catch (e) {
      if (_currentVerses.isNotEmpty && !info.isAmharic) {
        await _playTtsAudio();
      } else if (info.isAmharic) {
        _errorMessage = 'Amharic audio not available for this chapter';
        _state = AudioState.error;
        onStateChanged?.call();
      } else {
        _errorMessage = 'Connect to the internet to listen to Bible audio';
        _state = AudioState.error;
        onStateChanged?.call();
      }
    }
  }

  /// Tries to play the recorded narration for [info]. Returns `true` when the
  /// chapter was either played or a distinct error was surfaced; returns
  /// `false` when the backend has no recording for this chapter (caller falls
  /// back to TTS for English, or reports the absence for Amharic).
  Future<bool> _tryPlayRecorded(AudioChapterInfo info) async {
    final book = ScriptureService.bookMap[info.bookId];
    if (book == null) return false;
    try {
      // English narration is the public-domain World English Bible recording
      // hosted by eBible.org; Amharic uses the WordProject 1962 recording.
      final audioFile = info.isAmharic
          ? await WordProjectBibleService.getAudio(
              book.wordprojectId, info.chapter,
              languageCode: '17')
          : await EbibleWebAudioService.getAudio(info.bookId, info.chapter);
      if (audioFile == null) return false;
      await _playRecordedAudio(audioFile.path);
      return true;
    } on WordProjectAudioDownloadException {
      _errorMessage = 'Amharic audio download failed — check your connection';
      _state = AudioState.error;
      onStateChanged?.call();
      return true;
    } on EbibleWebAudioDownloadException {
      _errorMessage = 'Audio download failed — check your connection';
      _state = AudioState.error;
      onStateChanged?.call();
      return true;
    } catch (_) {
      _errorMessage = info.isAmharic
          ? 'Amharic audio could not be played'
          : 'Audio could not be played';
      _state = AudioState.error;
      onStateChanged?.call();
      return true;
    }
  }

  Future<void> _playRecordedAudio(String filePath) async {
    _sourceType = AudioSourceType.recorded;
    _state = AudioState.playing;
    onStateChanged?.call();
    await _tts.stop();
    await _audioPlayer.stop();
    await _audioPlayer.play(DeviceFileSource(filePath));
  }

  Future<void> _playTtsAudio() async {
    if (_isAmharic) return;
    _sourceType = AudioSourceType.tts;
    _state = AudioState.playing;
    onStateChanged?.call();
    await _audioPlayer.stop();
    await _speakCurrentVerse();
  }

  Future<void> _speakCurrentVerse() async {
    if (_currentVerseIndex < _currentVerses.length) {
      await _speakText(_currentVerses[_currentVerseIndex]);
    }
  }

  Future<void> _speakText(String text) async {
    if (_isAmharic) {
      // Amharic is never read aloud by TTS.
      _state = AudioState.stopped;
      onStateChanged?.call();
      return;
    }
    final escaped = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    await _tts.speak('<speak>$escaped<break time="200ms"/></speak>');
  }

  /// Speaks a single passage (e.g. the daily thread verse) via TTS,
  /// stopping any in-progress chapter playback. Amharic is never read aloud
  /// by TTS, so this is a no-op for Amharic.
  Future<void> speakVerse(String text, {required bool isAmharic}) async {
    if (isAmharic) return;
    await _init(language: 'en-US');
    await _tts.stop();
    await _audioPlayer.stop();
    _sourceType = AudioSourceType.tts;
    _currentChapter = null;
    _currentVerses = [];
    _currentVerseNumbers = [];
    _currentVerseIndex = 0;
    _errorMessage = null;
    _state = AudioState.playing;
    onStateChanged?.call();
    await _speakText(text);
  }

  Future<void> pause() async {
    if (_state == AudioState.playing) {
      if (_sourceType == AudioSourceType.recorded) {
        await _audioPlayer.pause();
      } else {
        await _tts.stop();
      }
      _state = AudioState.paused;
      onStateChanged?.call();
    }
  }

  Future<void> resume() async {
    if (_state == AudioState.paused) {
      if (_sourceType == AudioSourceType.recorded) {
        await _audioPlayer.resume();
        _state = AudioState.playing;
        onStateChanged?.call();
      } else {
        _state = AudioState.playing;
        onStateChanged?.call();
        await _speakCurrentVerse();
      }
    }
  }

  Future<void> togglePlayPause() async {
    if (_state == AudioState.playing) {
      await pause();
    } else if (_state == AudioState.paused) {
      await resume();
    } else if (_state == AudioState.stopped || _state == AudioState.error) {
      if (_currentChapter != null) {
        await playChapter(_currentChapter!);
      }
    }
  }

  Future<void> nextVerse() async {
    if (_currentVerseIndex < _currentVerses.length - 1) {
      if (_sourceType == AudioSourceType.recorded) {
        final targetMs =
            (_currentVerseIndex + 1) * _estimatedVerseDurationMs;
        await _audioPlayer.seek(Duration(milliseconds: targetMs));
      } else {
        await _tts.stop();
      }
      _currentVerseIndex++;
      if (_state == AudioState.playing || _state == AudioState.paused) {
        if (_sourceType == AudioSourceType.tts) {
          _state = AudioState.playing;
          onStateChanged?.call();
          await _speakCurrentVerse();
        }
      }
    }
  }

  Future<void> previousVerse() async {
    if (_currentVerseIndex > 0) {
      if (_sourceType == AudioSourceType.recorded) {
        final targetMs =
            (_currentVerseIndex - 1) * _estimatedVerseDurationMs;
        await _audioPlayer.seek(Duration(milliseconds: targetMs));
      } else {
        await _tts.stop();
      }
      _currentVerseIndex--;
      if (_state == AudioState.playing || _state == AudioState.paused) {
        if (_sourceType == AudioSourceType.tts) {
          _state = AudioState.playing;
          onStateChanged?.call();
          await _speakCurrentVerse();
        }
      }
    }
  }

  Future<void> seekToVerse(int index) async {
    if (index >= 0 && index < _currentVerses.length) {
      if (_sourceType == AudioSourceType.recorded) {
        final targetMs = index * _estimatedVerseDurationMs;
        await _audioPlayer.seek(Duration(milliseconds: targetMs));
      } else {
        await _tts.stop();
      }
      _currentVerseIndex = index;
      if (_state == AudioState.playing || _state == AudioState.paused) {
        if (_sourceType == AudioSourceType.tts) {
          _state = AudioState.playing;
          onStateChanged?.call();
          await _speakCurrentVerse();
        }
      }
    }
  }

  Future<void> seekToPosition(Duration position) async {
    if (_sourceType == AudioSourceType.recorded) {
      await _audioPlayer.seek(position);
    }
  }

  Future<Duration> get currentPosition async {
    if (_sourceType == AudioSourceType.recorded &&
        _audioPlayer.state == PlayerState.playing) {
      final pos = await _audioPlayer.getCurrentPosition();
      return pos ?? Duration.zero;
    }
    return Duration.zero;
  }

  Duration? get duration {
    if (_sourceType == AudioSourceType.recorded) {
      return Duration(milliseconds: _totalDurationMs);
    }
    return null;
  }

  Future<void> setSpeed(double rate) async {
    if (_initialized) {
      await _tts.setSpeechRate(rate);
    }
  }

  void stop() {
    _tts.stop();
    _audioPlayer.stop();
    _state = AudioState.stopped;
    naturallyCompleted = false;
    onStateChanged?.call();
  }

  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
  }
}

@visibleForTesting
Map<String, dynamic>? selectTtsVoice(List<dynamic> voices, String language) {
  const qualityRank = {
    'very high': 5,
    'high': 4,
    'normal': 3,
    'low': 2,
    'very low': 1,
  };
  final langPrefix = language.split('-')[0].toLowerCase();
  final exactLocale = language.toLowerCase();
  final filtered = voices
      .cast<Map<String, dynamic>>()
      .where((v) {
        final loc = (v['locale'] as String?)?.toLowerCase() ?? '';
        return loc.startsWith(langPrefix);
      })
      .toList();
  if (filtered.isEmpty) return null;
  filtered.sort((a, b) {
    final nameA = ((a['name'] as String?) ?? '').toLowerCase();
    final nameB = ((b['name'] as String?) ?? '').toLowerCase();
    final neuralA = nameA.contains('network') ||
        nameA.contains('wavenet') ||
        nameA.contains('neural') ||
        nameA.contains('natural') ? 1 : 0;
    final neuralB = nameB.contains('network') ||
        nameB.contains('wavenet') ||
        nameB.contains('neural') ||
        nameB.contains('natural') ? 1 : 0;
    final localeA = ((a['locale'] as String?) ?? '').toLowerCase();
    final localeB = ((b['locale'] as String?) ?? '').toLowerCase();
    final exactA = localeA == exactLocale ? 1 : 0;
    final exactB = localeB == exactLocale ? 1 : 0;
    final qA = qualityRank[(a['quality'] as String?)?.toLowerCase()] ?? 0;
    final qB = qualityRank[(b['quality'] as String?)?.toLowerCase()] ?? 0;
    final netA = (a['network_required'] as String?) == '1' ? 1 : 0;
    final netB = (b['network_required'] as String?) == '1' ? 1 : 0;
    if (qA != qB) return qB.compareTo(qA);
    if (neuralA != neuralB) return neuralB.compareTo(neuralA);
    if (exactA != exactB) return exactB.compareTo(exactA);
    return netA.compareTo(netB);
  });
  return filtered.first;
}
