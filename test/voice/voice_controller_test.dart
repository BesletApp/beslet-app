import 'dart:typed_data';

import 'package:beslet_app/core/voice/voice_capability_probe.dart';
import 'package:beslet_app/core/voice/voice_controller.dart';
import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  VoiceController build(
    FakeRecordingAdapter adapter,
    FakeTranscriptionService t,
    FakeTranslationService tr,
  ) =>
      VoiceController(
        recorder: adapter,
        transcription: t,
        translator: tr,
        probe: VoiceCapabilityProbe(adapter: adapter),
      );

  group('VoiceController happy path', () {
    test('records, stops, and transcribes', () async {
      final adapter = FakeRecordingAdapter();
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.start();
      expect(c.isRecording, isTrue);
      expect(c.phase, VoicePhase.recording);
      expect(adapter.startCalls, 1);

      await c.stop();
      expect(c.transcript?.text, 'Hello there');
      expect(c.transcript?.detectedLanguage, 'en');
      expect(c.phase, VoicePhase.complete);
      expect(c.error, isNull);
      expect(adapter.stopCalls, 1);
      c.dispose();
    });

    test('translates a finished transcript', () async {
      final adapter = FakeRecordingAdapter();
      final tr = FakeTranslationService();
      final c = build(adapter, FakeTranscriptionService(), tr);
      await c.start();
      await c.stop();
      await c.translate();
      expect(tr.calls, 1);
      expect(tr.lastSource, 'en');
      expect(tr.lastTarget, 'am');
      expect(c.translation?.text, 'salem');
      c.dispose();
    });

    test('an edited transcript is what gets translated', () async {
      final adapter = FakeRecordingAdapter();
      final tr = FakeTranslationService();
      final c = build(adapter, FakeTranscriptionService(), tr);
      await c.start();
      await c.stop();
      await c.translate(text: 'edited words');
      expect(tr.calls, 1);
      expect(tr.lastSource, 'en');
      c.dispose();
    });
  });

  group('VoiceController errors', () {
    test('a denied permission surfaces as permissionDenied and blocks start', () async {
      final adapter = FakeRecordingAdapter()..permission = VoicePermissionState.denied;
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.start();
      expect(c.error, VoiceError.permissionDenied);
      expect(c.isRecording, isFalse);
      expect(adapter.startCalls, 0);
      c.dispose();
    });

    test('a permanently denied permission is not reported as a retryable blip', () async {
      final adapter = FakeRecordingAdapter()
        ..permission = VoicePermissionState.permanentlyDenied;
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.start();
      expect(c.error, VoiceError.permissionPermanentlyDenied);
      c.dispose();
    });

    test('empty audio is flagged without inventing an unsupported-device story', () async {
      final adapter = FakeRecordingAdapter()
        ..stopResult = VoiceRecording(
          bytes: Uint8List(0),
          mimeType: 'audio/wav',
          path: 'empty.wav',
          duration: const Duration(milliseconds: 50),
        );
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.start();
      await c.stop();
      expect(c.error, VoiceError.emptyAudio);
      expect(c.isRecording, isFalse);
      c.dispose();
    });

    test('a transcription failure keeps the recording so it can be retried', () async {
      final adapter = FakeRecordingAdapter();
      final t = FakeTranscriptionService()
        ..error = const VoicePipelineException(VoiceError.network, 'offline');
      final c = build(adapter, t, FakeTranslationService());
      await c.start();
      await c.stop();
      expect(c.error, VoiceError.network);
      expect(c.phase, VoicePhase.idle);
      expect(c.recording, isNotNull);

      t.error = null;
      await c.retryTranscription();
      expect(c.transcript?.text, 'Hello there');
      expect(t.calls, 2);
      expect(adapter.startCalls, 1, reason: 'retry must never re-record');
      c.dispose();
    });

    test('a translation failure preserves the transcript and can be retried', () async {
      final adapter = FakeRecordingAdapter();
      final tr = FakeTranslationService()
        ..error = const VoicePipelineException(VoiceError.translationFailed, 'nope');
      final c = build(adapter, FakeTranscriptionService(), tr);
      await c.start();
      await c.stop();
      await c.translate();
      expect(c.translationError, VoiceError.translationFailed);
      expect(c.transcript?.text, 'Hello there', reason: 'transcript must survive');

      tr.error = null;
      await c.retryTranslation();
      expect(c.translation?.text, 'salem');
      expect(c.translationError, isNull);
      c.dispose();
    });

    test('a recording start failure is reported', () async {
      final adapter = FakeRecordingAdapter()..startError = Exception('no input device');
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.start();
      expect(c.error, VoiceError.microphoneUnavailable);
      expect(c.isRecording, isFalse);
      c.dispose();
    });
  });

  group('VoiceController lifecycle', () {
    test('cancel discards an in-progress recording', () async {
      final adapter = FakeRecordingAdapter();
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.start();
      expect(c.isRecording, isTrue);
      await c.cancel();
      expect(c.isRecording, isFalse);
      expect(c.phase, VoicePhase.idle);
      expect(adapter.cancelCalls, 1);
      c.dispose();
    });

    test('clear resets a finished transcript for a new recording', () async {
      final adapter = FakeRecordingAdapter();
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.start();
      await c.stop();
      expect(c.transcript, isNotNull);
      c.clear();
      expect(c.transcript, isNull);
      expect(c.phase, VoicePhase.idle);
      c.dispose();
    });

    test('dispose releases the recorder', () async {
      final adapter = FakeRecordingAdapter();
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      c.dispose();
      expect(adapter.disposeCalls, 1);
    });

    test('openSettings forwards to the adapter', () async {
      final adapter = FakeRecordingAdapter();
      final c = build(adapter, FakeTranscriptionService(), FakeTranslationService());
      await c.openSettings();
      expect(adapter.openSettingsCalls, 1);
      c.dispose();
    });
  });
}