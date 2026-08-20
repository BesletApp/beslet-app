import 'dart:async';
import 'dart:convert';

import 'voice_error_mapper.dart';
import 'voice_models.dart';

/// The translation seam. Translation is always an optional step that runs
/// *after* transcription; a failure here must never lose the original
/// transcript.
abstract class TranslationService {
  /// Translates [text] from [sourceLanguage] to [targetLanguage] ('en'/'am').
  /// Throws a [VoicePipelineException] with a reader-safe [VoiceError] on
  /// failure.
  Future<VoiceTranslation> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  });
}

/// Production translation service backed by the Gemini API (text-only call).
class GeminiTranslationService implements TranslationService {
  final Future<String> Function(String prompt) transport;
  final Duration timeout;

  GeminiTranslationService({
    required this.transport,
    this.timeout = const Duration(seconds: 30),
  });

  @override
  Future<VoiceTranslation> translate({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final targetName = targetLanguage == 'am' ? 'Amharic' : 'English';
    final prompt = 'Translate the following text into $targetName. '
        'Keep the meaning and tone. Reply with ONLY JSON: {"translated": "..."}. '
        'Do not add commentary.\n\nText:\n$text';
    try {
      final raw = await transport(prompt).timeout(timeout);
      final map = _decode(raw);
      final translated = (map['translated'] as String? ?? '').trim();
      if (translated.isEmpty) {
        throw const VoicePipelineException(
          VoiceError.translationFailed,
          'translator returned an empty result',
        );
      }
      return VoiceTranslation(translated);
    } on VoicePipelineException {
      rethrow;
    } catch (e) {
      throw VoicePipelineException(
        VoiceErrorMapper.mapGeminiError(e, fallback: VoiceError.translationFailed),
        e.toString(),
      );
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
      // Ignore JSON parsing issues; fall through to the raw-text heuristic.
    }
    return {'translated': s};
  }
}