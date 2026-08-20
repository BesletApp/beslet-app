import 'dart:typed_data';

/// Every distinct failure the voice pipeline can hit. The sheet maps each to a
/// reader-facing message; the original exception is always kept for the
/// diagnostics log so nothing collapses into a vague "unsupported device"
/// message.
enum VoiceError {
  permissionDenied,
  permissionPermanentlyDenied,
  microphoneUnavailable,
  microphoneInUse,
  insecureContext,
  browserRestricted,
  recordingUnavailable,
  emptyAudio,
  transcriptionFailed,
  network,
  authOrConfig,
  timeout,
  translationFailed,
  unknown,
}

/// Where the voice flow currently is. The sheet renders one UI per phase.
enum VoicePhase {
  idle,
  requestingPermission,
  recording,
  transcribing,
  translating,
  complete,
}

/// Microphone permission state as the pipeline understands it. The adapter
/// derives this from the platform permission API; the controller maps it to a
/// [VoiceError] when it blocks recording.
enum VoicePermissionState {
  unknown,
  requesting,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  hardwareUnavailable,
  browserUnavailable,
}

/// The real audio captured by the recorder. It is kept for the whole flow so a
/// failed transcription or translation can be retried without re-recording.
class VoiceRecording {
  final Uint8List bytes;
  final String mimeType;
  final String? path;
  final Duration duration;

  const VoiceRecording({
    required this.bytes,
    required this.mimeType,
    this.path,
    required this.duration,
  });

  int get sizeBytes => bytes.length;
}

/// A transcript plus the language the transcriber detected ('en' or 'am' when
/// known). Detection drives the translation direction.
class VoiceTranscript {
  final String text;
  final String? detectedLanguage;

  const VoiceTranscript(this.text, {this.detectedLanguage});
}

/// The result of the optional translation step.
class VoiceTranslation {
  final String text;

  const VoiceTranslation(this.text);
}

/// A pipeline error carrying both a reader-safe [VoiceError] and the technical
/// detail for the diagnostics log.
class VoicePipelineException implements Exception {
  final VoiceError error;
  final String detail;

  const VoicePipelineException(this.error, [this.detail = '']);

  @override
  String toString() => 'VoicePipelineException(${error.name}: $detail)';
}

/// Detects Amharic script in a text sample. Used to choose a translation
/// direction when the transcriber did not report a language.
bool detectAmharic(String text) {
  final sample = text.trim();
  if (sample.isEmpty) return false;
  var ethiopic = 0;
  var total = 0;
  for (final rune in sample.runes) {
    total++;
    if (rune >= 0x1200 && rune <= 0x137F) ethiopic++;
  }
  return total > 0 && ethiopic / total >= 0.2;
}