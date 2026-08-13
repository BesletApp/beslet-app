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
          kind: StudySectionKind.meaningBackground,
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
          kind: StudySectionKind.reflection,
          en: 'Where does the shepherd lead?',
        ),
        StudySection(
          kind: StudySectionKind.setting,
          en: 'A psalm of David.',
        ),
        StudySection(
          kind: StudySectionKind.whatTextSays,
          en: 'The LORD is my shepherd.',
        ),
      ],
    );
    await pump(tester, backend: _FakeBackend(outOfOrder));

    final titles = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    final settingIndex = titles.indexOf('Setting');
    final whatTextIndex = titles.indexOf('What the Text Communicates');
    final reflectionIndex = titles.indexOf('Consider');
    expect(settingIndex, lessThan(whatTextIndex),
        reason: 'Setting must render before What the Text Communicates');
    expect(whatTextIndex, lessThan(reflectionIndex),
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
          kind: StudySectionKind.setting,
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
          kind: StudySectionKind.biblicalConnections,
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
            kind: StudySectionKind.whatTextSays,
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
            kind: StudySectionKind.meaningBackground,
            en: '• The shepherd provides and restores.\n• He stays present.',
          ),
        ],
      );
      await _pumpResult(tester, result);

      expect(find.textContaining('provides and restores'), findsOneWidget);
      expect(find.textContaining('He stays present'), findsOneWidget);
    });
  });

  group('takeaway rendering', () {
    testWidgets('renders the neutral takeaway under the reflection question',
        (tester) async {
      final result = StudyResult(
        reference: _request().reference,
        source: StudySource.gemini,
        cachedAt: DateTime.now(),
        isAvailable: true,
        sections: const [
          StudySection(
            kind: StudySectionKind.reflection,
            en: "Where do you need the Shepherd's presence?",
            takeawayEn:
                'The LORD stays present as a shepherd, even in the darkest valley.',
          ),
        ],
      );
      await _pumpResult(tester, result);

      expect(find.text('The passage itself says'), findsOneWidget);
      expect(
          find.text(
              'The LORD stays present as a shepherd, even in the darkest valley.'),
          findsOneWidget);
    });

    testWidgets('renders no takeaway when the reflection carries none',
        (tester) async {
      await _pumpResult(tester, _noTermsResult());
      expect(find.text('The passage itself says'), findsNothing);
    });
  });
}

/// Pumps the panel for a given [StudyResult] with real l10n, so hierarchy and
/// takeaway rendering assertions can see the app's actual strings.
Future<void> _pumpResult(WidgetTester tester, StudyResult result) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        studySourcesProvider.overrideWith((ref) async =>
            StudySourceRegistry.fromJsonString(
                File('assets/data/study_sources.json').readAsStringSync())),
        studyCrossRefProvider
            .overrideWith((ref) async => loadTestCrossRefs()),
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
          kind: StudySectionKind.meaningBackground,
          en: 'A shepherd leads, feeds, and protects the flock.',
        ),
      ],
    );

class _FakeBackend implements StudyBackend {
  final StudyResult result;
  _FakeBackend(this.result);

  @override
  Future<StudyResult?> study(StudyRequest request) async => result;
}

/// A backend that answers after a real time delay, so the test can assert the
/// panel holds its loading state instead of hanging or showing a blank frame.
class _DelayedBackend implements StudyBackend {
  final StudyResult Function() build;
  final void Function() calls;
  _DelayedBackend(this.build, {required this.calls});

  @override
  Future<StudyResult?> study(StudyRequest request) async {
    calls();
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return build();
  }
}
