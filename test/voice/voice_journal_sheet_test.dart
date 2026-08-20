import 'package:beslet_app/core/voice/voice_models.dart';
import 'package:beslet_app/features/reflection/widgets/voice_journal_sheet.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

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