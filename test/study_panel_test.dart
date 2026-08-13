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
