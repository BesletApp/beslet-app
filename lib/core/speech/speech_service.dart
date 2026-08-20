import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Why a dictation session could not run, always surfaced to the reader.
enum SpeechFailure {
  permissionDenied,
  noRecognitionEngine,
  languageNotSupported,
  audioUnavailable,
  timedOut,
  other,
}

/// The outcome of a dictation session: a transcript, or a concrete failure.
/// A silent null transcript is never produced — every failure carries a reason
/// the sheet must explain.
class SpeechSessionResult {
  final String? transcript;
  final SpeechFailure? failure;

  const SpeechSessionResult.available(String this.transcript) : failure = null;

  const SpeechSessionResult.unavailable(this.failure) : transcript = null;

  bool get isAvailable => transcript != null && transcript!.trim().isNotEmpty;

  String get text => transcript ?? '';
}

/// What a speech check found about the device, before any session starts.
class SpeechAvailability {
  final bool engineAvailable;

  /// Locale ids the recognizer reports it can handle (may be empty).
  final List<String> localeIds;

  /// Whether [localeIds] contained the requested locale (when engine exists).
  final bool requestedLocaleSupported;

  /// Concrete reason when the engine is unavailable.
  final SpeechFailure? failure;

  const SpeechAvailability.available({
    required this.localeIds,
    required this.requestedLocaleSupported,
  })  : engineAvailable = true,
        failure = null;

  const SpeechAvailability.denied(this.failure)
      : engineAvailable = false,
        localeIds = const [],
        requestedLocaleSupported = false;

  bool get isAvailable => engineAvailable;
}

/// The injectable seam around the platform speech recognizer, so the sheet and
/// the tests never depend on the plugin's method channel directly.
abstract class SpeechGateway {
  /// Initializes the recognizer and requests the microphone/speech permission
  /// when the platform requires it. Returns true when a recognizer is ready.
  Future<bool> initialize();

  /// The locale ids the recognizer reports it supports (e.g. "en-US",
  /// "am-ET"). May be empty on devices that do not report a list.
  Future<List<String>> availableLocaleIds();

  /// Runs one dictation session in [localeId]. [listenFor] caps the session;
  /// [pauseFor] stops on silence. Partial results are streamed through
  /// [onPartialText] (text so far, whether final).
  Future<SpeechSessionResult> listen({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    void Function(String partial, bool isFinal)? onPartialText,
  });

  /// Stops an active session early.
  Future<void> stop();
}

/// The production gateway backed by the speech_to_text plugin.
class PluginSpeechGateway implements SpeechGateway {
  final SpeechToText speech;

  PluginSpeechGateway({SpeechToText? speech}) : speech = speech ?? SpeechToText();

  SpeechFailure? _sessionError;

  @override
  Future<bool> initialize() async {
    try {
      _sessionError = null;
      return await speech.initialize(
        onError: (e) => _sessionError = _mapError(e.errorMsg),
        options: [SpeechToText.androidNoBluetooth],
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<String>> availableLocaleIds() async {
    try {
      final locales = await speech.locales();
      return locales.map((l) => l.localeId).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<SpeechSessionResult> listen({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    void Function(String partial, bool isFinal)? onPartialText,
  }) async {
    _sessionError = null;
    var lastText = '';
    try {
      await speech.listen(
        onResult: (SpeechRecognitionResult result) {
          lastText = result.recognizedWords;
          onPartialText?.call(lastText, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          listenFor: listenFor,
          pauseFor: pauseFor,
          partialResults: true,
          cancelOnError: false,
          onDevice: false,
          listenMode: ListenMode.dictation,
        ),
      );
      final error = _sessionError;
      if (error != null) return SpeechSessionResult.unavailable(error);
      final text = lastText.trim();
      if (text.isNotEmpty) {
        return SpeechSessionResult.available(text);
      }
      return const SpeechSessionResult.unavailable(SpeechFailure.timedOut);
    } catch (e) {
      final m = e.toString().toLowerCase();
      if (m.contains('permission')) {
        return const SpeechSessionResult.unavailable(SpeechFailure.permissionDenied);
      }
      if (m.contains('not_found') || m.contains('not available')) {
        return const SpeechSessionResult.unavailable(SpeechFailure.noRecognitionEngine);
      }
      return const SpeechSessionResult.unavailable(SpeechFailure.other);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await speech.stop();
    } catch (_) {
      // Stopping is best-effort.
    }
  }

  SpeechFailure _mapError(String errorMsg) {
    final m = errorMsg.toLowerCase();
    if (m.contains('permission')) return SpeechFailure.permissionDenied;
    if (m.contains('not_found')) return SpeechFailure.noRecognitionEngine;
    if (m.contains('language_not_supported') || m.contains('language not')) {
      return SpeechFailure.languageNotSupported;
    }
    if (m.contains('audio')) return SpeechFailure.audioUnavailable;
    if (m.contains('timeout')) return SpeechFailure.timedOut;
    if (m.contains('network')) return SpeechFailure.other;
    return SpeechFailure.other;
  }
}

/// Thin orchestrator over a [SpeechGateway] used by the voice-journal sheet.
/// Everything is injectable so widget and unit tests never touch the plugin.
class SpeechService {
  final SpeechGateway gateway;

  const SpeechService(this.gateway);

  /// Locale id constants shared by the service and its callers.
  static const String amharicLocale = 'am-ET';
  static const String englishLocale = 'en-US';

  /// Checks the recognizer and whether the requested locale is supported, so
  /// the sheet can show the right message before a session starts.
  Future<SpeechAvailability> checkAvailability(String localeId) async {
    var ready = false;
    try {
      ready = await gateway.initialize();
    } catch (_) {
      ready = false;
    }
    if (!ready) {
      return const SpeechAvailability.denied(SpeechFailure.noRecognitionEngine);
    }
    final locales = await gateway.availableLocaleIds();
    final supported = locales.isEmpty ||
        locales.contains(localeId) ||
        localeId == amharicLocale && locales.contains(englishLocale);
    return SpeechAvailability.available(
      localeIds: locales,
      requestedLocaleSupported: supported,
    );
  }

  Future<SpeechSessionResult> dictate({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    void Function(String partial, bool isFinal)? onPartialText,
  }) =>
      gateway.listen(
        localeId: localeId,
        listenFor: listenFor,
        pauseFor: pauseFor,
        onPartialText: onPartialText,
      );

  Future<void> stop() => gateway.stop();
}