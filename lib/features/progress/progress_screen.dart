import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/tracking_provider.dart';
import '../../core/providers/analytics_provider.dart';
import 'widgets/stat_card.dart';
import 'widgets/streak_card.dart';
import 'widgets/chart_section.dart';
import 'widgets/achievement_card.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColors.backgroundLight;
    final primaryText =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final surface = isDark ? AppColors.surface : AppColors.backgroundLight;
    final card = isDark ? AppColors.card : AppColors.cardLight;
    final border =
        isDark ? AppColors.border : AppColors.borderLightTheme;

    final trackingAsync = ref.watch(trackingDataProvider);
    final completionsAsync = ref.watch(weeklyPillarCompletionsProvider);
    final sanctityAsync = ref.watch(sanctityScoreProvider);
    final weeklyXpAsync = ref.watch(weeklyXpProvider);
    final dailyXpAsync = ref.watch(dailyXpProvider);
    final bestStreakAsync = ref.watch(overallBestStreakProvider);

    return trackingAsync.when(
      loading: () => Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: bg,
        body: Center(child: Text('$e')),
      ),
      data: (tracking) {
        final completions =
            completionsAsync.valueOrNull ?? <String, List<bool>>{};
        final sanctityScore = sanctityAsync.valueOrNull ?? 0.0;
        final weeklyXp = weeklyXpAsync.valueOrNull ?? [0, 0, 0, 0];
        final dailyXp = dailyXpAsync.valueOrNull ?? List.filled(7, 0.0);
        final bestStreak = bestStreakAsync.valueOrNull ?? 0;

        final weekDays = List.generate(
            7,
            (i) => completions.values
                .any((pillar) => i < pillar.length && pillar[i]));

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildTopBar(context, isDark, primaryText, surface),
                const SizedBox(height: 20),
                _buildStatRow(
                    context, tracking, weeklyXp, isDark, card, border),
                const SizedBox(height: 12),
                StreakCard(
                  streak: tracking.streak,
                  bestStreak: bestStreak,
                  weekDays: weekDays,
                  sanctityScore: sanctityScore,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                ChartSection(
                  weeklyCompletions: completions,
                  weeklyXp: weeklyXp,
                  dailyXp: dailyXp,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                _buildAchievementsHeader(context, primaryText),
                const SizedBox(height: 10),
                _buildAchievementsGrid(context, tracking, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(
      BuildContext context, bool isDark, Color primaryText, Color surface) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.chevron_left,
                size: 20, color: primaryText),
          ),
        ),
        const Spacer(),
        Text('Progress',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: primaryText)),
        const Spacer(),
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, TrackingData tracking,
      List<double> weeklyXp, bool isDark, Color card, Color border) {
    final primaryText =
        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryText =
        isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final mutedText =
        isDark ? AppColors.textMuted : AppColors.textMutedLight;

    return Row(
      children: [
        Expanded(
          child: StatCard(
            backgroundColor: card,
            accentColor: AppColors.primary,
            icon: const Icon(Icons.emoji_events),
            iconBg: AppColors.primary.withValues(alpha: 0.15),
            iconColor: AppColors.primary,
            value: '${tracking.level}',
            valueColor: AppColors.primary,
            label: 'Level',
            labelColor: mutedText,
            subtitle: tracking.levelName,
            subtitleColor: secondaryText,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            backgroundColor: card,
            accentColor: AppColors.primary,
            icon: const Icon(Icons.bolt),
            iconBg: AppColors.primary.withValues(alpha: 0.15),
            iconColor: AppColors.primary,
            value: '${tracking.totalXp}',
            valueColor: primaryText,
            label: 'Total XP',
            labelColor: mutedText,
            subtitle:
                '+${weeklyXp.isNotEmpty ? weeklyXp[0].round() : 0} this week',
            subtitleColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsHeader(BuildContext context, Color primaryText) {
    return Text('Achievements',
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: primaryText));
  }

  Widget _buildAchievementsGrid(
      BuildContext context, TrackingData tracking, bool isDark) {
    final badges = tracking.badges;
    final earnedIds = badges.map((b) => b['id'] as String).toSet();

    const allAchievements = [
      ('first_step', 'First Step', '🌱', 'Complete your first habit'),
      ('week_streak', 'Faithful Week', '🔥', '7-day streak'),
      ('month_streak', '30-Day Streak', '👑', '30-day streak'),
      ('prayer_warrior', 'Prayer Warrior', '🙏', '100 prayer minutes'),
      ('bible_week', 'Scripture Scholar', '📖', '7 days of Bible'),
      ('mature', 'Maturity', '✨', 'Reach Mature level'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: allAchievements.map((a) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 42) / 2,
          child: AchievementCard(
            icon: a.$3,
            name: a.$2,
            subtitle: a.$4,
            unlocked: earnedIds.contains(a.$1),
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }
}
