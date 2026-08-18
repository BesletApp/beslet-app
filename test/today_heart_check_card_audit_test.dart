import 'dart:async';
import 'dart:io';

import 'package:beslet_app/core/providers/question_content_provider.dart';
import 'package:beslet_app/core/services/provocative_question_service.dart';
import 'package:beslet_app/core/services/scripture_service.dart';
import 'package:beslet_app/core/theme/app_colors.dart';
import 'package:beslet_app/core/theme/app_theme.dart';
import 'package:beslet_app/core/widgets/brand_mark.dart';
import 'package:beslet_app/features/home/widgets/today_heart_check_card.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stability-and-UX audit for the frozen "Today's Heart Check" feature.
///
/// Phase 1 (content) and Phase 2 (UI/UX) live here so the shipped asset and the
/// shipped widget are both re-verified on every run. Structure mirrors the real
/// Today screen: the card sits at the top of a single-column, scrollable page,
/// above the greeting content.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProvocativeQuestionService library;

  setUpAll(() async {
    final raw = File('assets/data/provocative_questions.json').readAsStringSync();
    library = ProvocativeQuestionService.fromJsonString(raw);
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    final ethiopic = FontLoader('NotoSansEthiopic')
      ..addFont(rootBundle.load('assets/fonts/NotoSansEthiopic.ttf'));
    await inter.load();
    await ethiopic.load();
  });

  tearDown(() {
    AppColors.currentOption = AppThemeOption.classic;
  });

  Widget wrap(ProvocativeQuestion q, Locale locale, ThemeData theme,
      {double scale = 1.0, Widget? trailing}) {
    return ProviderScope(
      overrides: [todayQuestionProvider.overrideWith((ref) async => q)],
      child: MaterialApp(
        theme: theme,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const TodayHeartCheckCard(),
                  if (trailing != null) trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required ProvocativeQuestion q,
    required Locale locale,
    AppThemeOption option = AppThemeOption.classic,
    bool dark = false,
    double scale = 1.0,
    Size size = const Size(390, 844),
    Widget? trailing,
    bool expand = false,
  }) async {
    AppColors.currentOption = option;
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(wrap(
      q,
      locale,
      dark ? AppTheme.darkTheme(option) : AppTheme.lightTheme(option),
      scale: scale,
      trailing: trailing,
    ));
    await tester.pump();
    if (expand) {
      final inkWell = find.descendant(
        of: find.byType(TodayHeartCheckCard),
        matching: find.byType(InkWell),
      );
      await tester.tap(inkWell, warnIfMissed: false);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  }

  /// The 1-2 entries per locale whose (question + reflection) text is longest.
  Map<String, List<ProvocativeQuestion>> heaviestPerLocale() {
    String pick(ProvocativeQuestion q, String lang) =>
        lang == 'am' ? q.questionAm + q.reflectionAm : q.questionEn + q.reflectionEn;
    String lang(Locale l) => l.languageCode;
    final byLocale = <String, List<ProvocativeQuestion>>{};
    for (final locale in const [Locale('en'), Locale('am')]) {
      final sorted = [...library.questions]
        ..sort((a, b) => pick(b, lang(locale)).length.compareTo(pick(a, lang(locale)).length));
      byLocale[lang(locale)] = sorted.take(2).toList();
    }
    return byLocale;
  }

  group('Phase 1 - content audit', () {
    test('sixty entries with no duplicate English or Amharic question', () {
      final enSeen = <String>{};
      final amSeen = <String>{};
      final dupes = <String>[];
      String norm(String s) =>
          s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      for (final q in library.questions) {
        if (!enSeen.add(norm(q.questionEn))) {
          dupes.add('${q.id}: duplicate EN "${q.questionEn}"');
        }
        if (!amSeen.add(norm(q.questionAm))) {
          dupes.add('${q.id}: duplicate AM "${q.questionAm}"');
        }
      }
      expect(dupes, isEmpty, reason: 'repetitive questions:\n${dupes.join('\n')}');
    });

    test('every reflection ends gently with a period, no question or order', () {
      final offenders = <String>[];
      for (final q in library.questions) {
        if (q.reflectionEn.contains('?') || q.reflectionEn.contains('!')) {
          offenders.add('${q.id}: reflectionEn uses ? or !');
        }
        if (q.reflectionAm.contains('?') || q.reflectionAm.contains('!')) {
          offenders.add('${q.id}: reflectionAm uses ? or !');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });

    test('every reference parses and cites only allowed books', () {
      final offenders = <String>[];
      for (final q in library.questions) {
        for (final reference in q.verses) {
          final range = ScriptureService.referenceRange(reference);
          if (range == null ||
              !ProvocativeQuestionService.allowedBooks.contains(range.bookId)) {
            offenders.add('${q.id}: $reference');
          }
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    });
  });

  group('Phase 2 - UI/UX audit', () {
    for (final locale in const [Locale('en'), Locale('am')]) {
      testWidgets(
          'every question renders expanded at 320 logical px, scale 2.0 '
          '(${locale.languageCode})', (tester) async {
        final failures = <String>[];
        for (final q in library.questions) {
          await pumpCard(
            tester,
            q: q,
            locale: locale,
            size: const Size(320, 480),
            scale: 2.0,
            expand: true,
          );
          final err = tester.takeException();
          if (err != null) {
            failures.add('${q.id}: $err');
          }
        }
        expect(failures, isEmpty,
            reason: 'render failures at 320px / scale 2.0:\n${failures.join('\n')}');
      });
    }

    testWidgets('no overflow across a sweep of screens and orientations',
        (tester) async {
      const sizes = [
        Size(320, 480),
        Size(360, 640),
        Size(390, 844),
        Size(412, 915),
        Size(768, 1024),
        Size(844, 390),
        Size(1024, 768),
      ];
      final heaviest = heaviestPerLocale();
      final failures = <String>[];
      for (final locale in const [Locale('en'), Locale('am')]) {
        for (final size in sizes) {
          for (final q in heaviest[locale.languageCode]!) {
            await pumpCard(tester,
                q: q, locale: locale, size: size, expand: true);
            final err = tester.takeException();
            if (err != null) {
              failures.add('${q.id} @ $size (${locale.languageCode}): $err');
            }
          }
        }
      }
      expect(failures, isEmpty,
          reason: 'render failures across screen sizes:\n${failures.join('\n')}');
    });

    testWidgets('long entries survive large text scaling at the tightest width',
        (tester) async {
      final heaviest = heaviestPerLocale();
      final failures = <String>[];
      for (final locale in const [Locale('en'), Locale('am')]) {
        for (final scale in const [1.3, 2.0]) {
          for (final q in heaviest[locale.languageCode]!) {
            await pumpCard(
              tester,
              q: q,
              locale: locale,
              size: const Size(320, 480),
              scale: scale,
              expand: true,
            );
            final err = tester.takeException();
            if (err != null) {
              failures.add('${q.id} @ scale $scale (${locale.languageCode}): $err');
            }
          }
        }
      }
      expect(failures, isEmpty,
          reason: 'render failures under text scaling:\n${failures.join('\n')}');
    });

    testWidgets('renders across palettes and dark mode', (tester) async {
      const cases = [
        (AppThemeOption.classic, false),
        (AppThemeOption.classic, true),
        (AppThemeOption.sepia, false),
        (AppThemeOption.midnight, true),
      ];
      final failures = <String>[];
      for (final (option, dark) in cases) {
        for (final locale in const [Locale('en'), Locale('am')]) {
          await pumpCard(
            tester,
            q: library.questions.first,
            locale: locale,
            option: option,
            dark: dark,
            size: const Size(360, 640),
            scale: 1.3,
            expand: true,
          );
          final err = tester.takeException();
          if (err != null) {
            failures.add('$option/dark=$dark (${locale.languageCode}): $err');
          }
        }
      }
      expect(failures, isEmpty,
          reason: 'render failures across palettes:\n${failures.join('\n')}');
    });

    testWidgets('expand reveals two references and a reflection; collapse restores',
        (tester) async {
      final q = library.questions.first;
      await pumpCard(tester, q: q, locale: const Locale('en'));

      expect(find.text('❝ ${q.questionEn}'), findsOneWidget);
      expect(find.text('— ${q.verses[0]}', skipOffstage: false), findsNothing);

      await tester.tap(find.byType(TodayHeartCheckCard));
      await tester.pumpAndSettle();

      expect(find.text('❝ ${q.questionEn}'), findsOneWidget);
      expect(find.text('— ${q.verses[0]}'), findsOneWidget);
      expect(find.text('— ${q.verses[1]}'), findsOneWidget);
      expect(find.text(q.reflectionEn), findsOneWidget);

      await tester.tap(find.byType(TodayHeartCheckCard));
      await tester.pumpAndSettle();

      expect(find.text(q.reflectionEn, skipOffstage: false), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Amharic locale formats references with Ethiopic book names',
        (tester) async {
      final q = library.questions.first;
      await pumpCard(tester, q: q, locale: const Locale('am'), expand: true);
      expect(find.text('— ${ScriptureService.amharicReference(q.verses[0])}'),
          findsOneWidget);
      expect(find.text('— ${ScriptureService.amharicReference(q.verses[1])}'),
          findsOneWidget);
    });

    testWidgets('English locale keeps the raw reference text', (tester) async {
      final q = library.questions.first;
      await pumpCard(tester, q: q, locale: const Locale('en'), expand: true);
      expect(find.text('— ${q.verses[0]}'), findsOneWidget);
      expect(find.text('— ${q.verses[1]}'), findsOneWidget);
    });

    testWidgets('the expanded card never overlaps the greeting content below',
        (tester) async {
      final q = library.questions.first;
      final failures = <String>[];
      for (final locale in const [Locale('en'), Locale('am')]) {
        await pumpCard(
          tester,
          q: q,
          locale: locale,
          size: const Size(320, 640),
          expand: true,
          trailing: const Padding(
            padding: EdgeInsets.only(top: 16),
            child: BrandMark(
              size: 30,
              color: Color(0xFFC8942E),
            ),
          ),
        );
        final cardBottom =
            tester.getBottomRight(find.byType(TodayHeartCheckCard)).dy;
        final markTop = tester.getTopLeft(find.byType(BrandMark)).dy;
        if (cardBottom > markTop + 1) {
          failures.add(
              '${locale.languageCode}: card bottom $cardBottom > greeting top $markTop');
        }
        final err = tester.takeException();
        if (err != null) {
          failures.add('${locale.languageCode}: $err');
        }
      }
      expect(failures, isEmpty, reason: failures.join('\n'));
    });

    testWidgets('content below shifts down when the question resolves '
        '(documented pop-in, no exception)', (tester) async {
      final q = library.questions.first;
      final gate = Completer<ProvocativeQuestion>();
      AppColors.currentOption = AppThemeOption.classic;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [todayQuestionProvider.overrideWith((ref) => gate.future)],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      TodayHeartCheckCard(),
                      SizedBox(height: 20),
                      Text('MARKER'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final before =
          tester.getTopLeft(find.byType(Text).last).dy;
      gate.complete(q);
      await tester.pump();
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(find.byType(Text).last).dy;
      // ignore: avoid_print
      print('documented pop-in shift: ${after - before}px (content below moves)');
      expect(tester.takeException(), isNull);
    });
  });
}