import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../secrets.dart';
import 'delve_diagnostics.dart';
import 'delve_models.dart';
import 'delve_prompt.dart';
import 'delve_validator.dart';

/// A typed failure the deep-study chain can classify instead of collapsing
/// every error to a silent null. [reason] maps to a reader-facing explanation.
class DelveGeminiException implements Exception {
  final DelveUnavailability reason;
  final String detail;

  const DelveGeminiException(this.reason, [this.detail = '']);

  @override
  String toString() => 'DelveGeminiException(${reason.name}: $detail)';
}

/// The "Delve Deeper" AI backend. The content is produced by a model on demand;
/// the [DelveValidator] stands between the model and the reader. Every attempt
/// returns a [DelveAttempt] with the concrete reason for a failure so the panel
/// can always explain why the deep study was unavailable.
class DelveBackend {
  final Future<String> Function(String prompt) transport;
  final DelveValidator validator;
  final DelvePromptBuilder promptBuilder;
  final Duration timeout;

  DelveBackend({
    required this.transport,
    required this.validator,
    this.promptBuilder = const DelvePromptBuilder(),
    this.timeout = const Duration(seconds: 60),
  });

  Future<DelveAttempt> delve(DelveRequest request) async {
    try {
      final prompt = promptBuilder.build(request);
      final raw = await transport(prompt).timeout(timeout);
      if (raw.trim().isEmpty) {
        throw const DelveGeminiException(
            DelveUnavailability.contentRejected, 'empty model response');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const DelveGeminiException(
            DelveUnavailability.contentRejected, 'reply was not a JSON object');
      }
      final validated = validator.validate(raw: decoded, request: request);
      if (validated == null) {
        final detail = 'reply failed the delve validator';
        DelveDiagnostics.instance.record(
          failureReason: DelveUnavailability.contentRejected,
          failureDetail: detail,
          payloadSnippet: raw.trim().length <= 160
              ? raw.trim()
              : '${raw.trim().substring(0, 160)}…',
        );
        developer.log('delve: validator rejected reply', name: 'delve');
        throw DelveGeminiException(
            DelveUnavailability.contentRejected, detail);
      }
      DelveDiagnostics.instance.record(failureReason: null);
      return DelveAttempt.available(validated);
    } on DelveGeminiException catch (e) {
      if (e.reason == DelveUnavailability.contentRejected &&
          (DelveDiagnostics.instance.failureReason != e.reason ||
              DelveDiagnostics.instance.payloadSnippet == null)) {
        DelveDiagnostics.instance.record(
          failureReason: e.reason,
          failureDetail: e.detail,
        );
      }
      developer.log('delve: AI ${e.reason.name}: ${e.detail}', name: 'delve');
      return DelveAttempt.unavailable(e.reason);
    } catch (e) {
      final reason = _classify(e);
      developer.log('delve: AI ${reason.name}: $e', name: 'delve');
      return DelveAttempt.unavailable(reason);
    }
  }

  /// Maps a raw transport/network/API exception to a [DelveUnavailability].
  static DelveUnavailability _classify(Object error) {
    if (error is TimeoutException) return DelveUnavailability.timeout;
    if (error is FormatException) return DelveUnavailability.contentRejected;
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is FileSystemException) {
      return DelveUnavailability.offline;
    }
    if (error is InvalidApiKey) return DelveUnavailability.authInvalid;
    if (error is UnsupportedUserLocation) return DelveUnavailability.authInvalid;
    if (error is ServerException) {
      final message = error.message.toLowerCase();
      if (message.contains('401') || message.contains('403')) {
        return DelveUnavailability.authInvalid;
      }
      if (message.contains('429') ||
          message.contains('quota') ||
          message.contains('rate') ||
          message.contains('exhausted')) {
        return DelveUnavailability.rateLimited;
      }
      return DelveUnavailability.server;
    }
    if (error is StateError && error.message.contains('no API key')) {
      return DelveUnavailability.authInvalid;
    }
    return DelveUnavailability.server;
  }
}

/// Builds the production deep-study transport: an API key (user-provided, else
/// the bundled free-tier key) with a Flash model and JSON structured output.
/// Same seam as the Study transport, but it records to [DelveDiagnostics] so
/// the two layers never confuse their observability.
Future<String> Function(String prompt) buildDelveTransport({
  String? bundledKey,
  Future<String?> Function() userKeyProvider = _noUserKey,
  String modelName = aiModelName,
  Duration timeout = const Duration(seconds: 45),
}) {
  return (prompt) async {
    final key = await _effectiveKey(bundledKey, userKeyProvider);
    if (key == null) {
      DelveDiagnostics.instance.record(keySource: 'none', keyLength: null);
      throw StateError('no API key');
    }
    String? userKey;
    try {
      userKey = await userKeyProvider();
    } catch (_) {}
    final source = (userKey != null && userKey.trim().isNotEmpty)
        ? 'user'
        : 'bundled';
    DelveDiagnostics.instance.record(
      keySource: source,
      keyLength: key.length,
    );
    developer.log(
        'delve: request with $source key (${key.length} chars)', name: 'delve');
    final model = GenerativeModel(model: modelName, apiKey: key);
    final startedAt = DateTime.now();
    try {
      developer.log('delve: transport: sending to $modelName', name: 'delve');
      final response = await model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      ).timeout(timeout);
      developer.log('delve: transport: HTTP 200 received', name: 'delve');
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw StateError('empty model response');
      }
      DelveDiagnostics.instance.record(
        keySource: source,
        keyLength: key.length,
        httpStatus: '200',
      );
      developer.log(
          'delve: ok in ${DateTime.now().difference(startedAt).inMilliseconds}ms '
          '(${text.length} bytes)',
          name: 'delve');
      return text;
    } catch (e) {
      final status = _httpStatusFor(error: e);
      DelveDiagnostics.instance.record(
        keySource: source,
        keyLength: key.length,
        httpStatus: status,
        failureDetail: e.toString(),
      );
      developer.log('delve: transport failed ($status): $e', name: 'delve');
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