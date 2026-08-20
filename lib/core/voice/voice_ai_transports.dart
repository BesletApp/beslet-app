import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../secrets.dart';
import 'voice_diagnostics.dart';

/// A single model call, separated from the transport so tests can stub the
/// network. The default returns a real [GenerativeModel] backed request.
typedef GeminiModelRequest = Future<GenerateContentResponse> Function(
  List<Content> contents, {
  GenerationConfig? generationConfig,
});

/// Builds a [GeminiModelRequest] for the given model name and API key.
/// Injectable so tests can assert the key and payload without a network call.
typedef GeminiModelFactory =
    GeminiModelRequest Function(String modelName, String apiKey);

GeminiModelRequest _defaultModelFactory(String modelName, String apiKey) {
  final model = GenerativeModel(model: modelName, apiKey: apiKey);
  return (contents, {generationConfig}) =>
      model.generateContent(contents, generationConfig: generationConfig);
}

/// Builds the production audio-transcription transport: an API key
/// (user-provided, else the bundled free-tier key) with the Flash model, the
/// audio bytes sent inline as a data part, and a JSON response. Mirrors the
/// voice-journal transport so the pipeline records its own observability.
Future<String> Function(
  String prompt, {
  required List<int> bytes,
  required String mimeType,
}) buildGeminiAudioTransport({
  String? bundledKey,
  Future<String?> Function() userKeyProvider = _noUserKey,
  String modelName = aiModelName,
  Duration timeout = const Duration(seconds: 45),
  GeminiModelFactory? modelFactory,
}) {
  return (prompt, {required bytes, required mimeType}) async {
    final key = await _effectiveKey(bundledKey, userKeyProvider);
    if (key == null) {
      VoiceDiagnostics.instance.record(
        lastError: 'authOrConfig',
        lastTechnicalError: 'no API key',
      );
      throw StateError('no API key');
    }
    final userKey = await _readUserKey(userKeyProvider);
    final source = (userKey != null && userKey.trim().isNotEmpty) ? 'user' : 'bundled';
    VoiceDiagnostics.instance.record(
      phase: 'transcribing',
      selectedMimeType: mimeType,
      lastTechnicalError: null,
    );
    developer.log(
        'voice: audio transcription with $source key (${key.length} chars)',
        name: 'voice');
    final request = (modelFactory ?? _defaultModelFactory)(modelName, key);
    final startedAt = DateTime.now();
    try {
      final response = await request(
        [
          Content('user', [
            DataPart(mimeType, Uint8List.fromList(bytes)),
            TextPart(prompt),
          ]),
        ],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      ).timeout(timeout);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw StateError('empty model response');
      }
      VoiceDiagnostics.instance.record(
        transcriptionOk: true,
        transcriptionMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
      developer.log(
          'voice: audio transcription ok in '
          '${DateTime.now().difference(startedAt).inMilliseconds}ms (${text.length} bytes)',
          name: 'voice');
      return text;
    } catch (e) {
      final status = _httpStatusFor(error: e);
      VoiceDiagnostics.instance.record(
        transcriptionOk: false,
        transcriptionMs: DateTime.now().difference(startedAt).inMilliseconds,
        transcriptionError: status,
        lastTechnicalError: e.toString(),
      );
      developer.log('voice: audio transcription failed ($status): $e', name: 'voice');
      rethrow;
    }
  };
}

/// Builds the production text-only transport used by the translation step.
Future<String> Function(String prompt) buildGeminiTextTransport({
  String? bundledKey,
  Future<String?> Function() userKeyProvider = _noUserKey,
  String modelName = aiModelName,
  Duration timeout = const Duration(seconds: 30),
  GeminiModelFactory? modelFactory,
}) {
  return (prompt) async {
    final key = await _effectiveKey(bundledKey, userKeyProvider);
    if (key == null) throw StateError('no API key');
    VoiceDiagnostics.instance.record(
      phase: 'translating',
      lastTechnicalError: null,
    );
    final request = (modelFactory ?? _defaultModelFactory)(modelName, key);
    final startedAt = DateTime.now();
    try {
      final response = await request(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      ).timeout(timeout);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw StateError('empty model response');
      }
      VoiceDiagnostics.instance.record(
        translationOk: true,
        translationMs: DateTime.now().difference(startedAt).inMilliseconds,
      );
      developer.log(
          'voice: translation ok in '
          '${DateTime.now().difference(startedAt).inMilliseconds}ms (${text.length} bytes)',
          name: 'voice');
      return text;
    } catch (e) {
      final status = _httpStatusFor(error: e);
      VoiceDiagnostics.instance.record(
        translationOk: false,
        translationMs: DateTime.now().difference(startedAt).inMilliseconds,
        translationError: status,
        lastTechnicalError: e.toString(),
      );
      developer.log('voice: translation failed ($status): $e', name: 'voice');
      rethrow;
    }
  };
}

String _httpStatusFor({Object? error, String message = ''}) {
  if (error is TimeoutException) return 'timeout';
  if (error is ServerException) {
    final m = '${error.message} $message'.toLowerCase();
    if (m.contains('400')) return '400';
    if (m.contains('401')) return '401';
    if (m.contains('403')) return '403';
    if (m.contains('404')) return '404';
    if (m.contains('429')) return '429';
    return 'server';
  }
  return 'unknown';
}

Future<String?> _noUserKey() async => null;

Future<String?> _readUserKey(Future<String?> Function() provider) async {
  try {
    return await provider();
  } catch (_) {
    return null;
  }
}

Future<String?> _effectiveKey(
    String? bundledKey, Future<String?> Function() userKeyProvider) async {
  final user = await _readUserKey(userKeyProvider);
  if (user != null && user.trim().isNotEmpty) return user.trim();
  final key = bundledKey;
  if (key == null || key.isEmpty || key.contains('YOUR_API_KEY')) return null;
  return key;
}