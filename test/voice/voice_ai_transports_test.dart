import 'package:beslet_app/core/secrets.dart';
import 'package:beslet_app/core/voice/voice_ai_transports.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

GenerateContentResponse _jsonResponse(String json) => GenerateContentResponse(
      [
        Candidate(
          Content('model', [TextPart(json)]),
          null,
          null,
          FinishReason.stop,
          null,
        ),
      ],
      null,
    );

/// Captures the model name, api key, contents, and config of every injected
/// model call so tests can assert the transport wiring without a network.
class _RecordingFactory {
  _RecordingFactory(this.json);

  final String json;
  final calls = <({
    String modelName,
    String apiKey,
    List<Content> contents,
    GenerationConfig? generationConfig,
  })>[];

  GeminiModelRequest call(String modelName, String apiKey) {
    return (contents, {generationConfig}) {
      calls.add((
        modelName: modelName,
        apiKey: apiKey,
        contents: List<Content>.of(contents),
        generationConfig: generationConfig,
      ));
      return Future.value(_jsonResponse(json));
    };
  }
}

void main() {
  group('buildGeminiAudioTransport', () {
    test('uses the bundled key and sends audio inline with JSON output', () async {
      final stub = _RecordingFactory('{"transcript":"hello","language":"en"}');
      final transport = buildGeminiAudioTransport(
        bundledKey: 'bundled-key-123',
        modelFactory: stub.call,
      );

      final text = await transport('transcribe this',
          bytes: [1, 2, 3], mimeType: 'audio/wav');

      expect(text, contains('"transcript"'));
      expect(stub.calls, hasLength(1));
      final call = stub.calls.single;
      expect(call.apiKey, 'bundled-key-123');
      expect(call.modelName, aiModelName);
      expect(call.generationConfig?.responseMimeType, 'application/json');
      final parts = call.contents.single.parts;
      expect(parts, hasLength(2));
      expect(parts[0], isA<DataPart>());
      final data = parts[0] as DataPart;
      expect(data.mimeType, 'audio/wav');
      expect(data.bytes, [1, 2, 3]);
      expect(parts[1], isA<TextPart>());
      expect((parts[1] as TextPart).text, 'transcribe this');
    });

    test('throws a StateError when no usable key is supplied', () async {
      final transport = buildGeminiAudioTransport();
      await expectLater(
        transport('hi', bytes: [1], mimeType: 'audio/wav'),
        throwsStateError,
      );
    });

    test('a user-provided key takes precedence over the bundled key', () async {
      final stub = _RecordingFactory('{"transcript":"hi","language":"en"}');
      final transport = buildGeminiAudioTransport(
        bundledKey: 'bundled-key-123',
        userKeyProvider: () async => 'user-key-456',
        modelFactory: stub.call,
      );

      await transport('hi', bytes: [1], mimeType: 'audio/wav');

      expect(stub.calls.single.apiKey, 'user-key-456');
    });
  });

  group('buildGeminiTextTransport', () {
    test('uses the bundled key for the text call', () async {
      final stub = _RecordingFactory('{"translated":"salem"}');
      final transport = buildGeminiTextTransport(
        bundledKey: 'bundled-key-123',
        modelFactory: stub.call,
      );

      final text = await transport('translate this');

      expect(text, contains('"translated"'));
      final call = stub.calls.single;
      expect(call.apiKey, 'bundled-key-123');
      expect(call.modelName, aiModelName);
      expect(call.generationConfig?.responseMimeType, 'application/json');
      final parts = call.contents.single.parts;
      expect(parts, hasLength(1));
      expect((parts.single as TextPart).text, 'translate this');
    });
  });
}