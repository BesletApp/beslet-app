import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import '../../secrets.dart';
import 'voice_journal_diagnostics.dart';
import 'voice_journal_models.dart';
import 'voice_journal_prompt.dart';
import 'voice_journal_validator.dart';

/// A typed failure the voice-journal chain can classify instead of collapsing
/// every error to a silent null. [reason] maps to a reader-facing explanation.
class VoiceJournalGeminiException implements Exception {
  final VoiceJournalUnavailability reason;
  final String detail;

  const VoiceJournalGeminiException(this.reason, [this.detail = '']);

  @override
  String toString() => 'VoiceJournalGeminiException(${reason.name}: $detail)';
}

/// The "Voice Journal" AI backend. The organized journal is produced by a model
/// on demand; the [VoiceJournalValidator] stands between the model and the
/// reader. Every attempt returns a [VoiceJournalAttempt] with the concrete
/// reason for a failure so the sheet can always explain why organizing was
/// unavailable.
class VoiceJournalBackend {
  final Future<String> Function(String prompt) transport;
  final VoiceJournalValidator validator;
  final VoiceJournalPromptBuilder promptBuilder;
  final Duration timeout;

  VoiceJournalBackend({
    required this.transport,
    required this.validator,
    this.promptBuilder = const VoiceJournalPromptBuilder(),
    this.timeout = const Duration(seconds: 45),
  });

  Future<VoiceJournalAttempt> organize(VoiceJournalRequest request) async {
    try {
      final prompt = promptBuilder.build(request);
      final raw = await transport(prompt).timeout(timeout);
      if (raw.trim().isEmpty) {
        throw const VoiceJournalGeminiException(
            VoiceJournalUnavailability.contentRejected, 'empty model response');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw const VoiceJournalGeminiException(
            VoiceJournalUnavailability.contentRejected,
            'reply was not a JSON object');
      }
      final validated = validator.validate(raw: decoded, request: request);
      if (validated == null) {
        final detail = 'reply failed the voice-journal validator';
        VoiceJournalDiagnostics.instance.record(
          failureReason: VoiceJournalUnavailability.contentRejected,
          failureDetail: detail,
          payloadSnippet: raw.trim().length <= 160
              ? raw.trim()
              : '${raw.trim().substring(0, 160)}…',
        );
        developer.log(
            'voice_journal: validator rejected reply', name: 'voice_journal');
        throw VoiceJournalGeminiException(
            VoiceJournalUnavailability.contentRejected, detail);
      }
      VoiceJournalDiagnostics.instance.record(failureReason: null);
      return VoiceJournalAttempt.available(validated);
    } on VoiceJournalGeminiException catch (e) {
      if (e.reason == VoiceJournalUnavailability.contentRejected &&
          (VoiceJournalDiagnostics.instance.failureReason != e.reason ||
              VoiceJournalDiagnostics.instance.payloadSnippet == null)) {
        VoiceJournalDiagnostics.instance.record(
          failureReason: e.reason,
          failureDetail: e.detail,
        );
      }
      developer.log('voice_journal: AI ${e.reason.name}: ${e.detail}',
          name: 'voice_journal');
      return VoiceJournalAttempt.unavailable(e.reason);
    } catch (e) {
      final reason = _classify(e);
      developer.log('voice_journal: AI ${reason.name}: $e',
          name: 'voice_journal');
      return VoiceJournalAttempt.unavailable(reason);
    }
  }

  /// Maps a raw transport/network/API exception to a [VoiceJournalUnavailability].
  static VoiceJournalUnavailability _classify(Object error) {
    if (error is TimeoutException) return VoiceJournalUnavailability.timeout;
    if (error is FormatException) return VoiceJournalUnavailability.contentRejected;
    if (error is SocketException ||
        error is http.ClientException ||
        error is HandshakeException ||
        error is FileSystemException) {
      return VoiceJournalUnavailability.offline;
    }
    if (error is InvalidApiKey) return VoiceJournalUnavailability.authInvalid;
    if (error is UnsupportedUserLocation) {
      return VoiceJournalUnavailability.authInvalid;
    }
    if (error is ServerException) {
      final message = error.message.toLowerCase();
      if (message.contains('401') || message.contains('403')) {
        return VoiceJournalUnavailability.authInvalid;
      }
      if (message.contains('429') ||
          message.contains('quota') ||
          message.contains('rate') ||
          message.contains('exhausted')) {
        return VoiceJournalUnavailability.rateLimited;
      }
      return VoiceJournalUnavailability.server;
    }
    if (error is StateError && error.message.contains('no API key')) {
      return VoiceJournalUnavailability.authInvalid;
    }
    return VoiceJournalUnavailability.server;
  }
}

/// Builds the production voice-journal transport: an API key (user-provided,
/// else the bundled free-tier key) with a Flash model and JSON structured
/// output. Same seam as the Study/Delve transports, recording to
/// [VoiceJournalDiagnostics] so the layers never confuse their observability.
Future<String> Function(String prompt) buildVoiceJournalTransport({
  String? bundledKey,
  Future<String?> Function() userKeyProvider = _noUserKey,
  String modelName = aiModelName,
  Duration timeout = const Duration(seconds: 30),
}) {
  return (prompt) async {
    final key = await _effectiveKey(bundledKey, userKeyProvider);
    if (key == null) {
      VoiceJournalDiagnostics.instance.record(keySource: 'none', keyLength: null);
      throw StateError('no API key');
    }
    String? userKey;
    try {
      userKey = await userKeyProvider();
    } catch (_) {}
    final source = (userKey != null && userKey.trim().isNotEmpty)
        ? 'user'
        : 'bundled';
    VoiceJournalDiagnostics.instance.record(
      keySource: source,
      keyLength: key.length,
    );
    developer.log(
        'voice_journal: request with $source key (${key.length} chars)',
        name: 'voice_journal');
    final model = GenerativeModel(model: modelName, apiKey: key);
    final startedAt = DateTime.now();
    try {
      final response = await model.generateContent(
        [Content.text(prompt)],
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      ).timeout(timeout);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        throw StateError('empty model response');
      }
      VoiceJournalDiagnostics.instance.record(
        keySource: source,
        keyLength: key.length,
        httpStatus: '200',
      );
      developer.log(
          'voice_journal: ok in ${DateTime.now().difference(startedAt).inMilliseconds}ms '
          '(${text.length} bytes)',
          name: 'voice_journal');
      return text;
    } catch (e) {
      final status = _httpStatusFor(error: e);
      VoiceJournalDiagnostics.instance.record(
        keySource: source,
        keyLength: key.length,
        httpStatus: status,
        failureDetail: e.toString(),
      );
      developer.log('voice_journal: transport failed ($status): $e',
          name: 'voice_journal');
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