import 'dart:typed_data';

import 'package:beslet_app/core/voice/recording_adapter.dart';
import 'package:beslet_app/core/voice/transcription_service.dart';
import 'package:beslet_app/core/voice/translation_service.dart';
import 'package:beslet_app/core/voice/voice_models.dart';

/// Injectable recording seam used across the voice unit + widget tests. It
/// behaves like a granted microphone that captures a 500 ms audio clip.
class FakeRecordingAdapter implements RecordingAdapter {
  VoicePermissionState permission = VoicePermissionState.granted;
  Object? startError;
  Object? stopError;
  VoiceRecording? stopResult;

  var startCalls = 0;
  var stopCalls = 0;
  var cancelCalls = 0;
  var disposeCalls = 0;
  var openSettingsCalls = 0;
  final levels = <double>[];

  FakeRecordingAdapter() {
    stopResult = VoiceRecording(
      bytes: Uint8List.fromList(List.filled(3200, 0)),
      mimeType: 'audio/wav',
      path: 'fake.wav',
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  Future<VoicePermissionState> permissionState() async => permission;

  @override
  Future<VoicePermissionState> requestPermission() async => permission;

  @override
  Future<bool> hasMicrophone() async => true;

  @override
  Future<List<String>> supportedMimeTypes() async => const ['audio/wav'];

  @override
  Future<String> pickMimeType() async => 'audio/wav';

  @override
  Future<void> start({
    required String mimeType,
    void Function(double level)? onLevel,
  }) async {
    startCalls++;
    final error = startError;
    if (error != null) throw error;
    onLevel?.call(-40);
    levels.add(-40);
  }

  @override
  Future<VoiceRecording> stop() async {
    stopCalls++;
    final error = stopError;
    if (error != null) throw error;
    return stopResult!;
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  @override
  Future<bool> openSettings() async {
    openSettingsCalls++;
    return true;
  }

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

class FakeTranscriptionService implements TranscriptionService {
  FakeTranscriptionService({this.result, this.error});

  VoiceTranscript? result;
  VoicePipelineException? error;
  var calls = 0;

  @override
  bool get isAvailable => true;

  @override
  String? get lastError => null;

  @override
  Future<VoiceTranscript> transcribe(VoiceRecording audio, {String? languageHint}) async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return result ?? const VoiceTranscript('Hello there', detectedLanguage: 'en');
  }
}

class FakeTranslationService implements TranslationService {
  FakeTranslationService({this.result, this.error});

  VoiceTranslation? result;
  VoicePipelineException? error;
  var calls = 0;
  String? lastSource;
  String? lastTarget;

  @override
  Future<VoiceTranslation> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    calls++;
    lastSource = sourceLanguage;
    lastTarget = targetLanguage;
    final e = error;
    if (e != null) throw e;
    return result ?? const VoiceTranslation('salem');
  }
}