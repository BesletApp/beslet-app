import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/tracking_provider.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/providers/bible_read_provider.dart';
import '../../core/providers/fellowship_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../experience/verse_hero_card.dart';

class _PillarData {
  final String icon;
  final String name;
  final String statusText;
  final bool isComplete;
  final double progress;
  final String? route;

  const _PillarData({
    required this.icon,
    required this.name,
    required this.statusText,
    required this.isComplete,
    required this.progress,
    this.route,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _celebrated = false;

  Future<void> _onRefresh() async {
    await Future.wait([
      ref.refresh(userProvider.future),
      ref.refresh(trackingDataProvider.future),
      ref.refresh(todayPrayerLogProvider.future),
      ref.refresh(todayBibleReadProvider.future),
      ref.refresh(todayFellowshipProvider.future),
      ref.refresh(weeklyFamilyHoursProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final trackingAsync = ref.watch(trackingDataProvider);
    final todayPrayer = ref.watch(todayPrayerLogProvider);
    final todayBibleRead = ref.watch(todayBibleReadProvider);
    final todayFellowship = ref.watch(todayFellowshipProvider);
    final weeklyFamilyHours = ref.watch(weeklyFamilyHoursProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        final tracking = trackingAsync.valueOrNull;
        final prayed = todayPrayer.valueOrNull != null;
        final bibleRead = todayBibleRead.valueOrNull != null;
        final skillsMin = tracking?.skillsMinutes ?? 0;
        final connectedToday = todayFellowship.valueOrNull != null;
        final familyHoursToday = weeklyFamilyHours.valueOrNull ?? 0.0;

        final tempPillars = _computePillars(prayed, bibleRead, skillsMin, connectedToday, familyHoursToday);
        final allComplete = tempPillars.every((p) => p.isComplete);

        if (allComplete && !_celebrated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showCelebration(user.name);
              setState(() => _celebrated = true);
            }
          });
        } else if (!allComplete) {
          _celebrated = false;
        }

        return Scaffold(
          body: Stack(children: [
            Positioned(top: -80, right: -60,
              child: Container(width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: 0.08), Colors.transparent]),
                ),
              ),
            ),
            Positioned(top: 120, left: -80,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: 0.05), Colors.transparent]),
                ),
              ),
            ),
            SafeArea(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(children: [
                    _buildHero(context, user, trackingAsync),
                    const SizedBox(height: 24),
                    _buildPillarGrid(context, tempPillars),
                    const SizedBox(height: 20),
                    const VerseHeroCard(),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  List<_PillarData> _computePillars(bool prayed, bool bibleRead, int skillsMin, bool connectedToday, double familyHoursToday) {
    return [
      _PillarData(
        icon: '🙏', name: 'Spiritual',
        statusText: prayed && bibleRead ? 'Prayer ✓ · Bible ✓'
            : prayed ? 'Prayer ✓ · Bible pending'
            : bibleRead ? 'Bible ✓ · Prayer pending' : 'Prayer & Bible',
        isComplete: prayed && bibleRead,
        progress: (prayed ? 0.5 : 0.0) + (bibleRead ? 0.5 : 0.0),
        route: '/prayer',
      ),
      _PillarData(
        icon: '🎯', name: 'Skills',
        statusText: skillsMin > 0 ? '${skillsMin}m today' : 'Tap to start',
        isComplete: skillsMin > 0,
        progress: skillsMin > 0 ? 1.0 : 0.0,
        route: '/skills',
      ),
      _PillarData(
        icon: '👥', name: 'Fellowship',
        statusText: connectedToday ? 'Connected ✓' : 'Reach out today',
        isComplete: connectedToday,
        progress: connectedToday ? 1.0 : 0.0,
        route: '/fellowship',
      ),
      _PillarData(
        icon: '👨‍👩‍👧‍👧', name: 'Family',
        statusText: familyHoursToday > 0 ? '${familyHoursToday.toStringAsFixed(1)}h today' : 'Log time',
        isComplete: familyHoursToday > 0,
        progress: familyHoursToday > 0 ? (familyHoursToday / 2.0).clamp(0.0, 1.0) : 0.0,
        route: '/family',
      ),
    ];
  }

  void _showCelebration(String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('🎉 ', style: TextStyle(fontSize: 18)),
        Expanded(child: Text('All done, $name! You\'re growing today.', style: AppTextStyles.bodyMedium)),
      ]),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }

  Widget _buildHero(BuildContext context, User user, AsyncValue<TrackingData> tracking) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting,', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            Text(user.name, style: AppTextStyles.displaySmall),
          ]),
        ),
        tracking.when(
          data: (data) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Text(data.levelName,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 11)),
          ),
          loading: () => const SizedBox(width: 80),
          error: (_, __) => const SizedBox(width: 80),
        ),
      ]),
      const SizedBox(height: 20),
      tracking.when(
        data: (data) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(children: [
            const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${data.bibleDays} days in the Word this week',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ]),
        ),
        loading: () => const SizedBox(height: 48),
        error: (_, __) => const SizedBox(height: 48),
      ),
    ]);
  }

  Widget _buildPillarGrid(BuildContext context, List<_PillarData> pillars) {
    final firstIncompleteIdx = pillars.indexWhere((p) => !p.isComplete);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text("Today's Growth",
          style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary, fontSize: 12)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _buildPillarCard(context, pillars[0], firstIncompleteIdx == 0)),
        const SizedBox(width: 10),
        Expanded(child: _buildPillarCard(context, pillars[1], firstIncompleteIdx == 1)),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _buildPillarCard(context, pillars[2], firstIncompleteIdx == 2)),
        const SizedBox(width: 10),
        Expanded(child: _buildPillarCard(context, pillars[3], firstIncompleteIdx == 3)),
      ]),
    ]);
  }

  Widget _buildPillarCard(BuildContext context, _PillarData pillar, bool isHighlighted) {
    return GestureDetector(
      onTap: () {
        if (pillar.route != null) {
          context.go(pillar.route!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('${pillar.name} tracking coming soon!', style: AppTextStyles.bodyMedium),
            backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
          ));
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted ? AppColors.primary : AppColors.border,
            width: isHighlighted ? 1.5 : 0.5,
          ),
          boxShadow: isHighlighted
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 1)]
              : null,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(pillar.icon, style: const TextStyle(fontSize: 20)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pillar.isComplete ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                border: Border.all(
                  color: pillar.isComplete
                      ? AppColors.primary
                      : (isHighlighted ? AppColors.primary.withValues(alpha: 0.5) : AppColors.textMuted),
                  width: 1.5,
                ),
              ),
              child: pillar.isComplete
                  ? const Icon(Icons.check, size: 12, color: AppColors.primary)
                  : null,
            ),
          ]),
          const SizedBox(height: 8),
          Text(pillar.name, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
          const SizedBox(height: 2),
          Text(pillar.statusText,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: pillar.progress,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(isHighlighted ? AppColors.primary : AppColors.textMuted),
              minHeight: 2,
            ),
          ),
        ]),
      ),
    );
  }

}
