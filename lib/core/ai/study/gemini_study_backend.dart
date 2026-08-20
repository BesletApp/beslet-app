import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../secrets.dart';
import 'study_backend.dart';
import 'study_diagnostics.dart';
import 'study_models.dart';
import 'study_prompt.dart';
import 'study_validator.dart';

/// A typed failure the study chain can classify instead of collapsing every
/// error to a silent null. [reason] maps to a reader-facing explanation.
class StudyGeminiException implements Exception {
  final StudyUnavailability reason;
  final String detail;

  const StudyGeminiException(this.reason, [this.detail = '']);

  @override
  String toString() => 'StudyGeminiException(${reason.name}: $detail)';
}

/// The AI study backend. The *content* is produced by a model; the validator
/// stands between the model and the reader. Unlike the previous design — which
/// turned every failure into an invisible null and a silent offline fallback —
/// an attempt now returns a [StudyAttempt] with the concrete reason for the
/// failure, so the panel can always explain why AI study was unavailable.
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
  Future<StudyAttempt> study(StudyRequest request) async {
    try {
      final prompt = promptBuilder.build(request);
      final raw = await transport(prompt).timeout(timeout);
      if (raw.trim().isEmpty) {
        throw const StudyGeminiException(
            StudyUnavailability.contentRejected, 'empty model response');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const StudyGeminiException(
            StudyUnavailability.contentRejected, 'reply was not a JSON object');
      }
      final validated = validator.validate(raw: decoded, request: request);
      if (validated == null) {
        final detail = 'reply failed the study validator';
        StudyDiagnostics.instance.record(
          failureReason: StudyUnavailability.contentRejected,
          failureDetail: detail,
          payloadSnippet: raw.trim().length <= 160
              ? raw.trim()
              : '${raw.trim().substring(0, 160)}…',
        );
        developer.log('study: validator rejected reply', name: 'study');
        throw StudyGeminiException(
            StudyUnavailability.contentRejected, detail);
      }
      StudyDiagnostics.instance.record(failureReason: null);
      return StudyAttempt.available(validated);
    } on StudyGeminiException catch (e) {
      if (e.reason == StudyUnavailability.contentRejected &&
          (StudyDiagnostics.instance.failureReason != e.reason ||
              StudyDiagnostics.instance.payloadSnippet == null)) {
        StudyDiagnostics.instance.record(
          failureReason: e.reason,
          failureDetail: e.detail,
        );
      }
      developer.log('study: AI ${e.reason.name}: ${e.detail}', name: 'study');
      return StudyAttempt.unavailable(e.reason);
    } catch (e) {
      final reason = _classify(e);
      developer.log('study: AI ${reason.name}: $e', name: 'study');
      return StudyAttempt.unavailable(reason);
    }
  }

  /// Maps a raw transport/network/API exception to a [StudyUnavailability].
  static StudyUnavailability _classify(Object error) {
    if (error is TimeoutException) return StudyUnavailability.timeout;
    if (error is FormatException) return StudyUnavailability.contentRejected;
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is FileSystemException) {
      return StudyUnavailability.offline;
    }
    if (error is InvalidApiKey) return StudyUnavailability.authInvalid;
    if (error is UnsupportedUserLocation) return StudyUnavailability.authInvalid;
    if (error is ServerException) {
      final message = error.message.toLowerCase();
      if (message.contains('401') || message.contains('403')) {
        return StudyUnavailability.authInvalid;
      }
      if (message.contains('429') ||
          message.contains('quota') ||
          message.contains('rate') ||
          message.contains('exhausted')) {
        return StudyUnavailability.rateLimited;
      }
      return StudyUnavailability.server;
    }
    if (error is StateError && error.message.contains('no API key')) {
      return StudyUnavailability.authInvalid;
    }
    return StudyUnavailability.server;
  }
}

/// Verifies that a personal Gemini key is usable by making one tiny
/// content-generation probe. This is *not* a study prompt and produces no
/// study content — it only confirms the key authenticates and can reach the
/// model. Throws a [StudyGeminiException] with the classified reason when the
/// key is invalid or unreachable.
Future<void> verifyGeminiKey(
  String apiKey, {
  String modelName = aiModelName,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final key = apiKey.trim();
  if (key.isEmpty) {
    throw const StudyGeminiException(
        StudyUnavailability.authInvalid, 'empty key');
  }
  try {
    final model = GenerativeModel(model: modelName, apiKey: key);
    final response = await model
        .generateContent([Content.text('Reply with exactly: OK')])
        .timeout(timeout);
    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw const StudyGeminiException(
          StudyUnavailability.server, 'empty verification reply');
    }
  } on StudyGeminiException {
    rethrow;
  } catch (e) {
    throw StudyGeminiException(GeminiStudyBackend._classify(e), '$e');
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
    if (key == null) {
      StudyDiagnostics.instance.record(keySource: 'none', keyLength: null);
      throw StateError('no API key');
    }
    String? userKey;
    try {
      userKey = await userKeyProvider();
    } catch (_) {}
    final source = (userKey != null && userKey.trim().isNotEmpty)
        ? 'user'
        : 'bundled';
    StudyDiagnostics.instance.record(
      keySource: source,
      keyLength: key.length,
    );
    developer.log('study: request with $source key (${key.length} chars)',
        name: 'study');
    final model = GenerativeModel(model: modelName, apiKey: key);
    final startedAt = DateTime.now();
    var status = '';
    try {
      developer.log('study: transport: sending to $modelName', name: 'study');
      final response = await model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      ).timeout(timeout);
      developer.log('study: transport: HTTP 200 received', name: 'study');
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw StateError('empty model response');
      }
      StudyDiagnostics.instance.record(
        keySource: source,
        keyLength: key.length,
        httpStatus: '200',
      );
      developer.log(
          'study: ok in ${DateTime.now().difference(startedAt).inMilliseconds}ms '
          '(${text.length} bytes)',
          name: 'study');
      return text;
    } catch (e) {
      status = _httpStatusFor(error: e);
      StudyDiagnostics.instance.record(
        keySource: source,
        keyLength: key.length,
        httpStatus: status,
        failureDetail: e.toString(),
      );
      developer.log('study: transport failed ($status): $e', name: 'study');
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
    if (m.contains('429')) return '429';
    return 'server';
  }
  return 'unknown';
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
