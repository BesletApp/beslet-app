import 'dart:async';
import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../../secrets.dart';
import 'study_backend.dart';
import 'study_models.dart';
import 'study_prompt.dart';
import 'study_validator.dart';

/// The AI study backend. The *content* is produced by a model; the validator
/// stands between the model and the reader, and any failure (offline, quota,
/// malformed reply, no key, invalid content) yields null so the service can
/// fall back to silence. Never throws, never breaks rendering.
///
/// Transport is injected — production uses [buildGeminiTransport], tests use a
/// fake. The backend itself owns no keys, no models, no network.
class GeminiStudyBackend implements StudyBackend {
  final Future<String> Function(String prompt) transport;
  final StudyValidator validator;
  final StudyPromptBuilder promptBuilder;
  final Duration timeout;

  GeminiStudyBackend({
    required this.transport,
    required this.validator,
    this.promptBuilder = const StudyPromptBuilder(),
    this.timeout = const Duration(seconds: 60),
  });

  @override
  Future<StudyResult?> study(StudyRequest request) async {
    try {
      final prompt = promptBuilder.build(request);
      final raw = await transport(prompt).timeout(timeout);
      if (raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return validator.validate(raw: decoded, request: request);
    } catch (_) {
      return null;
    }
  }
}

/// Builds the production transport: an API key (user-provided, else the
/// bundled free-tier key) with a Flash model and JSON structured output.
Future<String> Function(String prompt) buildGeminiTransport({
  String? bundledKey,
  Future<String?> Function() userKeyProvider = _noUserKey,
  String modelName = aiModelName,
  Duration timeout = const Duration(seconds: 45),
}) {
  return (prompt) async {
    final key = await _effectiveKey(bundledKey, userKeyProvider);
    if (key == null) throw StateError('no API key');
    final model = GenerativeModel(model: modelName, apiKey: key);
    final schema = Schema.object(
      properties: {
        'setting': Schema.object(properties: {
          'text': Schema.string(description: 'One or two sentences anchoring the passage.'),
        }),
        'context': Schema.object(properties: {
          'behindTheText': Schema.string(description: 'Author, audience, setting.'),
          'inTheText': Schema.string(description: 'Immediate context and argument.'),
        }),
        'whatTextSays': Schema.object(properties: {
          'text': Schema.string(description: 'A plain tracing of what the passage says.'),
        }),
        'meaningBackground': Schema.object(properties: {
          'text': Schema.string(
              description: 'Meaning, key terms, and historical/cultural/theological background, with textual observations.'),
          'terms': Schema.array(
            items: Schema.object(properties: {
              'term': Schema.string(
                  description: 'The important term or original-language word in its own script.'),
              'language': Schema.string(
                  description: 'e.g. hebrew, aramaic, greek, amharic, english.'),
              'transliteration': Schema.string(
                  description: 'Pronunciation guide, when useful.'),
              'meaning': Schema.string(
                  description: 'Short meaning in the reader\'s language, anchored in this passage.'),
            }),
          ),
        }),
        'biblicalConnections': Schema.object(properties: {
          'items': Schema.array(
            items: Schema.object(properties: {
              'bookId': Schema.string(description: 'Canonical book id from the list.'),
              'chapter': Schema.integer(),
              'startVerse': Schema.integer(),
              'endVerse': Schema.integer(),
              'priority': Schema.integer(description: '0 = essential, 1 = helpful, 2 = supporting.'),
              'reason': Schema.string(description: 'One-clause reason.'),
            }),
          ),
        }),
        'whatCanBeUnderstood': Schema.object(properties: {
          'blocks': Schema.array(
            items: Schema.object(properties: {
              'tier': Schema.string(description: 'clearlyStated | supportedUnderstanding | disputed'),
              'text': Schema.string(description: 'One careful interpretive observation.'),
            }),
          ),
        }),
        'reflection': Schema.object(properties: {
          'text': Schema.string(description: 'One open-ended question ending with "?".'),
        }),
      },
    );
    final response = await model.generateContent(
      [Content.text(prompt)],
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    ).timeout(timeout);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw StateError('empty model response');
    }
    return text;
  };
}

Future<String?> _noUserKey() async => null;

Future<String?> _effectiveKey(
    String? bundledKey, Future<String?> Function() userKeyProvider) async {
  try {
    final user = await userKeyProvider();
    if (user != null && user.trim().isNotEmpty) return user.trim();
  } catch (_) {}
  final k = bundledKey;
  if (k == null || k.isEmpty || k.contains('YOUR_API_KEY')) return null;
  return k;
}