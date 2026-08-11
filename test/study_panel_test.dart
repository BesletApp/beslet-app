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
  testWidgets('the terms block renders term, transliteration, and meaning',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studySourcesProvider.overrideWith((ref) async =>
              StudySourceRegistry.fromJsonString(
                  File('assets/data/study_sources.json').readAsStringSync())),
          studyServiceProvider.overrideWith((ref) async => StudyService(
                backend: _FakeBackend(_result()),
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

    expect(find.text('Meaning & Background'), findsOneWidget);
    expect(find.textContaining('רֹעִי'), findsOneWidget);
    expect(find.textContaining('ro’i'), findsOneWidget);
    expect(find.text('shepherd'), findsOneWidget);
  });

  testWidgets('the panel renders when terms are absent', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          studySourcesProvider.overrideWith((ref) async =>
              StudySourceRegistry.fromJsonString(
                  File('assets/data/study_sources.json').readAsStringSync())),
          studyServiceProvider.overrideWith((ref) async => StudyService(
                backend: _FakeBackend(_noTermsResult()),
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

    expect(find.text('Meaning & Background'), findsOneWidget);
    expect(find.text('Key terms & original language'), findsNothing);
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
