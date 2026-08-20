import 'package:beslet_app/core/speech/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class FakeSpeechGateway implements SpeechGateway {
  FakeSpeechGateway({
    this.initResult = true,
    this.locales = const ['en-US'],
    this.session,
    this.listenThrows,
  });

  bool initResult;
  List<String> locales;
  SpeechSessionResult? session;
  Object? listenThrows;

  final partials = <(String, bool)>[];
  var initCalls = 0;
  var listenCalls = 0;
  var stopCalls = 0;

  @override
  Future<bool> initialize() async {
    initCalls++;
    return initResult;
  }

  @override
  Future<List<String>> availableLocaleIds() async => locales;

  @override
  Future<SpeechSessionResult> listen({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    void Function(String partial, bool isFinal)? onPartialText,
  }) async {
    listenCalls++;
    if (listenThrows != null) throw listenThrows!;
    onPartialText?.call('hallo', false);
    final result =
        session ?? const SpeechSessionResult.available('final hallo text');
    onPartialText?.call(result.text, result.isAvailable);
    partials.add((result.text, result.isAvailable));
    return result;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }
}

/// A stand-in for the plugin's method-channel class so the production gateway's
/// own mapping code (PluginSpeechGateway) is exercised without a device.
class _ThrowingPluginSpeech extends SpeechToText {
  _ThrowingPluginSpeech() : super.withMethodChannel();

  Object? listenThrow;
  bool initResult = true;
  final localeNames = <LocaleName>[];

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async =>
      initResult;

  @override
  Future<List<LocaleName>> locales() async => localeNames;

  @override
  Future<void> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    cancelOnError = false,
    partialResults = true,
    onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    final error = listenThrow;
    if (error != null) throw error;
    onResult?.call(SpeechRecognitionResult.init(
      [SpeechRecognitionWords('final hallo text', null, 1)],
      ResultType.finalResult,
    ));
  }

  @override
  Future<void> stop() async {}
}

void main() {
  group('SpeechService.checkAvailability', () {
    test('reports ready when the engine initializes', () async {
      final gateway = FakeSpeechGateway();
      final service = SpeechService(gateway);
      final a = await service.checkAvailability(SpeechService.englishLocale);
      expect(a.isAvailable, isTrue);
      expect(a.engineAvailable, isTrue);
      expect(a.requestedLocaleSupported, isTrue);
      expect(gateway.initCalls, 1);
    });

    test('blames a missing engine, never a silent pass', () async {
      final service = SpeechService(FakeSpeechGateway(initResult: false));
      final a = await service.checkAvailability('am-ET');
      expect(a.isAvailable, isFalse);
      expect(a.failure, SpeechFailure.noRecognitionEngine);
      expect(a.requestedLocaleSupported, isFalse);
    });

    test('an amharic reader falls back to english when am-ET is absent',
        () async {
      final service = SpeechService(FakeSpeechGateway(locales: ['en-US']));
      final a = await service.checkAvailability('am-ET');
      expect(a.isAvailable, isTrue);
      expect(a.requestedLocaleSupported, isTrue);
      expect(a.localeIds, ['en-US']);
    });

    test('an amharic reader is helpfully flagged when neither locale works',
        () async {
      final service = SpeechService(FakeSpeechGateway(locales: ['fr-FR']));
      final a = await service.checkAvailability('am-ET');
      expect(a.isAvailable, isTrue);
      expect(a.requestedLocaleSupported, isFalse);
    });
  });

  group('SpeechService.dictate', () {
    test('streams partials and returns the final transcript', () async {
      final gateway = FakeSpeechGateway();
      final service = SpeechService(gateway);
      final partials = <String>[];
      final result = await service.dictate(
        localeId: 'en-US',
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 4),
        onPartialText: (text, isFinal) => partials.add(text),
      );
      expect(result.isAvailable, isTrue);
      expect(result.text, 'final hallo text');
      expect(partials.length, greaterThanOrEqualTo(2));
      expect(gateway.listenCalls, 1);
    });

    test('a session failure surfaces with its concrete reason', () async {
      final gateway = FakeSpeechGateway(
        session: const SpeechSessionResult.unavailable(
            SpeechFailure.languageNotSupported),
      );
      final service = SpeechService(gateway);
      final result = await service.dictate(
        localeId: 'am-ET',
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 4),
      );
      expect(result.isAvailable, isFalse);
      expect(result.failure, SpeechFailure.languageNotSupported);
      expect(result.text, isEmpty);
    });

    test('a permission error thrown by the plugin is mapped by the gateway',
        () async {
      final plugin = _ThrowingPluginSpeech()
        ..listenThrow = Exception('microphone permission denied');
      final service = SpeechService(PluginSpeechGateway(speech: plugin));
      final result = await service.dictate(
        localeId: 'en-US',
        listenFor: const Duration(minutes: 3),
        pauseFor: const Duration(seconds: 4),
      );
      expect(result.isAvailable, isFalse);
      expect(result.failure, SpeechFailure.permissionDenied);
    });

    test('stop forwards to the gateway', () async {
      final gateway = FakeSpeechGateway();
      await SpeechService(gateway).stop();
      expect(gateway.stopCalls, 1);
    });
  });
}