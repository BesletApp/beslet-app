import 'package:beslet_app/core/providers/audio_player_provider.dart';
import 'package:beslet_app/core/providers/connectivity_provider.dart';
import 'package:beslet_app/core/providers/growth_streams_provider.dart';
import 'package:beslet_app/core/providers/journal_provider.dart';
import 'package:beslet_app/core/providers/scripture_provider.dart';
import 'package:beslet_app/core/providers/soul_log_provider.dart';
import 'package:beslet_app/core/providers/vine_life_provider.dart';
import 'package:beslet_app/features/spiritual/bible_screen.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake audio notifier that never touches the native TTS/player, so the
/// widget test is fully offline.
class _FakeAudioPlayer extends AudioPlayerNotifier {
  @override
  AudioPlayerState build() => const AudioPlayerState();
}

/// Records every completion attempt — proving the "I have read" tap is the
/// only way to finish a reading, and that it lands exactly once.
class _FakeReadingNotifier extends ReadingNotifier {
  final marks = <({String? bookId, int? chapter})>[];
  @override
  Future<void> build() async {}
  @override
  Future<void> logReading({int minutes = 1, String? bookId, int? chapter}) async {}
  @override
  Future<void> markCompleted({String? bookId, int? chapter}) async {
    marks.add((bookId: bookId, chapter: chapter));
  }
}

class _FakeJournalNotifier extends JournalNotifier {
  final saved = <String>[];
  @override
  Future<void> build() async {}
  @override
  Future<void> saveEntry(String content) async {
    saved.add(content);
  }
}

ScriptureChapter _chapter({required int verses, bool amharic = false}) {
  return ScriptureChapter(
    bookId: 'genesis',
    chapter: 1,
    isAmharic: amharic,
    verses: [
      for (var i = 1; i <= verses; i++)
        ScriptureVerse(number: i, text: 'Verse $i — the Lord is my shepherd, I shall not want.'),
    ],
  );
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late _FakeReadingNotifier reading;
  late _FakeJournalNotifier journal;

  Future<void> pumpBible(
    WidgetTester tester, {
    int verses = 60,
    Locale? locale,
  }) async {
    SharedPreferences.setMockInitialValues({});
    reading = _FakeReadingNotifier();
    journal = _FakeJournalNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          audioPlayerProvider.overrideWith(() => _FakeAudioPlayer()),
          scriptureProvider.overrideWith((ref, params) async => _chapter(verses: verses)),
          todayReadingProvider.overrideWith((ref) async => null),
          todaySoulLogProvider.overrideWith((ref) async => null),
          journalEntryProvider.overrideWith((ref) async => null),
          journalNotifierProvider.overrideWith(() => journal),
          readingNotifierProvider.overrideWith(() => reading),
          vineLifeProvider.overrideWith((ref) async => const VineLifeState(
            water: 0.5,
            light: 0.5,
            warmth: 0.5,
            diligence: 0.5,
            daysMissed: 0,
            hoursAway: 0,
          )),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: const BibleScreen(initialBookId: 'genesis', initialChapter: 1),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  AppLocalizations l10n(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(BibleScreen)))!;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'), (_) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('xyz.luan/audioplayers.global'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  group('BibleZone footer', () {
    testWidgets('the confirmation is never visible when a chapter opens', (tester) async {
      await pumpBible(tester, verses: 4);
      final l = l10n(tester);
      expect(find.text(l.iHaveRead), findsNothing,
          reason: 'the "I have read" button must not be on screen at open');
      expect(find.text(l.whatDidYouUnderstand), findsNothing,
          reason: 'the reflection prompt must not be on screen at open');
      expect(reading.marks, isEmpty,
          reason: 'opening a chapter must never count as a completed reading');
    });

    testWidgets('a long chapter reveals the footer only when scrolled to the end', (tester) async {
      await pumpBible(tester, verses: 60);
      final l = l10n(tester);

      expect(find.text(l.iHaveRead), findsNothing);
      expect(find.text(l.whatDidYouUnderstand), findsNothing);

      // Scroll a short way — the footer must stay hidden until the very end.
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text(l.iHaveRead), findsNothing,
          reason: 'a partial scroll is not the end of the chapter');

      // Reach the bottom of the chapter.
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(l.whatDidYouUnderstand), findsOneWidget,
          reason: 'the reflection prompt appears at the bottom of the chapter');
      expect(find.text(l.iHaveRead), findsOneWidget,
          reason: 'the "I have read" button appears only after reaching the end');
    });

    testWidgets('a short chapter reveals the footer after a quiet dwell', (tester) async {
      await pumpBible(tester, verses: 2);
      final l = l10n(tester);

      expect(find.text(l.iHaveRead), findsNothing,
          reason: 'the button is never there at open, even on a short chapter');

      // A single-screen chapter has no scroll extent; the 10s dwell brings the
      // confirmation into view instead.
      await tester.pump(const Duration(seconds: 10));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(l.iHaveRead), findsOneWidget);
      expect(find.text(l.whatDidYouUnderstand), findsOneWidget);
    });

    testWidgets('tapping "I have read" saves the reflection and completes the reading once', (tester) async {
      await pumpBible(tester, verses: 60);
      final l = l10n(tester);

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(l.iHaveRead), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'The Word showed me rest.');
      // Let the 1s debounce save the reflection to the journal.
      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.text(l.iHaveRead));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));

      expect(reading.marks, hasLength(1),
          reason: 'finishing must record exactly one completed reading');
      expect(reading.marks.single.bookId, 'genesis');
      expect(reading.marks.single.chapter, 1);
      expect(journal.saved, contains('The Word showed me rest.'),
          reason: 'the reflection must be written to today\'s journal');
    });
  });
}
