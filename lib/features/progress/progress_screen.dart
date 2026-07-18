import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/tracking_provider.dart';
import '../../shared/widgets/error_card.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/reading_plan_provider.dart';
import '../../core/services/xp_service.dart';
import '../../core/services/summer_service.dart';
import '../../core/services/scripture_service.dart';
import '../../core/services/plan_progress_service.dart';
import '../../core/services/witness_service.dart';
import '../../core/database/app_database.dart';
import 'widgets/streak_card.dart';
import 'widgets/chart_section.dart';
import 'widgets/achievement_card.dart';
import 'widgets/book_progress_list.dart';

const _phaseNames = ['Discipline', 'Faith', 'Obedience', 'Impact'];

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.backgroundLight;
    final primaryText = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final surface = isDark ? AppColors.surface : AppColors.backgroundLight;
    final border = isDark ? AppColors.border : AppColors.borderLightTheme;
    final c = AppColors.of(context);

    final trackingAsync = ref.watch(trackingDataProvider);
    final completionsAsync = ref.watch(weeklyPillarCompletionsProvider);
    final sanctityAsync = ref.watch(sanctityScoreProvider);
    final weeklyXpAsync = ref.watch(weeklyXpProvider);
    final dailyXpAsync = ref.watch(dailyXpProvider);
    final bestStreakAsync = ref.watch(overallBestStreakProvider);
    final reflectionAsync = ref.watch(reflectionProvider);
    final readingProgressAsync = ref.watch(readingProgressProvider);
    final activeLoopAsync = ref.watch(activeLoopProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    return trackingAsync.when(
      loading: () => Scaffold(backgroundColor: bg, body: const Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(backgroundColor: bg, body: ErrorCard(message: 'Could not load stats')),
      data: (tracking) {
        final completions = completionsAsync.valueOrNull ?? <String, List<bool>>{};
        final sanctityScore = sanctityAsync.valueOrNull ?? 0.0;
        final weeklyXp = weeklyXpAsync.valueOrNull ?? [0.0, 0.0, 0.0, 0.0];
        final dailyXp = dailyXpAsync.valueOrNull ?? List.filled(7, 0.0);
        final bestStreak = bestStreakAsync.valueOrNull ?? 0;
        final reflection = reflectionAsync.valueOrNull;

        final weekDays = List.generate(7, (i) =>
            completions.values.any((pillar) => i < pillar.length && pillar[i]));

        final daysElapsed = SummerService.daysElapsed;
        final totalDays = SummerService.totalSummerDays;
        final phaseIdx = ScriptureService.getPhase(daysElapsed);

        final todayPillars = {
          'bible': completions['bible']?.isNotEmpty == true ? completions['bible']!.last : false,
          'prayer': completions['prayer']?.isNotEmpty == true ? completions['prayer']!.last : false,
          'fellowship': completions['fellowship']?.isNotEmpty == true ? completions['fellowship']!.last : false,
          'tasks': completions['tasks']?.isNotEmpty == true ? completions['tasks']!.last : false,
        };

        final dailyAvg = dailyXp.where((v) => v > 0).isEmpty
            ? 50.0 : (dailyXp.reduce((a, b) => a + b) / dailyXp.where((v) => v > 0).length) * 1.2;
        final weeklyAvg = weeklyXp.where((v) => v > 0).isEmpty
            ? 350.0 : (weeklyXp.reduce((a, b) => a + b) / weeklyXp.where((v) => v > 0).length) * 1.2;

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _buildHeader(tracking, primaryText, surface, c),
                const SizedBox(height: 20),
                _buildLevelHero(tracking, primaryText, surface, c),
                const SizedBox(height: 16),
                _buildPillarPulse(context, tracking, todayPillars, border),
                const SizedBox(height: 16),
                _buildPhaseJourney(daysElapsed, totalDays, phaseIdx, border, c),
                const SizedBox(height: 12),
                StreakCard(
                  streak: tracking.streak, bestStreak: bestStreak, weekDays: weekDays,
                  sanctityScore: sanctityScore, isDark: isDark,
                ),
                if (reflection == null) ...[
                  const SizedBox(height: 12),
                  _buildReflectionPrompt(context),
                ],
                const SizedBox(height: 12),
                _buildReadingPlanProgress(readingProgressAsync, activeLoopAsync, isDark, c),
                const SizedBox(height: 12),
                ChartSection(
                  weeklyCompletions: completions, weeklyXp: weeklyXp, dailyXp: dailyXp,
                  isDark: isDark, dailyGoal: dailyAvg, weeklyGoal: weeklyAvg,
                ),
                const SizedBox(height: 14),
                _buildAchievementsSection(tracking, screenWidth, isDark, c),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(TrackingData tracking, Color primaryText, Color surface, ThemePalette c) {
    return Row(
      children: [
        Text('Growth', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primaryText)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_fire_department, size: 16, color: AppColors.warning),
            const SizedBox(width: 4),
            Text('${tracking.streak}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryText)),
            const SizedBox(width: 4),
            Text('day', style: TextStyle(fontSize: 10, color: c.textMuted)),
          ]),
        ),
      ],
    );
  }

  Widget _buildLevelHero(TrackingData tracking, Color primaryText, Color surface, ThemePalette c) {
    final xpRemaining = XpService.xpToNextLevel(tracking.totalXp);
    final progress = tracking.levelProgress;
    final suggestion = XpService.nextActionSuggestion(tracking.totalXp);

    final levelIcons = [Icons.eco, Icons.spa, Icons.forest, Icons.park, Icons.star];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0.03)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(levelIcons[tracking.level.clamp(0, 4)], size: 22, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tracking.levelName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: primaryText)),
            Text('Level ${tracking.level}', style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${tracking.totalXp}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.primary, height: 1)),
            Text('XP total', style: TextStyle(fontSize: 10, color: c.textMuted)),
          ]),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: c.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${(progress * 100).round()}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('$xpRemaining XP to next level', style: TextStyle(fontSize: 10, color: c.textMuted)),
          const Spacer(),
          Text(suggestion, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ]),
      ]),
    );
  }

  Widget _buildPillarPulse(BuildContext context, TrackingData tracking, Map<String, bool> todayPillars, Color border) {
    final c = AppColors.of(context);
    final pillars = [
      _PillarData(Icons.menu_book, 'Bible', todayPillars['bible'] == true, AppColors.spiritualPurple, '/prayer'),
      _PillarData(Icons.water_drop, 'Pray', todayPillars['prayer'] == true, AppColors.spiritualPurple, '/prayer'),
      _PillarData(Icons.code, 'Skill', tracking.skillsMinutes > 0, AppColors.primary, '/skills'),
      _PillarData(Icons.people, 'Fellowship', todayPillars['fellowship'] == true, AppColors.primary, '/fellowship'),
      _PillarData(Icons.checklist, 'Tasks',
          tracking.todosTotal > 0 && tracking.todosDone >= tracking.todosTotal, AppColors.progressGreen, '/daily-todo'),
    ];

    final statusLabels = [
      todayPillars['bible'] == true ? '✓' : '✗',
      todayPillars['prayer'] == true ? '✓' : '✗',
      tracking.skillsMinutes > 0 ? '${tracking.skillsMinutes}m' : '✗',
      todayPillars['fellowship'] == true ? '✓' : '✗',
      tracking.todosTotal > 0 ? '${tracking.todosDone}/${tracking.todosTotal}' : '✗',
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Today's Rhythm", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted)),
      const SizedBox(height: 8),
      Row(children: List.generate(5, (i) {
        final p = pillars[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => context.go(p.route),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: p.isComplete ? p.color.withValues(alpha: 0.1) : c.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.isComplete ? p.color.withValues(alpha: 0.3) : border, width: 0.5),
              ),
              child: Column(children: [
                Icon(p.icon, size: 16, color: p.isComplete ? p.color : c.textMuted),
                const SizedBox(height: 4),
                Text(statusLabels[i],
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: p.isComplete ? p.color : c.textMuted)),
                Text(p.label, style: TextStyle(fontSize: 8, color: c.textSecondary)),
              ]),
            ),
          ),
        );
      })),
    ]);
  }

  Widget _buildPhaseJourney(int daysElapsed, int totalDays, int phaseIdx, Color border, ThemePalette c) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.timeline, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Summer Journey', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textSecondary)),
          const Spacer(),
          Text('Day $daysElapsed of $totalDays', style: TextStyle(fontSize: 10, color: c.textMuted)),
        ]),
        const SizedBox(height: 12),
        Row(children: List.generate(4, (i) {
          final isPast = i < phaseIdx;
          final isCurrent = i == phaseIdx;
          return Expanded(
            child: Column(children: [
              Row(children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= phaseIdx ? AppColors.primary : border,
                    ),
                  ),
                Container(
                  width: isCurrent ? 26 : 20, height: isCurrent ? 26 : 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast ? AppColors.primary : (isCurrent ? c.card : border.withValues(alpha: 0.3)),
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : (isPast ? AppColors.primary : border),
                      width: isCurrent ? 2.5 : 1.5,
                    ),
                  ),
                  child: isPast
                      ? const Icon(Icons.check, size: 12, color: Color(0xFF0A0A0A))
                      : (isCurrent ? const Icon(Icons.eco, size: 13, color: AppColors.primary) : null),
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < phaseIdx ? AppColors.primary : border,
                    ),
                  ),
              ]),
              const SizedBox(height: 6),
              Text(_phaseNames[i],
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600,
                      color: isCurrent ? AppColors.primary : c.textMuted)),
            ]),
          );
        })),
        const SizedBox(height: 8),
        Center(
          child: Text('Phase ${phaseIdx + 1}: ${_phaseNames[phaseIdx]}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ),
      ]),
    );
  }

  Widget _buildReflectionPrompt(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: () => context.go('/reflection'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.edit_note, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Reflection', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textPrimary)),
            Text('What grew? What slipped? Next focus?', style: TextStyle(fontSize: 10, color: c.textSecondary)),
          ])),
          Icon(Icons.chevron_right, size: 18, color: c.textMuted),
        ]),
      ),
    );
  }

  Widget _buildAchievementsSection(TrackingData tracking, double screenWidth, bool isDark, ThemePalette c) {
    const allAchievements = [
      ('first_step', 'First Step', Icons.flag, 'Complete your first habit'),
      ('week_streak', 'Faithful Week', Icons.local_fire_department, '7-day streak'),
      ('month_streak', '30-Day Streak', Icons.workspace_premium, '30-day streak'),
      ('prayer_warrior', 'Prayer Warrior', Icons.water_drop, '100 prayer minutes'),
      ('bible_week', 'Scripture Scholar', Icons.menu_book, '7 days of Bible'),
      ('hardcore', 'Hardcore', Icons.shield, 'All 5 pillars in a day'),
      ('mature', 'Maturity', Icons.emoji_events, 'Reach Mature level'),
    ];

    final earnedIds = tracking.badges.map((b) => b['id'] as String).toSet();
    final earned = allAchievements.where((a) => earnedIds.contains(a.$1)).length;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Milestones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const Spacer(),
        Text('$earned/${allAchievements.length} unlocked', style: TextStyle(fontSize: 11, color: c.textMuted)),
      ]),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10, runSpacing: 10,
        children: allAchievements.map((a) {
          return SizedBox(
            width: (screenWidth - 42) / 2,
            child: AchievementCard(
              icon: a.$3, name: a.$2, subtitle: a.$4,
              unlocked: earnedIds.contains(a.$1), isDark: isDark,
            ),
          );
        }).toList(),
      ),
    ]);
  }
  Widget _buildReadingPlanProgress(AsyncValue<PlanProgress> progressAsync, AsyncValue<ReadingLoop?> loopAsync, bool isDark, ThemePalette c) {
    return progressAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plan) {
        final loop = loopAsync.valueOrNull;
        final loopDay = loop != null
            ? DateTime.now().difference(DateTime.parse(loop.startDate)).inDays + 1
            : 0;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reading Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
            const SizedBox(height: 4),
            Text('${plan.totalChaptersRead} of ${plan.totalChaptersInBible} chapters · ${(plan.biblePercent * 100).toStringAsFixed(1)}% complete',
                style: TextStyle(fontSize: 12, color: c.textSecondary)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: plan.biblePercent,
                minHeight: 10,
                backgroundColor: c.border,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            ),
            if (loop != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.loop, size: 14, color: c.textMuted),
                const SizedBox(width: 4),
                Text('Loop ${loop.loopNumber}: Day $loopDay of ${loop.duration}',
                    style: TextStyle(fontSize: 11, color: c.textMuted)),
              ]),
            ],
            if (plan.currentBookName != null) ...[
              const SizedBox(height: 10),
              Text('Reading: ${plan.currentBookName} ${plan.currentBookChapter}',
                  style: TextStyle(fontSize: 12, color: c.textSecondary)),
            ],
            const SizedBox(height: 16),
            BookProgressList(progress: plan),
            _buildMilestoneMessage(plan, c),
          ]),
        );
      },
    );
  }

  Widget _buildMilestoneMessage(PlanProgress plan, ThemePalette c) {
    final completedBooks = plan.otProgress.where((p) => p.isComplete).length +
        plan.ntProgress.where((p) => p.isComplete).length;
    final msg = WitnessService.milestoneMessage(completedBooks, false);
    if (msg == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(children: [
          const Text('🌱', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 12, color: c.textSecondary, height: 1.4))),
        ]),
      ),
    );
  }
}

class _PillarData {
  final IconData icon;
  final String label;
  final bool isComplete;
  final Color color;
  final String route;
  const _PillarData(this.icon, this.label, this.isComplete, this.color, this.route);
}
