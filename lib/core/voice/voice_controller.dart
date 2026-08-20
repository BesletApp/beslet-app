import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'recording_adapter.dart';
import 'transcription_service.dart';
import 'translation_service.dart';
import 'voice_capability_probe.dart';
import 'voice_diagnostics.dart';
import 'voice_error_mapper.dart';
import 'voice_models.dart';

/// Drives the whole voice flow: permission → record (with live level) →
/// validate audio → transcribe → optionally translate → complete. The captured
/// [VoiceRecording] is held in memory so a failed transcription or translation
/// can be retried without re-recording.
class VoiceController extends ChangeNotifier {
  final RecordingAdapter recorder;
  final TranscriptionService transcription;
  final TranslationService translator;
  final VoiceCapabilityProbe probe;

  VoicePhase _phase = VoicePhase.idle;
  VoiceError? _error;
  VoiceRecording? _recording;
  VoiceTranscript? _transcript;
  VoiceTranslation? _translation;
  VoiceError? _translationError;
  double _level = 0;
  DateTime? _startedAt;

  VoiceController({
    required this.recorder,
    required this.transcription,
    required this.translator,
    required this.probe,
  });

  VoicePhase get phase => _phase;
  VoiceError? get error => _error;
  VoiceRecording? get recording => _recording;
  VoiceTranscript? get transcript => _transcript;
  VoiceTranslation? get translation => _translation;
  VoiceError? get translationError => _translationError;
  double get level => _level;
  bool get isRecording => _phase == VoicePhase.recording;

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  /// Requests permission and starts recording. Never blocks on the probe; the
  /// probe only feeds diagnostics.
  Future<void> start() async {
    if (isRecording) return;
    _error = null;
    _phase = VoicePhase.requestingPermission;
    notifyListeners();
    final permission = await recorder.requestPermission();
    if (permission != VoicePermissionState.granted) {
      _fail(VoiceErrorMapper.fromPermissionState(permission), 'permission $permission');
      return;
    }
    try {
      await probe.probe();
    } catch (e) {
      developer.log('voice: probe failed: $e', name: 'voice');
    }
    final mime = await recorder.pickMimeType();
    try {
      await recorder.start(
        mimeType: mime,
        onLevel: (level) {
          _level = level;
          notifyListeners();
        },
      );
      _startedAt = DateTime.now();
      _phase = VoicePhase.recording;
      notifyListeners();
    } catch (e) {
      _fail(VoiceErrorMapper.mapRecordingError(e), e.toString());
    }
  }

  /// Stops recording, validates the audio, and transcribes it.
  Future<void> stop() async {
    if (!isRecording) return;
    _phase = VoicePhase.transcribing;
    notifyListeners();
    try {
      final audio = await recorder.stop();
      if (audio.bytes.isEmpty || audio.duration.inMilliseconds < 150) {
        await _cleanupRecording();
        _fail(VoiceError.emptyAudio, 'audio empty or too short');
        return;
      }
      _recording = audio;
      VoiceDiagnostics.instance.record(
        phase: 'transcribing',
        recordedBytes: audio.sizeBytes,
        recordedDurationMs: audio.duration.inMilliseconds,
      );
      await _transcribe();
    } catch (e) {
      await _cleanupRecording();
      _fail(VoiceErrorMapper.mapRecordingError(e), e.toString());
    }
  }

  Future<void> _transcribe() async {
    final audio = _recording;
    if (audio == null) return;
    _phase = VoicePhase.transcribing;
    _error = null;
    notifyListeners();
    try {
      final result = await transcription.transcribe(audio);
      _transcript = result;
      _phase = VoicePhase.complete;
      notifyListeners();
    } on VoicePipelineException catch (e) {
      _fail(e.error, e.detail);
    } catch (e) {
      _fail(VoiceErrorMapper.mapGeminiError(e), e.toString());
    }
  }

  /// Retries transcription on the already-captured audio — never re-records.
  Future<void> retryTranscription() async {
    if (_recording == null) {
      await start();
      return;
    }
    await _transcribe();
  }

  /// Runs the optional translation step. On failure the original transcript is
  /// preserved and the failure is reported separately so it can be retried.
  /// [text] overrides the transcript text (e.g. after the user edits it).
  Future<void> translate({String? targetLanguage, String? text}) async {
    final src = (text ?? _transcript?.text)?.trim() ?? '';
    if (src.isEmpty) return;
    _phase = VoicePhase.translating;
    _translationError = null;
    notifyListeners();
    final source =
        _transcript?.detectedLanguage ?? (detectAmharic(src) ? 'am' : 'en');
    final target = targetLanguage ?? (source == 'am' ? 'en' : 'am');
    try {
      final result = await translator.translate(
        text: src,
        sourceLanguage: source,
        targetLanguage: target,
      );
      _translation = result;
      _phase = VoicePhase.complete;
      notifyListeners();
    } on VoicePipelineException catch (e) {
      _translationError = e.error;
      _phase = VoicePhase.complete;
      notifyListeners();
    } catch (e) {
      _translationError = VoiceError.translationFailed;
      _phase = VoicePhase.complete;
      notifyListeners();
    }
  }

  Future<void> retryTranslation({String? text}) =>
      translate(text: text ?? _transcript?.text);

  /// Opens app settings so a permanently denied microphone permission can be
  /// re-granted.
  Future<bool> openSettings() => recorder.openSettings();

  /// Cancels the in-progress recording and discards its temp file.
  Future<void> cancel() async {
    await recorder.cancel();
    _startedAt = null;
    _level = 0;
    _error = null;
    if (isRecording) {
      _phase = VoicePhase.idle;
      notifyListeners();
    }
  }

  /// Clears a finished transcript/translation so a new recording can start.
  void clear() {
    _transcript = null;
    _translation = null;
    _translationError = null;
    _recording = null;
    _error = null;
    _level = 0;
    _startedAt = null;
    _phase = VoicePhase.idle;
    notifyListeners();
  }

  Future<void> _cleanupRecording() async {
    await recorder.cancel();
    _recording = null;
    _startedAt = null;
    _level = 0;
  }

  void _fail(VoiceError error, Object detail) {
    VoiceDiagnostics.instance.record(
      lastError: error.name,
      lastTechnicalError: detail.toString(),
    );
    developer.log('voice: ${error.name}: $detail', name: 'voice');
    _error = error;
    _startedAt = null;
    _level = 0;
    _phase = VoicePhase.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(recorder.dispose());
    super.dispose();
  }
}