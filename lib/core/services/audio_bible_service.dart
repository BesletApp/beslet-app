import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'scripture_service.dart';
import 'amharic_bible_service.dart';
import 'wordproject_bible_service.dart';
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
    try {
      await _tts.setLanguage(language);
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(_isAmharic ? 0.5 : 0.52);
    await _tts.setPitch(0.9);
    await _tts.setVolume(1.0);
    try {
      final voices = await _tts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        final filtered = (voices as List)
            .cast<Map<String, dynamic>>()
            .where((v) {
              final loc = (v['locale'] as String?)?.toLowerCase() ?? '';
              return loc.startsWith(language.split('-')[0].toLowerCase());
            })
            .toList();
        if (filtered.isNotEmpty) {
          filtered.sort((a, b) {
            final qA = (a['quality'] as int?) ?? 0;
            final qB = (b['quality'] as int?) ?? 0;
            return qB.compareTo(qA);
          });
          final preferred = filtered.where((v) {
            final name = ((v['name'] as String?) ?? '').toLowerCase();
            return name.contains('natural') || name.contains('wavenet') || name.contains('high');
          }).toList();
          final chosen = preferred.isNotEmpty ? preferred.first : filtered.first;
          await _tts.setVoice({
            'name': chosen['name'],
            'locale': chosen['locale'],
          });
        }
      }
    } catch (_) {}
    _tts.setCompletionHandler(() {
      if (_sourceType == AudioSourceType.tts) {
        if (_currentVerseIndex < _currentVerses.length - 1) {
          _currentVerseIndex++;
          _speakCurrentVerse();
        } else {
          _state = AudioState.stopped;
          onStateChanged?.call();
          onCompleted?.call();
        }
      }
    });
    _initialized = true;
  }

  Future<void> _fetchChapterText(AudioChapterInfo info) async {
    try {
      if (info.isAmharic) {
        final amVerses = await AmharicBibleService.fetchChapter(info.bookId, info.chapter);
        if (amVerses.isNotEmpty) {
          _currentVerseNumbers = amVerses.map((v) => v.number.toString()).toList();
          _currentVerses = amVerses.map((v) => v.text).toList();
        } else {
          _errorMessage = 'Amharic text not available for this chapter';
          _state = AudioState.error;
          onStateChanged?.call();
        }
      } else {
        final bookName = ScriptureService.bookMap[info.bookId]?.nameEn ?? info.bookId;
        final url = 'https://bible-api.com/${Uri.encodeComponent(bookName)}+${info.chapter}?translation=web';
        final response = await http
            .get(Uri.parse(url), headers: {'User-Agent': 'BesletApp/1.0'})
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final verses = data['verses'] as List<dynamic>;
          _currentVerseNumbers = verses.map((v) => v['verse'].toString()).cast<String>().toList();
          _currentVerses = verses.map((v) => v['text'].toString()).cast<String>().toList();
        } else {
          _errorMessage = 'Failed to load chapter text (${response.statusCode})';
          _state = AudioState.error;
          onStateChanged?.call();
        }
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
      _state = AudioState.playing;
      onStateChanged?.call();
      await _tts.stop();
      await _audioPlayer.stop();
      final book = ScriptureService.bookMap[info.bookId];
      if (book != null) {
        try {
          final langCode = info.isAmharic ? '17' : '01';
          final audioFile = await WordProjectBibleService.getAudio(book.wordprojectId, info.chapter, languageCode: langCode);
          if (audioFile != null) { await _playRecordedAudio(audioFile.path); return; }
        } catch (_) {}
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
      final book = ScriptureService.bookMap[info.bookId];
      if (book != null) {
        try {
          final langCode = info.isAmharic ? '17' : '01';
          final audioFile = await WordProjectBibleService.getAudio(book.wordprojectId, info.chapter, languageCode: langCode);
          if (audioFile != null) { await _playRecordedAudio(audioFile.path); return; }
        } catch (_) {}
      }
      await _playTtsAudio();
    } catch (e) {
      if (_currentVerses.isNotEmpty) {
        await _playTtsAudio();
      } else {
        _errorMessage = 'Connect to the internet to listen to Bible audio';
        _state = AudioState.error;
        onStateChanged?.call();
      }
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
    _sourceType = AudioSourceType.tts;
    _state = AudioState.playing;
    onStateChanged?.call();
    await _audioPlayer.stop();
    await _speakCurrentVerse();
  }

  Future<void> _speakCurrentVerse() async {
    if (_currentVerseIndex < _currentVerses.length) {
      final text = _currentVerses[_currentVerseIndex];
      if (_isAmharic) {
        await _tts.speak(text);
      } else {
        await _tts.speak('<speak>$text<break time="200ms"/></speak>');
      }
    }
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
    onStateChanged?.call();
  }

  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
  }
}
