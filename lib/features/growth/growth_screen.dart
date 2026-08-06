import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/growth_provider.dart';
import '../../core/providers/growth_streams_provider.dart';
import '../../core/providers/daily_flow_provider.dart';
import '../../core/providers/journal_provider.dart';
import '../../core/providers/soul_log_provider.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/providers/vine_life_provider.dart';
import '../../core/services/growth_content.dart';
import '../../core/services/scene_event_bus.dart';
import '../../core/services/vineyard_reminder_service.dart';
import '../../core/services/scripture_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/beslet_card.dart';
import '../../shared/widgets/error_card.dart';
import 'plant_journey_sheet.dart';
import 'harvest_letter_sheet.dart';
import 'widgets/day_word_chip.dart';
import 'widgets/disclosure_tile.dart';
import 'widgets/fruit_drawer.dart';
import 'widgets/fruit_list.dart';
import 'widgets/question_card.dart';
import 'widgets/rhythm_ring.dart';
import 'widgets/stage_path.dart';
import 'widgets/streak_flame.dart';
import 'widgets/weather_card.dart';
import 'widgets/week_bars.dart';
import 'widgets/scene_moment.dart';
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
class _LivingVineyard extends ConsumerStatefulWidget {
  final GrowthJourneyData journey;
  const _LivingVineyard({required this.journey});

  @override
  ConsumerState<_LivingVineyard> createState() => _LivingVineyardState();
}

class _LivingVineyardState extends ConsumerState<_LivingVineyard> {
  /// Guards the delayed recap replay so it dies if the screen is left.
  int? _recapToken;

  /// Whether the garden is celebrating a return after absence.
  bool _revived = false;
  int? _revivalToken;

  /// Transcendence moments the garden may earn.
  late final SceneMomentController _moment = SceneMomentController();
  bool _lampFlared = false;
  JourneyMovement? _lastMovement;

  @override
  void initState() {
    super.initState();
    _scheduleRecap();
    _stampVisit();
    _checkAbsence();
    _maybeDawnGrace();
  }

  /// The garden remembers the user was here — presence, not merit. This is
  /// the thread that lets it feel missed and rejoice on return.
  void _stampVisit() {
    try {
      ref.read(vineLifeWriterProvider).touchLastVisit();
    } catch (_) {}
  }

  /// After an absence, the garden rejoices on return: the vine drinks deep of
  /// the user's presence and then settles back into its quiet vigil.
  void _checkAbsence() {
    ref.read(vineLifeProvider.future).then((state) {
      if (!mounted || state.daysMissed <= 0) return;
      final token = DateTime.now().microsecondsSinceEpoch;
      _revivalToken = token;
      setState(() => _revived = true);
      Future.delayed(const Duration(milliseconds: 4200), () {
        if (!mounted || _revivalToken != token) return;
        setState(() => _revived = false);
      });
    }).catchError((_) {});
  }

  /// Plays a transcendence moment just after the frame (so the scene can
  /// listen) and counts it in the garden's memory.
  void _scheduleMoment(SceneMomentKind kind) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _moment.play(kind);
      try {
        ref.read(vineLifeWriterProvider).recordMoment();
      } catch (_) {}
    });
  }

  /// The first morning visit of the day is greeted with a dawn of grace — but
  /// only once, gently, so it never becomes routine noise.
  Future<void> _maybeDawnGrace() async {
    final hour = DateTime.now().hour;
    if (hour < 5 || hour >= 9) return;
    final d = DateTime.now();
    final today =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('vineMomentDawn') == today) return;
      await prefs.setString('vineMomentDawn', today);
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;
        _scheduleMoment(SceneMomentKind.dawnGrace);
      });
    } catch (_) {}
  }

  /// When the Word's light climbs high, the lamp flares once in thanks.
  void _maybeLampFlare(double light) {
    if (light > 0.75 && !_lampFlared) {
      _lampFlared = true;
      _scheduleMoment(SceneMomentKind.lampFlare);
    } else if (light <= 0.75) {
      _lampFlared = false;
    }
  }

  /// When the movement of the journey turns, the garden remembers the season.
  void _maybeSeasonTurn(JourneyMovement movement) {
    if (_lastMovement == null) {
      _lastMovement = movement;
      return;
    }
    if (_lastMovement != movement) {
      _lastMovement = movement;
      _scheduleMoment(SceneMomentKind.seasonTurn);
    }
  }

  @override
  void dispose() {
    _recapToken = null;
    _revivalToken = null;
    _moment.dispose();
    super.dispose();
  }

  /// If disciplines were logged on other screens since the last visit, replay
  /// them as a short recap so the vine is honest about the day. A discipline is
  /// never silent.
  void _scheduleRecap() {
    final bus = ref.read(sceneEventBusProvider);
    final pending = bus.pendingRecap();
    if (pending.isEmpty) return;
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced) {
      bus.markRecapped();
      return;
    }
    final token = DateTime.now().microsecondsSinceEpoch;
    _recapToken = token;
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || _recapToken != token) return;
      for (var i = 0; i < pending.length; i++) {
        Future.delayed(Duration(milliseconds: i * 420), () {
          if (!mounted || _recapToken != token) return;
          bus.value = pending[i];
        });
      }
      Future.delayed(Duration(milliseconds: pending.length * 420 + 900), () {
        if (!mounted || _recapToken != token) return;
        bus.markRecapped();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final isAm = l.localeName == 'am';

    final journey = widget.journey;
    final day = ref.watch(journeyDayProvider);
    final intention = ref.watch(activeIntentionProvider) ?? JourneyIntention.abide;
    final timeframeDays = ref.watch(activeTimeframeDaysProvider);
    final movement = ref.watch(activeMovementProvider) ?? JourneyMovement.planting;
    final mood = ref.watch(todaySoulLogProvider).valueOrNull?.mood;

    final geometry = GrowthContent.vineGeometry(day, timeframeDays);
    final stage = GrowthContent.vineStageFor(day, timeframeDays);
    final intentionLabel = GrowthContent.intentionLabel(intention);
    final movementTitle = GrowthContent.movementTitle(movement);

    final vitality = ref.watch(growthVitalityProvider);
    final eventSource = ref.watch(sceneEventBusProvider);
    final rhythm = ref.watch(todayRhythmProvider);
    final streak = ref.watch(streakStateProvider).valueOrNull;
    final week = ref.watch(weekLivingProvider).valueOrNull ?? const <int>[];
    final tourSeen = ref.watch(growthTourProvider);
    final showTour = tourSeen.valueOrNull == false;
    final vineState = ref.watch(vineLifeProvider).valueOrNull;

    _maybeLampFlare(vineState?.light ?? 0);
    _maybeSeasonTurn(movement);

    final seed = journey.id.hashCode;
    final fruitColor = Color.lerp(const Color(0xFF7FB36A), const Color(0xFFE8C53A), geometry.growth01)!;

    final history = ref.watch(journalHistoryProvider).valueOrNull ?? <JournalEntryData>[];
    final fruits = history
        .where((e) => e.date.compareTo(journey.startDate) >= 0 && e.content?.trim().isNotEmpty == true)
        .toList();

    return Stack(
      children: [
        ListView(
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
              height: 440,
              child: VineyardScene(
                seed: seed,
                growth01: geometry.growth01,
                branches: geometry.branches,
                fruitCount: _fruitCountFor(day, geometry.growth01),
                fruitColor: fruitColor,
                mood: mood,
                showBlossoms: stage == VineStage.blooming,
                hydration: vitality.hydration01,
                leafGlow: vitality.leafGlow01,
                branchOpen: vitality.branchOpen01,
                ripen: vitality.ripen01,
                eventSource: eventSource,
                revival: _revived,
                momentController: _moment,
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
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isAm ? movementTitle.am : movementTitle.en,
                    style: t.bodyMedium.copyWith(color: AppColors.of(context).primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  StagePath(stage: stage),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const _TodayFlowCard(),
            const SizedBox(height: AppSpacing.sm),
            DisclosureTile(
              icon: Icons.auto_awesome,
              title: l.todayRhythm,
              initiallyOpen: showTour,
              trailing: Text(
                '${rhythm.done}/${rhythm.total}',
                style: t.labelLarge.copyWith(color: AppColors.of(context).primary),
              ),
              children: const [RhythmRing()],
            ),
            const SizedBox(height: AppSpacing.sm),
            DisclosureTile(
              icon: Icons.calendar_view_week_outlined,
              title: l.thisWeek,
              initiallyOpen: showTour,
              trailing: Text(
                '${week.isEmpty ? 0 : week.last}',
                style: t.labelLarge.copyWith(color: AppColors.of(context).primary),
              ),
              children: const [WeekBars()],
            ),
            const SizedBox(height: AppSpacing.sm),
            DisclosureTile(
              icon: Icons.local_fire_department,
              title: l.abiding,
              initiallyOpen: showTour,
              trailing: Text(
                '${streak?.currentStreak ?? 0}',
                style: t.labelLarge.copyWith(color: AppColors.of(context).primary),
              ),
              children: const [StreakFlame()],
            ),
            const SizedBox(height: AppSpacing.md),
            QuestionCard(
              question: GrowthContent.questionFor(intention, day).en,
              questionAm: GrowthContent.questionFor(intention, day).am,
              isAm: isAm,
            ),
            const SizedBox(height: AppSpacing.sm),
            WeatherCard(mood: mood, isAm: isAm),
            const SizedBox(height: AppSpacing.sm),
            DayWordChip(verse: ScriptureService.threadVerseFor(DateTime.now()), isAm: isAm),
            const SizedBox(height: AppSpacing.sm),
            FruitDrawer(
              startDate: journey.startDate,
              isAm: isAm,
              fruitCount: fruits.length,
              onHarvest: () => _openHarvestSheet(context, ref, fruits),
            ),
          ],
        ),
        if (showTour)
          _TourPill(
            messages: [l.tourVine, l.tourGrows, l.tourMood],
            onDone: () => ref.read(growthTourProvider.notifier).markSeen(),
          ),
        if (_revived)
          _WelcomeBackPill(
            message: l.gardenWelcomeBack,
          ),
      ],
    );
  }
}

/// Today's guided flow as three pillar checkmarks — Bible, Prayer, Act — the
/// same journey the Home card walks. A faithful day is all three; grace means
/// even one counts.
class _TodayFlowCard extends ConsumerWidget {
  const _TodayFlowCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final isAm = l.localeName == 'am';
    final flow = ref.watch(dailyFlowProvider);
    final pillars = <(bool, String, String)>[
      (flow.bibleDone, '📖', isAm ? 'መጽሐፍ ቅዱስ' : 'Bible'),
      (flow.prayerDone, '🙏', isAm ? 'ጸሎት' : 'Prayer'),
      (flow.actionDone, '🌱', isAm ? 'ተግባር' : 'Act'),
    ];

    return BesletCard(
      variant: CardVariant.secondary,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.flag_outlined, size: 18, color: c.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(l.todaysFlow, style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700))),
          Text('${flow.done}/${flow.total}', style: t.labelLarge.copyWith(color: c.primary)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: flow.total == 0 ? 0 : flow.done / flow.total,
            minHeight: 6,
            backgroundColor: c.border,
            valueColor: AlwaysStoppedAnimation(c.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          for (final pillar in pillars)
            Expanded(
              child: Column(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pillar.$1 ? c.primary.withValues(alpha: 0.15) : c.border.withValues(alpha: 0.4),
                    border: Border.all(color: pillar.$1 ? c.primary : AppColors.borderLight, width: 2),
                  ),
                  child: Center(
                    child: pillar.$1
                        ? const Icon(Icons.check, size: 20, color: AppColors.primary)
                        : Text(pillar.$2, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pillar.$3,
                  style: t.bodySmall.copyWith(fontSize: 10, color: pillar.$1 ? c.primary : c.textMuted),
                ),
              ]),
            ),
        ]),
      ]),
    );
  }
}

/// A quiet word on returning after absence: the garden kept a vigil and is
/// glad to see the user again. Never a guilt trip — just warmth.
class _WelcomeBackPill extends StatelessWidget {
  final String message;

  const _WelcomeBackPill({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      top: AppSpacing.md,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
          decoration: BoxDecoration(
            color: c.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.primary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              const Icon(Icons.wb_twilight, size: 18, color: Color(0xFFE8C53A)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: t.bodySmall.copyWith(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A gentle three-beat hint shown only on the first visit: the vine, how it
/// grows, and where the day's question lives. Taps advance it; it never blocks.
class _TourPill extends StatefulWidget {
  final List<String> messages;
  final VoidCallback onDone;

  const _TourPill({required this.messages, required this.onDone});

  @override
  State<_TourPill> createState() => _TourPillState();
}

class _TourPillState extends State<_TourPill> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      if (_index < widget.messages.length - 1) {
        setState(() => _index++);
        _restartTimer();
      } else {
        _finish();
      }
    });
  }

  void _next() {
    if (_index < widget.messages.length - 1) {
      setState(() => _index++);
      _restartTimer();
    } else {
      _finish();
    }
  }

  void _finish() {
    _timer?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: AppSpacing.md,
      child: SafeArea(
        top: false,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _next,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.primary.withValues(alpha: 0.35)),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Row(
                  key: ValueKey(_index),
                  children: [
                    Expanded(
                      child: Text(
                        widget.messages[_index],
                        style: t.bodyMedium.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: c.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    try { await VineyardReminderService.refresh(); } catch (_) {}
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
