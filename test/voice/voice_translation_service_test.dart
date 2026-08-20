import 'dart:async';

import 'package:beslet_app/core/voice/translation_service.dart';
import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  group('GeminiTranslationService', () {
    test('parses JSON and targets the requested language', () async {
      String? prompt;
      final service = GeminiTranslationService(transport: (p) async {
        prompt = p;
        return '{"translated": "salem"}';
      });
      final r = await service.translate(
        text: 'ሰላም',
        sourceLanguage: 'am',
        targetLanguage: 'en',
      );
      expect(r.text, 'salem');
      expect(prompt, contains('English'));
    });

    test('an amharic target is named', () async {
      String? prompt;
      final service = GeminiTranslationService(transport: (p) async {
        prompt = p;
        return '{"translated": "ሰላም"}';
      });
      await service.translate(
        text: 'Hello',
        sourceLanguage: 'en',
        targetLanguage: 'am',
      );
      expect(prompt, contains('Amharic'));
    });

    test('a stubborn non-JSON reply is kept whole', () async {
      final service = GeminiTranslationService(transport: (p) async => 'salem beza');
      expect(
        (await service.translate(
          text: 'x',
          sourceLanguage: 'en',
          targetLanguage: 'am',
        ))
            .text,
        'salem beza',
      );
    });

    test('an empty result is a translationFailed error', () async {
      final service = GeminiTranslationService(transport: (p) async => '{}');
      await expectLater(
        service.translate(
          text: 'x',
          sourceLanguage: 'en',
          targetLanguage: 'am',
        ),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.translationFailed)),
      );
    });

    test('a timeout maps to timeout', () async {
      final service = GeminiTranslationService(transport: (p) async {
        throw TimeoutException('slow');
      });
      await expectLater(
        service.translate(
          text: 'x',
          sourceLanguage: 'en',
          targetLanguage: 'am',
        ),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.timeout)),
      );
    });

    test('a server failure maps to the translation fallback', () async {
      final service = GeminiTranslationService(transport: (p) async {
        throw ServerException('500 internal');
      });
      await expectLater(
        service.translate(
          text: 'x',
          sourceLanguage: 'en',
          targetLanguage: 'am',
        ),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.translationFailed)),
      );
    });
  });
}