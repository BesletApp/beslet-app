import 'package:beslet_app/core/providers/audio_player_provider.dart';
import 'package:beslet_app/core/providers/connectivity_provider.dart';
import 'package:beslet_app/core/providers/growth_streams_provider.dart';
import 'package:beslet_app/core/providers/journal_provider.dart';
import 'package:beslet_app/core/providers/scripture_provider.dart';
import 'package:beslet_app/core/providers/soul_log_provider.dart';
import 'package:beslet_app/core/providers/vine_life_provider.dart';
import 'package:beslet_app/features/spiritual/bible_screen.dart';
import 'package:beslet_app/features/spiritual/widgets/chapter_picker.dart';
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
    String? initialBookId = 'genesis',
    int? initialChapter = 1,
    void Function(String bookId, int chapter, bool isAmharic)? onScriptureRequested,
    TodayReadingPlan? planOverride,
    Map<String, Object>? prefs,
  }) async {
    SharedPreferences.setMockInitialValues(prefs ?? {});
    reading = _FakeReadingNotifier();
    journal = _FakeJournalNotifier();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityProvider.overrideWith((ref) => Stream.value(true)),
          audioPlayerProvider.overrideWith(() => _FakeAudioPlayer()),
          scriptureProvider.overrideWith((ref, params) async {
            onScriptureRequested?.call(params.bookId, params.chapter, params.isAmharic);
            return _chapter(verses: verses);
          }),
          if (planOverride != null)
            todayBiblePlanProvider.overrideWithValue(planOverride),
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
          home: BibleScreen(
            initialBookId: initialBookId,
            initialChapter: initialChapter,
          ),
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

  group('Chapter navigation', () {
    testWidgets('next moves to the following chapter in the same book',
        (tester) async {
      final requested = <({String bookId, int chapter})>[];
      await pumpBible(
        tester,
        initialBookId: 'genesis',
        initialChapter: 1,
        onScriptureRequested: (bookId, chapter, _) =>
            requested.add((bookId: bookId, chapter: chapter)),
      );

      await tester.tap(find.byTooltip('Next chapter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(requested.any((r) => r.bookId == 'genesis' && r.chapter == 2),
          isTrue,
          reason: 'next must open chapter 2 of the same book');
    });

    testWidgets('previous moves to the prior chapter in the same book',
        (tester) async {
      final requested = <({String bookId, int chapter})>[];
      await pumpBible(
        tester,
        initialBookId: 'genesis',
        initialChapter: 3,
        onScriptureRequested: (bookId, chapter, _) =>
            requested.add((bookId: bookId, chapter: chapter)),
      );

      await tester.tap(find.byTooltip('Previous chapter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(requested.any((r) => r.bookId == 'genesis' && r.chapter == 2),
          isTrue,
          reason: 'previous must open chapter 2 of the same book');
    });

    testWidgets('next flows into the next book at a book boundary',
        (tester) async {
      final requested = <({String bookId, int chapter})>[];
      await pumpBible(
        tester,
        initialBookId: 'obadiah', // 1 chapter — next must leave the book
        initialChapter: 1,
        onScriptureRequested: (bookId, chapter, _) =>
            requested.add((bookId: bookId, chapter: chapter)),
      );

      await tester.tap(find.byTooltip('Next chapter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(requested.any((r) => r.bookId == 'jonah' && r.chapter == 1),
          isTrue,
          reason: 'next at Obadiah 1 must land on Jonah 1');
    });

    testWidgets('previous flows into the prior book at a book boundary',
        (tester) async {
      final requested = <({String bookId, int chapter})>[];
      await pumpBible(
        tester,
        initialBookId: 'jonah',
        initialChapter: 1,
        onScriptureRequested: (bookId, chapter, _) =>
            requested.add((bookId: bookId, chapter: chapter)),
      );

      await tester.tap(find.byTooltip('Previous chapter'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(requested.any((r) => r.bookId == 'obadiah' && r.chapter == 1),
          isTrue,
          reason: 'previous at Jonah 1 must land on Obadiah 1');
    });

    testWidgets('previous is disabled at the very start of the canon',
        (tester) async {
      await pumpBible(tester, initialBookId: 'genesis', initialChapter: 1);
      final prev = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Previous chapter'),
          matching: find.byType(IconButton),
        ),
      );
      expect(prev.onPressed, isNull,
          reason: 'nothing comes before Genesis 1');
    });

    testWidgets('next is disabled at the very end of the canon',
        (tester) async {
      await pumpBible(tester, initialBookId: 'revelation', initialChapter: 22);
      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('Next chapter'),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNull,
          reason: 'nothing comes after Revelation 22');
    });

    testWidgets('tapping the chapter label opens the quick chapter grid',
        (tester) async {
      final requested = <({String bookId, int chapter})>[];
      await pumpBible(
        tester,
        initialBookId: 'genesis',
        initialChapter: 1,
        onScriptureRequested: (bookId, chapter, _) =>
            requested.add((bookId: bookId, chapter: chapter)),
      );

      await tester.tap(find.text('Genesis 1'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ChapterPicker), findsOneWidget,
          reason: 'tapping the label must open the chapter grid');

      await tester.tap(find.descendant(
        of: find.byType(ChapterPicker),
        matching: find.text('5'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(requested.any((r) => r.bookId == 'genesis' && r.chapter == 5),
          isTrue,
          reason: 'selecting a chapter in the grid must update the reader');
    });
  });

  group('Bible zone is never empty', () {
    testWidgets('opens on the saved last-read chapter when present',
        (tester) async {
      final requested = <({String bookId, int chapter})>[];
      await pumpBible(
        tester,
        initialBookId: null,
        initialChapter: null,
        prefs: {
          'last_open_page':
              '{"bookId":"psalms","chapter":23,"language":"en"}',
        },
        onScriptureRequested: (bookId, chapter, _) =>
            requested.add((bookId: bookId, chapter: chapter)),
      );

      debugPrint('DBG requested=$requested');
      expect(requested.any((r) => r.bookId == 'psalms' && r.chapter == 23),
          isTrue,
          reason: 'the Bible zone must restore the last-read chapter');
    });

    testWidgets('opens on today\'s plan when nothing was read yet',
        (tester) async {
      final requested = <({String bookId, int chapter})>[];
      await pumpBible(
        tester,
        initialBookId: null,
        initialChapter: null,
        planOverride: const TodayReadingPlan(
          bookId: 'matthew',
          chapter: 5,
          labelEn: 'Matthew 5',
          labelAm: 'ማቴዎስ 5',
        ),
        onScriptureRequested: (bookId, chapter, _) =>
            requested.add((bookId: bookId, chapter: chapter)),
      );

      expect(requested.any((r) => r.bookId == 'matthew' && r.chapter == 5),
          isTrue,
          reason: 'a fresh Bible zone must default to today\'s reading plan');
      expect(find.text('Loading chapter...'), findsNothing,
          reason: 'the Bible zone must never sit in an empty loading state');
    });
  });
}
