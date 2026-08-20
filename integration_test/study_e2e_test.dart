import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:beslet_app/core/ai/ai_key_store.dart';
import 'package:beslet_app/core/ai/study/study_diagnostics.dart';
import 'package:beslet_app/core/ai/study/study_models.dart';
import 'package:beslet_app/core/ai/study/study_provider.dart';
import 'package:beslet_app/core/theme/app_theme.dart';
import 'package:beslet_app/features/spiritual/widgets/study_panel.dart';
import 'package:beslet_app/l10n/app_localizations.dart';

/// End-to-end verification of the Study feature running on a real device:
/// the curated bank load, the live AI transport (bundled or user key), the
/// validator, the service cache, and the actual on-screen panel render — in
/// English and Amharic, single verse / multiple verses / whole chapter.
///
/// Run:
///   flutter test integration_test/study_e2e_test.dart -d `device-id`
/// Optionally provide a personal Gemini key to also verify the user-key path:
///   flutter test integration_test/study_e2e_test.dart -d `device-id` \
///     --dart-define=TEST_GEMINI_KEY=AIza...
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('study pipeline end-to-end on device', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Resolve the real StudyService (loads the bundled bank, canon, intros,
    // cross-refs and sources from the app bundle on device).
    final service = await container.read(studyServiceProvider.future);
    debugPrint('study-e2e: studyService ready');

    const enMatt3 =
        'Blessed are the poor in spirit, for theirs is the kingdom of heaven.';
    const enJohn17 =
        'For God did not send his Son into the world to condemn the world, but to save the world through him.';
    const enJohn18 =
        'Whoever believes in him is not condemned, but whoever does not believe stands condemned already because they have not believed in the name of God\'s one and only Son.';
    const enPs1 = 'Shout for joy to the LORD, all the earth.';
    const enPs2 = 'Worship the LORD with gladness; come before him with joyful songs.';
    const enPs3 =
        'Know that the LORD is God. It is he who made us, and we are his; we are his people, the sheep of his pasture.';
    const enPs4 = 'Enter his gates with thanksgiving and his courts with praise; give thanks to him and praise his name.';
    const enPs5 =
        'For the LORD is good and his love endures forever; his faithfulness continues through all generations.';
    const amMatt9 = 'ሰላም አድራጊዎች ብጹዓን ናቸው፤ የእግዚአብሔር ልጆች ተብለው ይጠራሉና።';
    const amMatt10 = 'ስለ ጽድቅ ሲባል የተሰደዱ ብጹዓን ናቸው፤ የመንግሥተ ሰማያት የእነርሱ ናትና።';

    // All passages are intentionally *unbanked* so every one of them must go
    // through the live Gemini transport (the bank only covers 8 passages).
    final p1 = StudyRequest(
      reference: const StudyReference(
          bookId: 'matthew', chapter: 5, startVerse: 3, endVerse: 3),
      isAmharic: false,
      verseTexts: const [enMatt3],
    );
    final p2 = StudyRequest(
      reference: const StudyReference(
          bookId: 'john', chapter: 3, startVerse: 17, endVerse: 18),
      isAmharic: false,
      verseTexts: const [enJohn17, enJohn18],
    );
    final p3 = StudyRequest(
      reference: const StudyReference(
          bookId: 'psalms', chapter: 100, startVerse: 1, endVerse: 5),
      isAmharic: false,
      verseTexts: const [enPs1, enPs2, enPs3, enPs4, enPs5],
      depth: StudyDepth.brief,
    );
    final p4 = StudyRequest(
      reference: const StudyReference(
          bookId: 'matthew', chapter: 5, startVerse: 9, endVerse: 10),
      isAmharic: true,
      verseTexts: const [amMatt9, amMatt10],
    );

    String diag([StudyDiagnostics? d]) {
      final di = d ?? StudyDiagnostics.instance;
      return 'key=${di.keySource ?? '-'} len=${di.keyLength ?? '-'} '
          'http=${di.httpStatus ?? '-'} reason=${di.failureReason?.name ?? '-'} '
          'detail=${(di.failureDetail ?? '-').replaceAll('\n', ' ')} '
          'cacheHit=${di.cacheHit ?? '-'} '
          'payload=${(di.payloadSnippet ?? '-').replaceAll('\n', ' ')}';
    }

    String outline(StudyResult r) {
      final textChars = r.sections.fold<int>(
          0,
          (a, s) =>
              a + s.textFor(false).length + s.textFor(true).length);
      return 'src=${r.source.name} avail=${r.isAvailable} '
          'sections=${r.sections.length} unavail=${r.unavailability.name} '
          'limit=${r.limitReached} textChars=$textChars '
          'kinds=${r.sections.map((s) => s.kind.name).join(',')}';
    }

    Future<StudyResult> run(StudyRequest req, String label) async {
      final now = DateTime.now();
      final r = await service.study(req);
      final ms = DateTime.now().difference(now).inMilliseconds;
      debugPrint('study-e2e: [$label] ${req.reference.referenceFor(req.isAmharic)} '
          'in ${ms}ms -> ${outline(r)} | ${diag()}');
      return r;
    }

    // ── PHASE 1: the real StudyPanel renders on screen ────────────────────
    debugPrint('study-e2e: PHASE 1 — live StudyPanel for '
        '${p1.reference.referenceFor(false)}');
    await tester.pumpWidget(_Harness(
      container: container,
      child: StudyPanel(request: p1, isAm: false),
    ));
    await _pumpUntil(tester,
        () => find.byType(CircularProgressIndicator).evaluate().isEmpty,
        timeout: const Duration(seconds: 150));
    await tester.pump(const Duration(milliseconds: 300));

    final passageShown =
        find.textContaining('poor in spirit').evaluate().isNotEmpty;
    final contentText = find
        .descendant(
            of: find.byType(StudyPanel),
            matching: find.byType(Text))
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .where((t) => t.trim().isNotEmpty)
        .toList();
    debugPrint(
        'study-e2e: panel passage card shown=$passageShown; '
        'visible text blocks=${contentText.length}');
    debugPrint('study-e2e: panel first texts: '
        '${contentText.take(4).map((t) => t.replaceAll('\n', ' ')).toList()}');
    final panelResult = await service.study(p1);
    debugPrint('study-e2e: panel result -> ${outline(panelResult)} | ${diag()}');

    expect(find.byType(CircularProgressIndicator).evaluate().isEmpty, isTrue,
        reason: 'panel never finished loading');
    expect(passageShown, isTrue,
        reason: 'panel did not render the passage card (no real content)');
    expect(panelResult.isAvailable, isTrue,
        reason: 'study returned unavailable: ${panelResult.unavailability.name}');
    expect(panelResult.sections, isNotEmpty,
        reason: 'study returned a note with no sections');

    // ── PHASE 2: live AI transport across passages ────────────────────────
    debugPrint('study-e2e: PHASE 2 — live backend runs (all unbanked)');
    final r2 = await run(p2, 'john 3:17-18 en');
    final r3 = await run(p3, 'psalm 100 en (whole chapter, brief)');
    final r4 = await run(p4, 'matt 5:9-10 am');

    for (final r in [r2, r3, r4]) {
      expect(r.isAvailable, isTrue,
          reason: 'a study failed: ${r.unavailability.name}');
      expect(r.sections, isNotEmpty,
          reason: 'a study produced no sections');
    }

    // ── PHASE 3: cache behavior (memory + disk) ───────────────────────────
    debugPrint('study-e2e: PHASE 3 — cache');
    final cached1 = await run(p1, 'matt 5:3 again (memory expected)');
    expect(cached1.source, panelResult.source,
        reason: 'memory cache changed the source');
    await service.refresh(p1); // drop memory + inflight, keep disk
    final cached2 =
        await run(p1, 'matt 5:3 after refresh (disk expected)');
    expect(cached2.isAvailable, isTrue);
    expect(cached2.sections, isNotEmpty);
    debugPrint('study-e2e: disk cache hit flag = '
        '${StudyDiagnostics.instance.cacheHit}');

    // ── PHASE 4: personal Gemini key path (opt-in) ────────────────────────
    const envKey = String.fromEnvironment('TEST_GEMINI_KEY');
    if (envKey.isNotEmpty) {
      debugPrint('study-e2e: PHASE 4 — personal key path');
      await AiKeyStore().saveUserKey(envKey);
      final r2b = await service.refresh(p2, bypassDisk: true);
      debugPrint('study-e2e: [with personal key] john 3:17-18 -> '
          '${outline(r2b)} | ${diag()}');
      expect(r2b.isAvailable, isTrue,
          reason: 'personal-key study failed: ${r2b.unavailability.name}');
      expect(StudyDiagnostics.instance.keySource, 'user',
          reason: 'study did not use the personal key');
    } else {
      debugPrint('study-e2e: PHASE 4 skipped (no TEST_GEMINI_KEY provided)');
    }

    // ── Final summary ─────────────────────────────────────────────────────
    debugPrint('study-e2e: === END-TO-END RESULT ===');
    debugPrint('study-e2e: panel rendered content: $passageShown');
    for (final r in [panelResult, r2, r3, r4]) {
      debugPrint('study-e2e: ${r.reference.referenceFor(false)} '
          '-> src=${r.source.name} avail=${r.isAvailable} '
          'unavail=${r.unavailability.name} '
          'sections=${r.sections.length}');
    }
    debugPrint('study-e2e: final diagnostics: ${diag()}');
  });
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 90),
  Duration step = const Duration(milliseconds: 300),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(step);
    if (condition()) return;
  }
  throw TimeoutException('condition not met within $timeout');
}

class _Harness extends StatelessWidget {
  const _Harness({required this.container, required this.child});

  final ProviderContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.light,
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('am')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SafeArea(child: child),
        ),
      ),
    );
  }
}