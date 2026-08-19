import 'dart:io';

import 'package:beslet_app/core/ai/study/study_backend.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_provider.dart';
import 'package:beslet_app/core/ai/study/study_service.dart';
import 'package:beslet_app/core/ai/study/study_sources.dart';
import 'package:beslet_app/features/spiritual/widgets/study_panel.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'study_test_utils.dart';

StudyRequest _request() => StudyRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 23, startVerse: 1, endVerse: 3),
      isAmharic: false,
      verseTexts: const ['a', 'b', 'c'],
    );

StudyResult _result() => StudyResult(
      reference: _request().reference,
      source: StudySource.gemini,
      cachedAt: DateTime.now(),
      isAvailable: true,
      sections: [
        const StudySection(
          kind: StudySectionKind.originalLanguage,
          en: 'A shepherd leads, feeds, and protects the flock.',
          terms: [
            StudyTerm(
              term: 'רֹעִי',
              language: 'hebrew',
              transliteration: 'ro’i',
              en: 'shepherd',
            ),
          ],
        ),
      ],
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required StudyBackend backend,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studySourcesProvider.overrideWith((ref) async =>
              StudySourceRegistry.fromJsonString(
                  File('assets/data/study_sources.json').readAsStringSync())),
          studyCrossRefProvider.overrideWith((ref) async =>
              loadTestCrossRefs()),
          studyServiceProvider.overrideWith((ref) async => StudyService(
                backend: backend,
                readCache: (_) async => null,
                writeCache: (_, _) async {},
              )),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StudyPanel(request: _request(), isAm: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the terms block renders term, transliteration, and meaning',
      (tester) async {
    await pump(tester, backend: _FakeBackend(_result()));

    expect(find.text('Looking Closely at the Words'), findsOneWidget);
    expect(find.textContaining('רֹעִי'), findsOneWidget);
    expect(find.textContaining('ro’i'), findsOneWidget);
    expect(find.text('shepherd'), findsOneWidget);
  });

  testWidgets('the panel renders when terms are absent', (tester) async {
    await pump(tester, backend: _FakeBackend(_noTermsResult()));

    expect(find.text('Looking Closely at the Words'), findsOneWidget);
    expect(find.text('Key terms & original language'), findsNothing);
  });

  testWidgets('sections render in the canonical scaffold order', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final outOfOrder = StudyResult(
      reference: _request().reference,
      source: StudySource.gemini,
      cachedAt: DateTime.now(),
      isAvailable: true,
      sections: const [
        StudySection(
          kind: StudySectionKind.questionsToCarry,
          en: 'Where does the shepherd lead?',
        ),
        StudySection(
          kind: StudySectionKind.passageOverview,
          en: 'A psalm of David.',
        ),
        StudySection(
          kind: StudySectionKind.literaryContext,
          en: 'The LORD is my shepherd.',
        ),
      ],
    );
    await pump(tester, backend: _FakeBackend(outOfOrder));

    final titles =
        tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    final overviewIndex = titles.indexOf('At a Glance');
    final literaryIndex = titles.indexOf('What the Text Communicates');
    final questionsIndex = titles.indexOf('Consider');
    expect(overviewIndex, lessThan(literaryIndex),
        reason: 'At a Glance must render before What the Text Communicates');
    expect(literaryIndex, lessThan(questionsIndex),
        reason: 'What the Text Communicates must render before Consider');
  });

  testWidgets('the offline index fills the connections step when the backend '
      'returns none', (tester) async {
    final noConnections = StudyResult(
      reference: _request().reference,
      source: StudySource.gemini,
      cachedAt: DateTime.now(),
      isAvailable: true,
      sections: const [
        StudySection(
          kind: StudySectionKind.passageOverview,
          en: 'A psalm of David.',
        ),
      ],
    );
    await pump(tester, backend: _FakeBackend(noConnections));

    expect(find.text('Scripture Alongside Scripture'), findsOneWidget,
        reason: 'the connections step must be filled from the offline index');
    expect(find.text('John 10:11'), findsOneWidget,
        reason: 'the offline index links psalm 23 to John 10:11');
  });

  testWidgets('a slow backend does not hang the panel; it renders once the '
      'note resolves', (tester) async {
    var calls = 0;
    final backend = _DelayedBackend(() => _result(), calls: () => calls++);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studySourcesProvider.overrideWith((ref) async =>
              StudySourceRegistry.fromJsonString(
                  File('assets/data/study_sources.json').readAsStringSync())),
          studyCrossRefProvider.overrideWith((ref) async =>
              loadTestCrossRefs()),
          studyServiceProvider.overrideWith((ref) async => StudyService(
                backend: backend,
                readCache: (_) async => null,
                writeCache: (_, _) async {},
              )),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StudyPanel(request: _request(), isAm: false),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget,
        reason: 'before the 300ms elapses the panel must show the loading '
            'state, never a hung or empty frame');

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Looking Closely at the Words'), findsOneWidget,
        reason: 'after the note resolves the panel renders content');
    expect(calls, 1, reason: 'a single open must trigger one backend call');
  });

  testWidgets('offline connections are merged into the backend connections '
      'without duplication', (tester) async {
    final backendConnections = StudyResult(
      reference: _request().reference,
      source: StudySource.gemini,
      cachedAt: DateTime.now(),
      isAvailable: true,
      sections: const [
        StudySection(
          kind: StudySectionKind.scriptureInterconnections,
          references: [
            StudyCrossReference(
              bookId: 'john',
              chapter: 10,
              startVerse: 11,
              endVerse: 11,
              en: 'The good Shepherd.',
            ),
          ],
        ),
      ],
    );
    await pump(tester, backend: _FakeBackend(backendConnections));

    expect(find.text('John 10:11'), findsOneWidget,
        reason: 'the shared reference must render exactly once');
    expect(find.text('1 Peter 5:7'), findsOneWidget,
        reason: 'the offline-only reference must also appear');
  });

  group('hierarchy rendering', () {
    testWidgets('labeled movement steps render as numbered step rows',
        (tester) async {
      final result = StudyResult(
        reference: _request().reference,
        source: StudySource.gemini,
        cachedAt: DateTime.now(),
        isAvailable: true,
        sections: const [
          StudySection(
            kind: StudySectionKind.literaryContext,
            en: 'Step 1 — The LORD opens the psalm as the shepherd.\n'
                'Step 2 — He leads through the darkest valley.',
          ),
        ],
      );
      await _pumpResult(tester, result);

      expect(find.textContaining('opens the psalm as the shepherd'),
          findsOneWidget);
      expect(
          find.textContaining('leads through the darkest valley'), findsOneWidget);
    });

    testWidgets('bullet rows render as separate lines', (tester) async {
      final result = StudyResult(
        reference: _request().reference,
        source: StudySource.gemini,
        cachedAt: DateTime.now(),
        isAvailable: true,
        sections: const [
          StudySection(
            kind: StudySectionKind.originalLanguage,
            en: '• The shepherd provides and restores.\n• He stays present.',
          ),
        ],
      );
      await _pumpResult(tester, result);

      expect(find.textContaining('provides and restores'), findsOneWidget);
      expect(find.textContaining('He stays present'), findsOneWidget);
    });
  });

  group('threads rendering', () {
    testWidgets('renders the neutral threads line under the questions',
        (tester) async {
      final result = StudyResult(
        reference: _request().reference,
        source: StudySource.gemini,
        cachedAt: DateTime.now(),
        isAvailable: true,
        sections: const [
          StudySection(
            kind: StudySectionKind.questionsToCarry,
            en: "Where do you need the Shepherd's presence?",
            enSub:
                'The LORD stays present as a shepherd, even in the darkest valley.',
          ),
        ],
      );
      await _pumpResult(tester, result);

      // A tall viewport so the lazy ListView actually builds the takeaway row
      // (the provenance pill above it pushes content below a 600px frame).
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pump();

      expect(find.text('The passage itself says'), findsOneWidget);
      expect(
          find.text(
              'The LORD stays present as a shepherd, even in the darkest valley.'),
          findsOneWidget);
    });

    testWidgets('renders no threads when the questions carry none',
        (tester) async {
      await _pumpResult(tester, _noTermsResult());
      expect(find.text('The passage itself says'), findsNothing);
    });
  });

  group('non-silent unavailability', () {
    testWidgets('an offline assembly shows the reason banner plus the note',
        (tester) async {
      final offlineNote = StudyResult(
        reference: _request().reference,
        source: StudySource.knowledge,
        cachedAt: DateTime.now(),
        isAvailable: true,
        unavailability: StudyUnavailability.offline,
        sections: const [
          StudySection(
            kind: StudySectionKind.passageOverview,
            en: 'The book background for this passage.',
          ),
        ],
      );
      await _pumpResult(tester, offlineNote);

      expect(find.text('AI study is temporarily unavailable'), findsOneWidget,
          reason: 'the reader must always be told why AI was unavailable');
      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(find.text('Offline note'), findsOneWidget,
          reason: 'the fallback must be labeled, never silent');
      expect(find.text('Continue with Offline Study'), findsOneWidget);
      // No "Add my Gemini API key" for a pure offline failure.
      expect(find.text('Add my Gemini API key'), findsNothing);
    });

    testWidgets('dismissing the unavailable banner keeps the note readable',
        (tester) async {
      final offlineNote = StudyResult(
        reference: _request().reference,
        source: StudySource.knowledge,
        cachedAt: DateTime.now(),
        isAvailable: true,
        unavailability: StudyUnavailability.timeout,
        sections: const [
          StudySection(
            kind: StudySectionKind.passageOverview,
            en: 'The book background for this passage.',
          ),
        ],
      );
      await _pumpResult(tester, offlineNote);
      await tester.tap(find.text('Continue with Offline Study'));
      await tester.pumpAndSettle();

      expect(find.text('AI study is temporarily unavailable'), findsNothing,
          reason: 'dismissing hides the banner for this open');
      expect(find.text('The book background for this passage.'), findsOneWidget,
          reason: 'the note underneath stays readable');
    });

    testWidgets('a rate-limit failure offers adding a personal key',
        (tester) async {
      final limited = StudyResult(
        reference: _request().reference,
        source: StudySource.knowledge,
        cachedAt: DateTime.now(),
        isAvailable: true,
        unavailability: StudyUnavailability.rateLimited,
        sections: const [
          StudySection(
            kind: StudySectionKind.passageOverview,
            en: 'The book background for this passage.',
          ),
        ],
      );
      await _pumpResult(tester, limited);
      expect(find.text('Add my Gemini API key'), findsOneWidget,
          reason: 'a personal key can bypass a shared-key rate limit');
    });
  });

  group('provenance label', () {
    testWidgets('an AI note is labeled as generated with AI', (tester) async {
      await _pumpResult(tester, _result());
      expect(find.text('Generated with AI'), findsOneWidget);
      expect(find.text('Offline note'), findsNothing);
    });

    testWidgets('a curated bank note is labeled as an offline note',
        (tester) async {
      final banked = StudyResult(
        reference: _request().reference,
        source: StudySource.localBank,
        cachedAt: DateTime.now(),
        isAvailable: true,
        sections: const [
          StudySection(
            kind: StudySectionKind.passageOverview,
            en: 'A curated note.',
          ),
        ],
      );
      await _pumpResult(tester, banked);
      expect(find.text('Offline note'), findsOneWidget);
      expect(find.text('Generated with AI'), findsNothing);
    });
  });

  group('daily limit', () {
    testWidgets('the limit banner uses the exact required copy', (tester) async {
      final limited = StudyResult(
        reference: _request().reference,
        source: StudySource.knowledge,
        cachedAt: DateTime.now(),
        isAvailable: true,
        limitReached: true,
        sections: const [
          StudySection(
            kind: StudySectionKind.passageOverview,
            en: 'The book background for this passage.',
          ),
        ],
      );
      await _pumpResult(tester, limited);
      expect(find.text("You've reached today's AI study limit."),
          findsOneWidget);
      expect(find.text('Continue with Offline Study'), findsOneWidget);
      expect(find.text('Add my Gemini API key'), findsOneWidget);
    });
  });
}

/// Pumps the panel for a given [StudyResult] with real l10n, so hierarchy and
/// threads rendering assertions can see the app's actual strings.
Future<void> _pumpResult(WidgetTester tester, StudyResult result) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studySourcesProvider.overrideWith((ref) async =>
            StudySourceRegistry.fromJsonString(
                File('assets/data/study_sources.json').readAsStringSync())),
        studyCrossRefProvider.overrideWith((ref) async => loadTestCrossRefs()),
        studyServiceProvider.overrideWith((ref) async => StudyService(
              backend: _FakeBackend(result),
              readCache: (_) async => null,
              writeCache: (_, _) async {},
            )),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: StudyPanel(request: _request(), isAm: false)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

StudyResult _noTermsResult() => StudyResult(
      reference: _request().reference,
      source: StudySource.gemini,
      cachedAt: DateTime.now(),
      isAvailable: true,
      sections: const [
        StudySection(
          kind: StudySectionKind.originalLanguage,
          en: 'A shepherd leads, feeds, and protects the flock.',
        ),
      ],
    );

class _FakeBackend implements StudyBackend {
  final StudyResult result;
  _FakeBackend(this.result);

  @override
  Future<StudyAttempt> study(StudyRequest request) async =>
      StudyAttempt.available(result);
}

/// A backend that answers after a real time delay, so the test can assert the
/// panel holds its loading state instead of hanging or showing a blank frame.
class _DelayedBackend implements StudyBackend {
  final StudyResult Function() build;
  final void Function() calls;
  _DelayedBackend(this.build, {required this.calls});

  @override
  Future<StudyAttempt> study(StudyRequest request) async {
    calls();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return StudyAttempt.available(build());
  }
}