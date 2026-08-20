import 'dart:async';
import 'dart:convert';

import 'voice_error_mapper.dart';
import 'voice_models.dart';

/// The speech-to-text seam. The UI only ever depends on this abstraction; the
/// implementation can be the AI backend, an on-device recognizer, or anything
/// else that turns audio into text.
abstract class TranscriptionService {
  /// Whether the service can attempt a transcription right now.
  bool get isAvailable;

  /// The technical detail of the last failure, for diagnostics.
  String? get lastError;

  /// Transcribes [audio] into text. Throws a [VoicePipelineException] with a
  /// reader-safe [VoiceError] on failure.
  Future<VoiceTranscript> transcribe(VoiceRecording audio, {String? languageHint});
}

/// Primary transcription service: sends the recorded audio to the Gemini API
/// (inline data part) and asks for a verbatim transcript plus the detected
/// language. Language detection drives the optional translation step.
class GeminiTranscriptionService implements TranscriptionService {
  final Future<String> Function(
    String prompt, {
    required List<int> bytes,
    required String mimeType,
  }) transport;
  final Duration timeout;

  GeminiTranscriptionService({
    required this.transport,
    this.timeout = const Duration(seconds: 45),
  });

  String? _lastError;

  @override
  bool get isAvailable => true;

  @override
  String? get lastError => _lastError;

  @override
  Future<VoiceTranscript> transcribe(
    VoiceRecording audio, {
    String? languageHint,
  }) async {
    final prompt = _buildPrompt(languageHint);
    try {
      final raw =
          await transport(prompt, bytes: audio.bytes, mimeType: audio.mimeType)
              .timeout(timeout);
      final map = _decode(raw);
      final text = (map['transcript'] as String? ?? '').trim();
      if (text.isEmpty) {
        throw const VoicePipelineException(
          VoiceError.emptyAudio,
          'transcriber returned no transcript',
        );
      }
      return VoiceTranscript(
        text,
        detectedLanguage: _normaliseLanguage(map['language'], text),
      );
    } on VoicePipelineException {
      rethrow;
    } catch (e) {
      _lastError = e.toString();
      final error = VoiceErrorMapper.mapGeminiError(e);
      throw VoicePipelineException(error, e.toString());
    }
  }

  Map<String, dynamic> _decode(String raw) {
    final s = raw
        .trim()
        .replaceAll(RegExp(r'^```json\s*|\s*```$'), '')
        .trim();
    if (s.isEmpty) return const {};
    try {
      final decoded = jsonDecode(s);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // The model ignored the JSON instruction; treat the whole reply as the
      // transcript so a stubborn reply is never silently lost.
    }
    return {'transcript': s};
  }

  static String? _normaliseLanguage(Object? language, String text) {
    final l = (language?.toString() ?? '').toLowerCase();
    if (l.contains('amharic') || l == 'am' || l == 'amh' || l.contains('አማ')) {
      return 'am';
    }
    if (l.contains('english') || l == 'en' || l == 'eng') {
      return 'en';
    }
    return detectAmharic(text) ? 'am' : null;
  }

  String _buildPrompt(String? languageHint) {
    final langLine = switch (languageHint) {
      'am' => 'The speech is in Amharic.',
      'en' => 'The speech is in English.',
      _ => 'Detect whether the speech is in English or Amharic.',
    };
    return 'Transcribe the audio verbatim. $langLine '
        'Reply with ONLY JSON: {"transcript": "...", "language": "en" or "am"}. '
        'Do not summarize, translate, or add commentary. Preserve the exact words.';
  }
}

/// Fallback service used only when recording a file is impossible but a live
/// recognizer exists. It ignores [audio] and runs a live dictation session.
class StreamingFallbackTranscriptionService implements TranscriptionService {
  final Future<VoiceTranscript> Function() dictate;

  StreamingFallbackTranscriptionService({required this.dictate});

  String? _lastError;

  @override
  bool get isAvailable => true;

  @override
  String? get lastError => _lastError;

  @override
  Future<VoiceTranscript> transcribe(
    VoiceRecording audio, {
    String? languageHint,
  }) async {
    try {
      return await dictate();
    } catch (e) {
      _lastError = e.toString();
      throw VoicePipelineException(
        VoiceError.transcriptionFailed,
        e.toString(),
      );
    }
  }
}