import 'dart:io';

import 'package:beslet_app/core/ai/study/study_backend.dart';
import 'package:beslet_app/core/ai/study/study_local_bank.dart';
import 'package:beslet_app/core/ai/study/study_provider.dart';
import 'package:beslet_app/core/ai/study/study_service.dart';
import 'package:beslet_app/core/ai/study/study_sources.dart';
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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAudioPlayer extends AudioPlayerNotifier {
  @override
  AudioPlayerState build() => const AudioPlayerState();
}

class _FakeReadingNotifier extends ReadingNotifier {
  @override
  Future<void> build() async {}
  @override
  Future<void> logReading({int minutes = 1, String? bookId, int? chapter}) async {}
  @override
  Future<void> markCompleted({String? bookId, int? chapter}) async {}
}

class _FakeJournalNotifier extends JournalNotifier {
  @override
  Future<void> build() async {}
  @override
  Future<void> saveEntry(String content) async {}
}

ScriptureChapter _chapter({
  required String bookId,
  required int chapter,
  required int verses,
  bool amharic = false,
}) {
  return ScriptureChapter(
    bookId: bookId,
    chapter: chapter,
    isAmharic: amharic,
    verses: [
      for (var i = 1; i <= verses; i++)
        ScriptureVerse(number: i, text: 'Verse $i'),
    ],
  );
}

Future<void> pumpBible(
  WidgetTester tester, {
  String bookId = 'genesis',
  int chapter = 1,
  int verses = 60,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityProvider.overrideWith((ref) => Stream.value(true)),
        audioPlayerProvider.overrideWith(() => _FakeAudioPlayer()),
        scriptureProvider.overrideWith((ref, params) async {
          if (params.bookId == 'revelation') return null;
          return _chapter(bookId: params.bookId, chapter: params.chapter, verses: 20);
        }),
        todayBiblePlanProvider.overrideWithValue(const TodayReadingPlan(
          bookId: 'genesis', chapter: 1, labelEn: 'Genesis 1', labelAm: 'ዘፍጥረት 1',
        )),
        todayReadingProvider.overrideWith((ref) async => null),
        todaySoulLogProvider.overrideWith((ref) async => null),
        journalEntryProvider.overrideWith((ref) async => null),
        journalNotifierProvider.overrideWith(() => _FakeJournalNotifier()),
        readingNotifierProvider.overrideWith(() => _FakeReadingNotifier()),
        vineLifeProvider.overrideWith((ref) async => const VineLifeState(
          water: 0.5,
          light: 0.5,
          warmth: 0.5,
          diligence: 0.5,
          daysMissed: 0,
          hoursAway: 0,
        )),
        studyLocalBankProvider.overrideWith((ref) async =>
            StudyLocalBank.fromJsonString(
                File('assets/data/study.json').readAsStringSync())),
        studySourcesProvider.overrideWith((ref) async =>
            StudySourceRegistry.fromJsonString(
                File('assets/data/study_sources.json').readAsStringSync())),
        // Local-only service: no Gemini, no network, deterministic in tests.
        studyServiceProvider.overrideWith((ref) async {
          final bank = await ref.watch(studyLocalBankProvider.future);
          return StudyService(
            backend: LocalStudyBackend(bank),
            readCache: (key) async =>
                (await SharedPreferences.getInstance()).getString(key),
            writeCache: (key, value) async =>
                (await SharedPreferences.getInstance()).setString(key, value),
          );
        }),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BibleScreen(initialBookId: bookId, initialChapter: chapter),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

/// Flushes the StudyPanel's async load (bank future + SharedPreferences).
Future<void> pumpPanel(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('long-press enters passage selection; tapping extends the range',
      (tester) async {
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 6);

    await tester.longPress(find.text('1'));
    await tester.pump();
    expect(find.text('Study · 1 verse'), findsOneWidget);

    await tester.tap(find.text('3'));
    await tester.pump();
    expect(find.text('Study · 3 verses'), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.text('Study · 5 verses'), findsOneWidget);
  });

  testWidgets('cancel exits passage selection', (tester) async {
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 6);

    await tester.longPress(find.text('1'));
    await tester.pump();
    expect(find.text('Study · 1 verse'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('Study · 1 verse'), findsNothing);
  });

  testWidgets('selection is clamped to ten verses', (tester) async {
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 12);

    await tester.longPress(find.text('1'));
    await tester.pump();

    await tester.scrollUntilVisible(find.text('11'), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('11'));
    await tester.pump();
    expect(find.text('Study · 10 verses'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('12'), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('12'));
    await tester.pump();
    expect(find.text('Study · 10 verses'), findsOneWidget);
  });

  testWidgets('Study opens the panel with the banked note for the passage',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 6);

    await tester.longPress(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();

    await tester.tap(find.text('Study · 3 verses'));
    await pumpPanel(tester);

    expect(find.text('Psalms 23:1–3'), findsOneWidget);
    expect(find.text('What the Text Communicates'), findsOneWidget);
    expect(find.textContaining('shepherd'), findsWidgets);
  });

  testWidgets('the panel names the curated sources each section draws on',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 6);

    await tester.longPress(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();

    await tester.tap(find.text('Study · 3 verses'));
    await pumpPanel(tester);

    await tester.scrollUntilVisible(
        find.textContaining('Scripture and your church remain the authority'),
        200,
        scrollable: find.byType(Scrollable).last);

    // The "what the text says" section draws on Holy Scripture only.
    expect(find.textContaining('Sources: Holy Scripture'), findsWidgets);
    // A background section draws on Scripture and the received teaching.
    expect(
      find.textContaining('Sources: Holy Scripture · '
          'The received teaching of the Church'),
      findsWidgets,
    );
  });

  testWidgets('unbanked passage shows the quiet needs-connection note',
      (tester) async {
    await pumpBible(tester, bookId: 'genesis', chapter: 1, verses: 6);

    await tester.longPress(find.text('1'));
    await tester.pump();

    await tester.tap(find.text('Study · 1 verse'));
    await pumpPanel(tester);

    expect(
      find.text('A full study note for this passage needs a connection right '
          'now. The passage stands on its own — read it, sit with it, and let '
          'it do its work.'),
      findsOneWidget,
    );
  });

  testWidgets('action-sheet Study tile opens the panel for a single verse',
      (tester) async {
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 6);

    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Study'), findsOneWidget);

    await tester.tap(find.text('Study'));
    await pumpPanel(tester);

    expect(find.text('Psalms 23:1'), findsOneWidget);
  });

  testWidgets('tapping a cross-reference opens the in-sheet viewer with the '
      'app-owned passage text', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 6);

    await tester.longPress(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();

    await tester.tap(find.text('Study · 3 verses'));
    await pumpPanel(tester);

    await tester.scrollUntilVisible(find.text('John 10:11'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('John 10:11'));
    await tester.pump();
    await tester.tap(find.text('John 10:11'));
    await pumpPanel(tester);

    // The viewer reuses the app's own Bible text for the reference (never AI).
    expect(
      find.descendant(
        of: find.byType(ListView).last,
        matching: find.text('Verse 11'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a cross-reference with no local passage text stays quiet',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await pumpBible(tester, bookId: 'psalms', chapter: 23, verses: 6);

    await tester.longPress(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('3'));
    await tester.pump();

    await tester.tap(find.text('Study · 3 verses'));
    await pumpPanel(tester);

    await tester.scrollUntilVisible(find.text('Revelation 7:17'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(find.text('Revelation 7:17'));
    await tester.tap(find.text('Revelation 7:17'));
    await pumpPanel(tester);

    expect(
      find.text("This passage isn't available right now."),
      findsOneWidget,
    );
  });
}
