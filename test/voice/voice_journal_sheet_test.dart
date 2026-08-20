import 'package:beslet_app/core/secrets.dart';
import 'package:beslet_app/core/voice/voice_ai_transports.dart';
import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:beslet_app/features/reflection/widgets/voice_journal_sheet.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'fakes.dart';

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

/// Returns a canned transcript for audio calls and a canned translation for
/// text calls, recording which api key each used. Guards the production
/// wiring: the sheet must pass the bundled key to both transports.
class _SheetModelFactory {
  var audioCalls = 0;
  var textCalls = 0;
  final audioApiKeys = <String>[];
  final textApiKeys = <String>[];

  GeminiModelRequest call(String modelName, String apiKey) {
    return (contents, {generationConfig}) {
      final hasData =
          contents.any((c) => c.parts.any((p) => p is DataPart));
      if (hasData) {
        audioCalls++;
        audioApiKeys.add(apiKey);
        return Future.value(_jsonResponse('{"transcript":"Hello there","language":"en"}'));
      }
      textCalls++;
      textApiKeys.add(apiKey);
      return Future.value(_jsonResponse('{"translated":"salem"}'));
    };
  }
}

void main() {
  Widget wrap({
    FakeRecordingAdapter? adapter,
    FakeTranscriptionService? transcription,
    FakeTranslationService? translation,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VoiceJournalSheet(
            recordingAdapter: adapter ?? FakeRecordingAdapter(),
            transcriptionService: transcription ?? FakeTranscriptionService(),
            translationService: translation ?? FakeTranslationService(),
          ),
        ),
      ),
    );
  }

  /// Production wiring: no transcription/translation injection, only the
  /// recording seam and a stubbed model factory for the real Gemini transports.
  Widget wrapProduction({
    required _SheetModelFactory modelFactory,
    FakeRecordingAdapter? adapter,
  }) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VoiceJournalSheet(
            recordingAdapter: adapter ?? FakeRecordingAdapter(),
            modelFactory: modelFactory.call,
          ),
        ),
      ),
    );
  }

  group('VoiceJournalSheet record flow', () {
    testWidgets('record → stop → transcript → translate', (tester) async {
      final adapter = FakeRecordingAdapter();
      final tr = FakeTranslationService();
      await tester.pumpWidget(wrap(adapter: adapter, translation: tr));
      await tester.pump();
      expect(find.text('Start recording'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(adapter.startCalls, 1);

      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Hello there'), findsOneWidget);
      expect(adapter.stopCalls, 1);

      await tester.tap(find.text('Translate'));
      await tester.pump();
      await tester.pump();
      expect(find.text('salem'), findsOneWidget);
      expect(tr.calls, 1);
    });

    testWidgets('production wiring passes the bundled key to both transports',
        (tester) async {
      final adapter = FakeRecordingAdapter();
      final factory = _SheetModelFactory();
      await tester.pumpWidget(wrapProduction(modelFactory: factory, adapter: adapter));
      await tester.pump();
      expect(find.text('Start recording'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Hello there'), findsOneWidget);
      expect(factory.audioCalls, 1);
      expect(factory.audioApiKeys.single, defaultGeminiKey);

      await tester.tap(find.text('Translate'));
      await tester.pump();
      await tester.pump();
      expect(find.text('salem'), findsOneWidget);
      expect(factory.textCalls, 1);
      expect(factory.textApiKeys.single, defaultGeminiKey);
    });

    testWidgets('a denied permission shows the reader-safe error step', (tester) async {
      final adapter = FakeRecordingAdapter()
        ..permission = VoicePermissionState.denied;
      await tester.pumpWidget(wrap(adapter: adapter));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('Microphone permission is needed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(adapter.startCalls, 0);
    });

    testWidgets('a transcription failure retries without re-recording', (tester) async {
      final adapter = FakeRecordingAdapter();
      final t = FakeTranscriptionService()
        ..error = const VoicePipelineException(VoiceError.network, 'offline');
      await tester.pumpWidget(wrap(adapter: adapter, transcription: t));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Retry transcription'), findsOneWidget);
      expect(adapter.startCalls, 1);

      t.error = null;
      await tester.tap(find.text('Retry transcription'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Hello there'), findsOneWidget);
      expect(adapter.startCalls, 1, reason: 'retry must not re-record');
    });

    testWidgets('a translation failure retries against the held transcript', (tester) async {
      final adapter = FakeRecordingAdapter();
      final tr = FakeTranslationService()
        ..error = const VoicePipelineException(VoiceError.translationFailed, 'nope');
      await tester.pumpWidget(wrap(adapter: adapter, translation: tr));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.mic));
      await tester.pump();
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('Translate'));
      await tester.pump();
      await tester.pump();
      expect(find.text('salem'), findsNothing);
      expect(find.text('Retry translation'), findsOneWidget);

      tr.error = null;
      await tester.tap(find.text('Retry translation'));
      await tester.pump();
      await tester.pump();
      expect(find.text('salem'), findsOneWidget);
    });
  });
}