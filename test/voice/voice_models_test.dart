import 'dart:typed_data';

import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detectAmharic', () {
    test('rejects empty and plain latin text', () {
      expect(detectAmharic(''), isFalse);
      expect(detectAmharic('   '), isFalse);
      expect(detectAmharic('Hello world'), isFalse);
    });

    test('accepts pure Ethiopic text', () {
      expect(detectAmharic('ሰላም እንዴት ነህ'), isTrue);
    });

    test('accepts mixed text with enough Ethiopic script', () {
      expect(detectAmharic('Hello ሰላም ነው'), isTrue);
    });

    test('rejects a tiny Ethiopic sprinkle', () {
      expect(detectAmharic('AAAA ሰ'), isFalse);
    });
  });

  group('VoiceRecording', () {
    test('reports its byte size', () {
      final r = VoiceRecording(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        mimeType: 'audio/wav',
        duration: const Duration(seconds: 1),
      );
      expect(r.sizeBytes, 4);
    });
  });

  group('VoicePipelineException', () {
    test('carries a reader-safe error and technical detail', () {
      const e = VoicePipelineException(VoiceError.network, 'socket closed');
      expect(e.error, VoiceError.network);
      expect(e.detail, 'socket closed');
      expect(e.toString(), contains('network'));
    });
  });
}