import 'dart:async';
import 'dart:typed_data';

import 'package:beslet_app/core/voice/transcription_service.dart';
import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

VoiceRecording _audio() => VoiceRecording(
      bytes: Uint8List.fromList(List.filled(3200, 0)),
      mimeType: 'audio/wav',
      path: 'fake.wav',
      duration: const Duration(milliseconds: 500),
    );

void main() {
  group('GeminiTranscriptionService', () {
    test('parses JSON with transcript and language', () async {
      String? prompt;
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        prompt = p;
        return '{"transcript": "Hello there", "language": "en"}';
      });
      final t = await service.transcribe(_audio());
      expect(t.text, 'Hello there');
      expect(t.detectedLanguage, 'en');
      expect(prompt, contains('Detect whether the speech is in English or Amharic.'));
    });

    test('languageHint am reaches the prompt', () async {
      String? prompt;
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        prompt = p;
        return '{"transcript": "ሰላም", "language": "am"}';
      });
      final t = await service.transcribe(_audio(), languageHint: 'am');
      expect(t.detectedLanguage, 'am');
      expect(prompt, contains('Amharic'));
    });

    test('an amharic report normalises to am', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        return '{"transcript": "ሰላም", "language": "amharic"}';
      });
      expect((await service.transcribe(_audio())).detectedLanguage, 'am');
    });

    test('missing language falls back to a script sniff', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        return '{"transcript": "ሰላም እንዴት"}';
      });
      expect((await service.transcribe(_audio())).detectedLanguage, 'am');
    });

    test('a stubborn non-JSON reply is kept whole', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        return 'Plain words the model refused to wrap';
      });
      final t = await service.transcribe(_audio());
      expect(t.text, 'Plain words the model refused to wrap');
      expect(t.detectedLanguage, isNull);
    });

    test('code-fenced JSON is stripped', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        return '```json\n{"transcript": "fenced", "language": "en"}\n```';
      });
      expect((await service.transcribe(_audio())).text, 'fenced');
    });

    test('an empty transcript is a reader-safe emptyAudio error', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        return '{"language": "en"}';
      });
      await expectLater(
        service.transcribe(_audio()),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.emptyAudio)),
      );
    });

    test('maps a transport timeout to timeout', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        throw TimeoutException('slow');
      });
      await expectLater(
        service.transcribe(_audio()),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.timeout)),
      );
    });

    test('maps a missing key to authOrConfig', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        throw StateError('no API key');
      });
      await expectLater(
        service.transcribe(_audio()),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.authOrConfig)),
      );
    });

    test('maps a 429 to timeout and records the technical error', () async {
      final service = GeminiTranscriptionService(transport: (p, {required bytes, required mimeType}) async {
        throw ServerException('429 Too Many Requests');
      });
      await expectLater(
        service.transcribe(_audio()),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.timeout)),
      );
      expect(service.lastError, isNotNull);
    });
  });

  group('StreamingFallbackTranscriptionService', () {
    test('returns the dictation result', () async {
      final service = StreamingFallbackTranscriptionService(
        dictate: () async => const VoiceTranscript('live words', detectedLanguage: 'en'),
      );
      final t = await service.transcribe(_audio());
      expect(t.text, 'live words');
    });

    test('a dictation failure becomes transcriptionFailed', () async {
      final service = StreamingFallbackTranscriptionService(
        dictate: () async => throw Exception('engine died'),
      );
      await expectLater(
        service.transcribe(_audio()),
        throwsA(isA<VoicePipelineException>()
            .having((e) => e.error, 'error', VoiceError.transcriptionFailed)),
      );
    });
  });
}