import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/growth_provider.dart';
import '../../core/providers/journal_provider.dart';
import '../../core/providers/soul_log_provider.dart';
import '../../core/services/growth_content.dart';
import '../../core/services/scripture_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/beslet_card.dart';
import '../../shared/widgets/error_card.dart';
import 'plant_journey_sheet.dart';
import 'harvest_letter_sheet.dart';
import 'widgets/day_word_card.dart';
import 'widgets/encouragement_card.dart';
import 'widgets/fruit_list.dart';
import 'widgets/question_card.dart';
import 'widgets/season_story_card.dart';
import 'widgets/weather_card.dart';
import 'widgets/vineyard_scene.dart';

class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final journeyAsync = ref.watch(journeyProvider);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: journeyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ErrorCard(message: 'Could not load the Vineyard'),
            ),
          ),
          data: (journey) {
            if (journey == null) {
              return _EmptyVineyard();
            }
            if (journey.harvested) {
              return _HarvestedVineyard(journey: journey);
            }
            return _LivingVineyard(journey: journey);
          },
        ),
      ),
    );
  }
}

/// Before a journey is planted: a quiet, empty field awaiting the first seed.
class _EmptyVineyard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.bottomPadding,
      ),
      children: [
        _vineyardHeader(c, t, l),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: VineyardScene(
            seed: 1,
            growth01: 0,
            branches: 0,
            fruitCount: 0,
            fruitColor: const Color(0xFF7FB36A),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BesletCard(
          variant: CardVariant.secondary,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.soilYoursGrowingHis,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.vineyardEmptyBody,
                style: t.bodyMedium.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openPlantSheet(context),
                  icon: const Icon(Icons.grass),
                  label: Text(l.plantIt),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.of(context).primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The active journey: a living vine fed by the day's Word, weather, and the
/// user's own planted answers.
class _LivingVineyard extends ConsumerWidget {
  final GrowthJourneyData journey;
  const _LivingVineyard({required this.journey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final isAm = l.localeName == 'am';

    final day = ref.watch(journeyDayProvider);
    final intention = ref.watch(activeIntentionProvider) ?? JourneyIntention.abide;
    final timeframeDays = ref.watch(activeTimeframeDaysProvider);
    final movement = ref.watch(activeMovementProvider) ?? JourneyMovement.planting;
    final mood = ref.watch(todaySoulLogProvider).valueOrNull?.mood;

    final geometry = GrowthContent.vineGeometry(day, timeframeDays);
    final stage = GrowthContent.vineStageFor(day, timeframeDays);
    final intentionLabel = GrowthContent.intentionLabel(intention);
    final movementTitle = GrowthContent.movementTitle(movement);
    final stageLine = GrowthContent.vineStageLine(stage);
    final grace = GrowthContent.graceNote();

    final seed = journey.id.hashCode;
    final fruitColor = Color.lerp(const Color(0xFF7FB36A), const Color(0xFFE8C53A), geometry.growth01)!;

    final history = ref.watch(journalHistoryProvider).valueOrNull ?? <JournalEntryData>[];
    final fruits = history
        .where((e) => e.date.compareTo(journey.startDate) >= 0 && e.content?.trim().isNotEmpty == true)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.bottomPadding,
      ),
      children: [
        _vineyardHeader(c, t, l),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: VineyardScene(
            seed: seed,
            growth01: geometry.growth01,
            branches: geometry.branches,
            fruitCount: _fruitCountFor(day, geometry.growth01),
            fruitColor: fruitColor,
            mood: mood,
            showBlossoms: stage == VineStage.blooming,
            onFruitTap: fruits.isEmpty
                ? null
                : (i) {
                    if (i < fruits.length) {
                      final entry = fruits[i];
                      showFruitDialog(
                        context,
                        content: entry.content ?? '',
                        day: GrowthContent.journeyDay(
                          DateTime.parse(journey.startDate),
                          DateTime.parse(entry.date),
                        ),
                        isAm: isAm,
                      );
                    }
                  },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BesletCard(
          variant: CardVariant.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.eco, size: 18, color: AppColors.of(context).primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isAm ? intentionLabel.am : intentionLabel.en,
                      style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${l.dayLabel} $day',
                    style: t.labelSmall.copyWith(color: c.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isAm ? movementTitle.am : movementTitle.en,
                style: t.bodyMedium.copyWith(color: AppColors.of(context).primary, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isAm ? stageLine.am : stageLine.en,
                style: t.bodyMedium.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        BesletCard(
          variant: CardVariant.tertiary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.light_mode_outlined, size: 16, color: AppColors.of(context).primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isAm ? grace.am : grace.en,
                  style: t.bodySmall.copyWith(color: c.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SeasonStoryCard(movement: movement, isAm: isAm),
        const SizedBox(height: AppSpacing.sm),
        DayWordCard(verse: ScriptureService.threadVerseFor(DateTime.now()), isAm: isAm),
        const SizedBox(height: AppSpacing.sm),
        QuestionCard(
          question: GrowthContent.questionFor(intention, day).en,
          questionAm: GrowthContent.questionFor(intention, day).am,
          isAm: isAm,
        ),
        const SizedBox(height: AppSpacing.sm),
        WeatherCard(mood: mood, isAm: isAm),
        const SizedBox(height: AppSpacing.sm),
        EncouragementCard(day: day, mood: mood, isAm: isAm),
        const SizedBox(height: AppSpacing.sm),
        FruitList(startDate: journey.startDate, isAm: isAm),
        const SizedBox(height: AppSpacing.sm),
        _HarvestActionCard(
          isAm: isAm,
          answers: fruits.map((e) => e.content ?? '').toList(),
          movement: movement,
          onHarvest: () => _openHarvestSheet(context, ref, fruits),
        ),
      ],
    );
  }
}

class _HarvestActionCard extends ConsumerWidget {
  final bool isAm;
  final List<String> answers;
  final JourneyMovement movement;
  final VoidCallback onHarvest;

  const _HarvestActionCard({
    required this.isAm,
    required this.answers,
    required this.movement,
    required this.onHarvest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final horizon = GrowthContent.horizonLine();
    return BesletCard(
      variant: CardVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAm ? horizon.am : horizon.en,
            style: t.bodyMedium.copyWith(color: c.textSecondary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: AppSpacing.sm),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onHarvest,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.of(context).primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_basket_outlined, size: 18, color: AppColors.of(context).primary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l.harvestWhenReady,
                      style: t.labelLarge.copyWith(
                        color: AppColors.of(context).primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// After a journey has been harvested: the gathered fruit, the quiet field,
/// and an open invitation to plant again.
class _HarvestedVineyard extends ConsumerWidget {
  final GrowthJourneyData journey;
  const _HarvestedVineyard({required this.journey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final isAm = l.localeName == 'am';
    final day = ref.watch(journeyDayProvider);
    final timeframeDays = ref.watch(activeTimeframeDaysProvider);
    final mood = ref.watch(todaySoulLogProvider).valueOrNull?.mood;
    final geometry = GrowthContent.vineGeometry(day, timeframeDays);
    final fruitColor = Color.lerp(const Color(0xFF7FB36A), const Color(0xFFE8C53A), geometry.growth01)!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.sm,
        AppSpacing.screenPadding,
        AppSpacing.bottomPadding,
      ),
      children: [
        _vineyardHeader(c, t, l),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: VineyardScene(
            seed: journey.id.hashCode,
            growth01: geometry.growth01,
            branches: geometry.branches,
            fruitCount: _fruitCountFor(day, geometry.growth01),
            fruitColor: fruitColor,
            mood: mood,
            showBlossoms: false,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        BesletCard(
          variant: CardVariant.secondary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.harvestGathered,
                style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.harvestGatheredBody,
                style: t.bodyMedium.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openPlantSheet(context),
                  icon: const Icon(Icons.grass),
                  label: Text(l.plantAgain),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.of(context).primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FruitList(startDate: journey.startDate, isAm: isAm),
      ],
    );
  }
}

Future<void> _openHarvestSheet(
  BuildContext context,
  WidgetRef ref,
  List<JournalEntryData> fruits,
) async {
  final isAm = AppLocalizations.of(context)?.localeName == 'am';
  final movement = ref.read(activeMovementProvider) ?? JourneyMovement.planting;
  final choice = await showHarvestLetterSheet(
    context,
    answers: fruits.map((e) => e.content ?? '').toList(),
    movement: movement,
    isAm: isAm,
  );
  if (choice == HarvestChoice.harvest && context.mounted) {
    await ref.read(journeyNotifierProvider.notifier).harvestJourney();
  }
}

int _fruitCountFor(int day, double growth01) {
  if (day <= 1) return 0;
  if (growth01 < 0.2) return 1;
  if (growth01 < 0.45) return 2;
  if (growth01 < 0.7) return 3;
  return 4;
}

Widget _vineyardHeader(ThemePalette c, AppTextTheme t, AppLocalizations l) {
  return Row(
    children: [
      Expanded(
        child: Text(
          l.vineyardTitle,
          style: t.displaySmall,
        ),
      ),
    ],
  );
}

Future<void> _openPlantSheet(BuildContext context) async {
  final planted = await showPlantJourneySheet(context);
  if (planted && context.mounted) {
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.plantedSnack),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
