import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beslet_app/core/database/app_database.dart';
import 'package:beslet_app/core/providers/growth_provider.dart';
import 'package:beslet_app/core/providers/journal_provider.dart';
import 'package:beslet_app/core/providers/soul_log_provider.dart';
import 'package:beslet_app/l10n/app_localizations.dart';
import 'package:beslet_app/features/growth/growth_screen.dart';
import 'package:beslet_app/features/growth/widgets/season_story_card.dart';
import 'package:beslet_app/features/growth/widgets/vineyard_scene.dart';

GrowthJourneyData journey({
  required int daysAgo,
  String intention = 'word',
  int? timeframeDays = 30,
}) {
  final start = DateTime.now().subtract(Duration(days: daysAgo)).toIso8601String().substring(0, 10);
  return GrowthJourneyData(
    id: 'j-1',
    intention: intention,
    timeframeDays: timeframeDays,
    startDate: start,
    note: null,
    harvested: false,
    createdAt: DateTime.now().toIso8601String(),
  );
}

void main() {
  Future<void> pumpGrowth(
    WidgetTester tester, {
    GrowthJourneyData? data,
    List<JournalEntryData> history = const [],
    Locale? locale,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          journeyProvider.overrideWith((ref) async => data),
          todaySoulLogProvider.overrideWith((ref) async => null),
          journalEntryProvider.overrideWith((ref) async => null),
          journalHistoryProvider.overrideWith((ref) async => history),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: locale,
          home: const Scaffold(body: GrowthScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('GrowthScreen', () {
    testWidgets('shows the empty Vineyard and a Plant it button when no journey', (tester) async {
      await pumpGrowth(tester, data: null);
      expect(find.text('The Vineyard'), findsOneWidget);
      expect(find.text('Plant it'), findsOneWidget);
      expect(find.byType(VineyardScene), findsOneWidget);
    });

    testWidgets('renders the Vineyard in Amharic when the locale is am', (tester) async {
      await pumpGrowth(tester, data: null, locale: const Locale('am'));
      expect(find.text('የወይን እርሻ'), findsOneWidget);
      expect(find.text('ትክል'), findsOneWidget);
    });

    testWidgets('shows the living Vineyard with the journey day when planted', (tester) async {
      await pumpGrowth(tester, data: journey(daysAgo: 10));
      expect(find.text('The Vineyard'), findsOneWidget);
      expect(find.text('Day 11'), findsOneWidget);
      expect(find.textContaining('To know the Word'), findsOneWidget);
      expect(find.byType(VineyardScene), findsOneWidget);
    });

    testWidgets('shows the season story, encouragement, and fruit list', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await pumpGrowth(
        tester,
        data: journey(daysAgo: 5),
        history: [
          JournalEntryData(
            id: 'e-1',
            date: today,
            content: 'The Word showed me to rest in Him today.',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ],
      );
      expect(find.text('The Season'), findsOneWidget);
      expect(find.text('Your Fruit'), findsOneWidget);
      expect(find.textContaining('rest in Him today'), findsOneWidget);
      expect(find.byType(SeasonStoryCard), findsOneWidget);
    });

    testWidgets('open journey sheet shows intentions and timeframes', (tester) async {
      await pumpGrowth(tester, data: null);
      await tester.tap(find.text('Plant it'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Enter the Vineyard'), findsOneWidget);
      expect(find.text('To know the Word'), findsOneWidget);
      expect(find.text('Just abide'), findsOneWidget);
      expect(find.text('90 days — a season'), findsOneWidget);
      expect(find.text('Open — until I say otherwise'), findsOneWidget);
    });

    testWidgets('open journey sheet can select an intention and timeframe', (tester) async {
      await pumpGrowth(tester, data: null);
      await tester.tap(find.text('Plant it'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('To tend the heart'));
      await tester.pump();
      await tester.ensureVisible(find.text('7 days'));
      await tester.pump();
      await tester.tap(find.text('7 days'));
      await tester.pump();
      expect(find.text('Plant it'), findsWidgets);
    });

    testWidgets('harvest action opens the Harvest Letter sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await pumpGrowth(
        tester,
        data: journey(daysAgo: 40),
        history: [
          JournalEntryData(
            id: 'e-1',
            date: today,
            content: 'I rested in the Vine today.',
            createdAt: DateTime.now().toIso8601String(),
          ),
        ],
      );
      await tester.tap(find.text('The harvest — when you are ready'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('The Harvest'), findsOneWidget);
      expect(find.text('Continue abiding'), findsOneWidget);
      expect(find.textContaining('I rested in the Vine today'), findsWidgets);
    });

    testWidgets('a harvested journey shows the gathered-harvest view', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final harvested = journey(daysAgo: 90);
      final harvestedJourney = GrowthJourneyData(
        id: harvested.id,
        intention: harvested.intention,
        timeframeDays: harvested.timeframeDays,
        startDate: harvested.startDate,
        note: harvested.note,
        harvested: true,
        createdAt: harvested.createdAt,
      );
      await pumpGrowth(tester, data: harvestedJourney);
      expect(find.text('The harvest is gathered.'), findsOneWidget);
      expect(find.text('Plant again'), findsOneWidget);
    });
  });
}
