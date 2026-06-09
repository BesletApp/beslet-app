import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/services/summer_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/tracking_provider.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/providers/bible_read_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/fellowship_provider.dart';
import '../../core/providers/family_provider.dart';
import '../../services/update_checker.dart';

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
  bool _widgetUpdated = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2));
    final update = await UpdateChecker.checkForUpdate();
    if (update != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'New update available',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'Version ${update.latestVersion} is ready\n\n${update.releaseNotes}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                'Later',
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await launchUrl(
                  Uri.parse(update.downloadUrl),
                  mode: LaunchMode.externalApplication,
                );
              },
              child: const Text('Download Update'),
            ),
          ],
        ),
      );
    }
  }

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

    final l = AppLocalizations.of(context)!;
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

        if (!_widgetUpdated) {
          _widgetUpdated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
            final planDay = (DateTime.now().difference(createdAt).inDays % 90) + 1;
            await WidgetService.updateWidgetData(planDay: planDay);
          });
        }

        final tempPillars = _computePillars(prayed, bibleRead, skillsMin, connectedToday, familyHoursToday, l);
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
                  gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: 0.12), Colors.transparent]),
                ),
              ),
            ),
            Positioned(top: 120, left: -80,
              child: Container(width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.primary.withValues(alpha: 0.08), Colors.transparent]),
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
                    _buildVerseCard(context),
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

  List<_PillarData> _computePillars(bool prayed, bool bibleRead, int skillsMin, bool connectedToday, double familyHoursToday, AppLocalizations l) {
    return [
      _PillarData(
        icon: '🙏', name: l.spiritual,
        statusText: prayed && bibleRead ? l.pillarSpiritualComplete
            : prayed ? l.pillarPrayerDoneBiblePending
            : bibleRead ? l.pillarBibleDonePrayerPending : l.pillarSpiritualPending,
        isComplete: prayed && bibleRead,
        progress: (prayed ? 0.5 : 0.0) + (bibleRead ? 0.5 : 0.0),
        route: '/prayer',
      ),
      _PillarData(
        icon: '🎯', name: l.skills,
        statusText: skillsMin > 0 ? l.skillMinutesToday(skillsMin) : l.skillTapToStart,
        isComplete: skillsMin > 0,
        progress: skillsMin > 0 ? 1.0 : 0.0,
        route: '/skills',
      ),
      _PillarData(
        icon: '👥', name: l.fellowship,
        statusText: connectedToday ? l.fellowshipConnected : l.reachOut,
        isComplete: connectedToday,
        progress: connectedToday ? 1.0 : 0.0,
        route: '/fellowship',
      ),
      _PillarData(
        icon: '👨‍👩‍👧‍👧', name: l.familyTime,
        statusText: familyHoursToday > 0 ? l.familyHoursToday(familyHoursToday.toStringAsFixed(1)) : l.logTime,
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
    final inSummer = SummerService.isInSummer;
    final daysElapsed = SummerService.daysElapsed;
    final daysRemaining = SummerService.daysRemaining;
    final totalDays = SummerService.totalSummerDays;
    final progress = totalDays > 0 ? daysElapsed / totalDays : 0.0;

    if (!inSummer) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Text(SummerService.outsideMessage,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 11)),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$greeting,', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              Text(user.name, style: AppTextStyles.displaySmall),
              const SizedBox(height: 4),
              Text('Summer starts in ${SummerService.daysUntilNextSummer} days.',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
            ]),
          ),
          SizedBox(width: 64, height: 64,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(value: 0, strokeWidth: 4,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
              Icon(Icons.wb_sunny_outlined, size: 28, color: AppColors.primary.withValues(alpha: 0.6)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Text('🌱', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Get ready for summer!', style: AppTextStyles.labelLarge),
                Text('Build your spiritual habits before ${SummerService.nextSummerStart.month}/${SummerService.nextSummerStart.day}.',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        tracking.when(
          data: (data) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${data.streak}-day streak · Level ${data.level + 1}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(value: data.levelProgress,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary), minHeight: 3),
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                ),
                child: Text('${data.totalXp} XP',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 11)),
              ),
            ]),
          ),
          loading: () => const SizedBox(height: 48),
          error: (_, __) => const SizedBox(height: 48),
        ),
      ]);
    }

    final messages = [
      'Each day you choose well, you become who you\'re meant to be.',
      'Stay faithful, stay strong.',
      'Small steps lead to big changes.',
      'Your journey matters.',
      'Today is a gift. Seize it!',
      'Keep going, you\'re doing great!',
    ];
    final msg = messages[DateTime.now().day % messages.length];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Text('Day $daysElapsed of $totalDays · $daysRemaining left',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 11)),
      ),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$greeting,', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            Text(user.name, style: AppTextStyles.displaySmall),
            const SizedBox(height: 4),
            Text('Day $daysElapsed — $msg',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ]),
        ),
        const SizedBox(width: 16),
        SizedBox(width: 64, height: 64,
          child: Stack(alignment: Alignment.center, children: [
            CircularProgressIndicator(value: progress, strokeWidth: 4,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$daysElapsed', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontSize: 18)),
              Text('of $totalDays', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 9)),
            ]),
          ]),
        ),
      ]),
      const SizedBox(height: 16),
      tracking.when(
        data: (data) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${data.streak}-day streak · Level ${data.level + 1}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(value: data.levelProgress,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary), minHeight: 3),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Text('${data.totalXp} XP',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 11)),
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

  Widget _buildVerseCard(BuildContext context) {
    final scripture = ScriptureService.getDailyScripture();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 3, height: 14,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text('Verse of the Day',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontSize: 10, letterSpacing: 1.2)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/bible'),
            child: Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
          ),
        ]),
        const SizedBox(height: 12),
        Text('"${scripture.text}"',
            style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic, height: 1.6)),
        const SizedBox(height: 6),
        Text(scripture.reference, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        if (scripture.textAm != null) ...[
          const SizedBox(height: 10),
          Text(scripture.textAm!,
              style: AppTextStyles.amharicBody.copyWith(fontSize: 13, height: 1.6, color: AppColors.textSecondary)),
        ],
      ]),
    );
  }
}
