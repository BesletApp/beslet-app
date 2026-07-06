import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../core/providers/todo_provider.dart';
import '../../services/update_checker.dart';
import '../../shared/widgets/error_card.dart';

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
  bool _showCommunity = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCommunityPrompt());
  }

  Future<void> _checkCommunityPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final prompted = prefs.getBool('communityPrompted') ?? false;
    if (mounted && !prompted) {
      setState(() => _showCommunity = true);
    }
  }

  Future<void> _dismissCommunity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('communityPrompted', true);
    if (mounted) setState(() => _showCommunity = false);
  }

  Future<void> _openTelegram() async {
    await _dismissCommunity();
    await launchUrl(
      Uri.parse('https://t.me/besletcommunity'),
      mode: LaunchMode.externalApplication,
    );
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
      ref.refresh(todayTodoStatsProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final trackingAsync = ref.watch(trackingDataProvider);
    final todayPrayer = ref.watch(todayPrayerLogProvider);
    final todayBibleRead = ref.watch(todayBibleReadProvider);
    final todayFellowship = ref.watch(todayFellowshipProvider);
    final todayTodoStats = ref.watch(todayTodoStatsProvider);

    final l = AppLocalizations.of(context)!;
    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorCard(message: 'Could not load your data', onRetry: _onRefresh)),
      data: (user) {
        final tracking = trackingAsync.valueOrNull;
        final prayed = todayPrayer.valueOrNull != null;
        final bibleRead = todayBibleRead.valueOrNull != null;
        final skillsMin = tracking?.skillsMinutes ?? 0;
        final inSummer = SummerService.isInSummer;
        final daysElapsed = SummerService.daysElapsed;
        final daysRemaining = SummerService.daysRemaining;
        final totalDays = SummerService.totalSummerDays;
        final connectedToday = todayFellowship.valueOrNull != null;
        final todoStats = todayTodoStats.valueOrNull ?? TodoStats(total: 0, completed: 0);

        if (!_widgetUpdated) {
          _widgetUpdated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
            final planDay = (DateTime.now().difference(createdAt).inDays % 90) + 1;
            await WidgetService.updateWidgetData(planDay: planDay);
          });
        }

        final tempPillars = _computePillars(prayed, bibleRead, skillsMin, connectedToday, todoStats, l);
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

        final todayXp = (bibleRead ? 20 : 0) + (prayed ? 15 : 0) + (todoStats.completed * 5) + (skillsMin > 0 ? 10 : 0) + (connectedToday ? 5 : 0);

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(children: [
                  _buildCompactHeader(context, user, daysElapsed, totalDays, daysRemaining, inSummer, l),
                  const SizedBox(height: 20),
                  _buildVerseHero(context),
                  const SizedBox(height: 20),
                  _buildLitPath(context, bibleRead, prayed, todoStats, todayXp, tracking, daysElapsed, totalDays, l),
                  if (_showCommunity) ...[
                    const SizedBox(height: 16),
                    _buildCommunityBanner(context),
                  ],
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_PillarData> _computePillars(bool prayed, bool bibleRead, int skillsMin, bool connectedToday, TodoStats todoStats, AppLocalizations l) {
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
        icon: '✅', name: 'Tasks',
        statusText: todoStats.total > 0 ? '${todoStats.completed}/${todoStats.total} done' : 'Plan today →',
        isComplete: todoStats.total > 0 && todoStats.completed >= todoStats.total,
        progress: todoStats.total > 0 ? todoStats.completed / todoStats.total : 0.0,
        route: '/daily-todo',
      ),
    ];
  }

  Widget _buildCommunityBanner(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.primary.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('💬', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.community, style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                'Share your summer experience, day-to-day lifestyle, and encourage one another in our Telegram community.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11, height: 1.4),
              ),
            ]),
          ),
          GestureDetector(
            onTap: _dismissCommunity,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.close, size: 18, color: AppColors.textMuted),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _openTelegram,
            icon: const Icon(Icons.send, size: 16),
            label: Text('Join ብስለት on Telegram', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF0A0A0A),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
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

  Widget _buildCompactHeader(BuildContext context, User user, int daysElapsed, int totalDays, int daysRemaining, bool inSummer, AppLocalizations l) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (inSummer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Text('Day $daysElapsed of $totalDays · $daysRemaining left',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontSize: 11)),
          )
        else
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
        const Spacer(),
        Text('$greeting, ${user.name.split(' ').first}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ]),
    ]);
  }

  Widget _buildLitPath(BuildContext context, bool bibleRead, bool prayed, TodoStats todoStats, int todayXp, TrackingData? tracking, int daysElapsed, int totalDays, AppLocalizations l) {
    final tasksDone = todoStats.total > 0 && todoStats.completed >= todoStats.total;
    final step1done = bibleRead;
    final step2done = bibleRead && prayed;
    final step3done = bibleRead && prayed && tasksDone;
    final currentStep = step1done ? (step2done ? (step3done ? 3 : 2) : 1) : 0;

    final phaseIdx = ScriptureService.getPhase(daysElapsed);
    final phaseColors = [const Color(0xFF4CAF50), const Color(0xFF2196F3), const Color(0xFFFF6F00), const Color(0xFF9C27B0)];
    final phaseNames = ['Discipline', 'Faith', 'Obedience', 'Impact'];
    final phaseColor = phaseColors[phaseIdx];
    final phaseName = phaseNames[phaseIdx];

    final streak = tracking?.streak ?? 0;

    return Column(children: [
      _buildLitStep(
        step: 1,
        icon: '📖',
        label: 'Read the Word',
        purpose: 'Hear His voice',
        isComplete: step1done,
        isLocked: false,
        isCurrent: currentStep == 0,
        accent: AppColors.spiritualPurple,
        actionLabel: step1done ? null : 'Start Reading →',
        onAction: step1done ? null : () => context.go('/bible'),
        onView: step1done ? () => context.go('/bible') : null,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 20,
          child: Center(
            child: Container(
              width: 1,
              height: 16,
              decoration: BoxDecoration(
                color: step1done ? AppColors.progressGreen : AppColors.border,
              ),
            ),
          ),
        ),
      ),
      _buildLitStep(
        step: 2,
        icon: '🙏',
        label: 'Prayer',
        purpose: 'Pour out your heart',
        isComplete: step2done,
        isLocked: !step1done,
        isCurrent: currentStep == 1,
        accent: AppColors.spiritualPurple,
        actionLabel: step2done ? null : (step1done ? 'Start Prayer →' : null),
        onAction: step1done && !step2done ? () => context.go('/prayer') : null,
        onView: step2done ? () => context.go('/prayer') : null,
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SizedBox(
          height: 20,
          child: Center(
            child: Container(
              width: 1,
              height: 16,
              decoration: BoxDecoration(
                color: step2done ? AppColors.progressGreen : AppColors.border,
              ),
            ),
          ),
        ),
      ),
      _buildLitStep(
        step: 3,
        icon: '✅',
        label: "Today's Tasks",
        purpose: 'Walk in obedience',
        isComplete: step3done,
        isLocked: !step2done,
        isCurrent: currentStep == 2,
        accent: AppColors.progressGreen,
        actionLabel: step3done ? null : (step2done ? (todoStats.total == 0 ? 'Plan →' : 'Do →') : null),
        onAction: step2done && !step3done ? () => context.go('/daily-todo') : null,
        onView: step3done ? () => context.go('/daily-todo') : null,
      ),
      const SizedBox(height: 16),
      _buildRitualFooter(streak, todayXp, phaseName, phaseColor, daysElapsed, totalDays, l),
    ]);
  }

  Widget _buildLitStep({
    required int step,
    required String icon,
    required String label,
    required String purpose,
    required bool isComplete,
    required bool isLocked,
    required bool isCurrent,
    required Color accent,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onView,
  }) {
    final opacity = isLocked ? 0.35 : (isComplete ? 0.7 : 1.0);
    final bgColor = isCurrent ? AppColors.cardElevated : AppColors.card;
    final borderColor = isCurrent ? accent.withValues(alpha: 0.4) : (isComplete ? accent.withValues(alpha: 0.2) : AppColors.border);
    final borderWidth = isCurrent ? 1.0 : 0.5;

    return GestureDetector(
      onTap: isComplete ? onView : (isLocked ? null : onAction),
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: isCurrent
                ? [BoxShadow(color: accent.withValues(alpha: 0.08), blurRadius: 12, spreadRadius: 1)]
                : null,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: AppTextStyles.labelLarge.copyWith(fontSize: 14, color: isComplete ? accent : AppColors.textPrimary)),
                  Text(purpose, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted, fontStyle: FontStyle.italic)),
                ]),
              ),
              if (isComplete)
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.15)),
                  child: Icon(Icons.check, size: 14, color: accent),
                )
              else if (isLocked)
                Icon(Icons.lock_outline, size: 16, color: AppColors.textMuted),
            ]),
            if (actionLabel != null && !isLocked) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: Icon(Icons.arrow_forward, size: 16),
                  label: Text(actionLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: const Color(0xFF07090E),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildRitualFooter(int streak, int todayXp, String phaseName, Color phaseColor, int daysElapsed, int totalDays, AppLocalizations l) {
    final progress = totalDays > 0 ? daysElapsed / totalDays : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(children: [
        Row(children: [
          Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('$streak-day', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.textPrimary)),
          ]),
          const SizedBox(width: 16),
          Container(width: 1, height: 12, color: AppColors.border),
          const SizedBox(width: 16),
          Row(children: [
            Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
            const SizedBox(width: 4),
            Text('+$todayXp XP', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.primary)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: phaseColor)),
              const SizedBox(width: 4),
              Text(phaseName, style: AppTextStyles.bodySmall.copyWith(fontSize: 9, color: phaseColor, fontWeight: FontWeight.w700)),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(phaseColor),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Day $daysElapsed of $totalDays', style: AppTextStyles.bodySmall.copyWith(fontSize: 9, color: AppColors.textMuted)),
        ]),
      ]),
    );
  }

  Widget _buildVerseHero(BuildContext context) {
    final scripture = ScriptureService.getDailyScripture();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('✨', style: TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text('Verse of the Day',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontSize: 9, letterSpacing: 1.2)),
          ]),
        ),
        const SizedBox(height: 20),
        Text('"${scripture.text}"',
            style: AppTextStyles.bodyLarge.copyWith(fontStyle: FontStyle.italic, height: 1.7, fontSize: 17),
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(scripture.reference, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        if (scripture.textAm != null) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 2)),
            ),
            child: Text(scripture.textAm!,
                style: AppTextStyles.amharicBody.copyWith(fontSize: 13, height: 1.6, color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/bible'),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text('Listen', style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.audioBlue,
                side: BorderSide(color: AppColors.audioBlue.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.go('/bible'),
              icon: const Icon(Icons.menu_book, size: 16),
              label: Text('Read', style: const TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF07090E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}
