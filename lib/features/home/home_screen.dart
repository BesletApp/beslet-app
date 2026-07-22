import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_durations.dart';
import '../../core/personalization/tone_service.dart';
import '../../core/personalization/personalization_providers.dart';
import '../../core/emotional/experience_profile.dart';
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
import '../../core/providers/streak_provider.dart';
import '../../core/providers/reading_plan_provider.dart';
import '../../core/services/plan_progress_service.dart';
import '../../core/providers/soul_log_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/loop_service.dart';
import '../../services/update_checker.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/enkutatash_overlay.dart';


class _StepData {
  final String icon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String route;
  const _StepData({required this.icon, required this.title, required this.subtitle, required this.ctaLabel, required this.route});
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  bool _isAm = false;
  bool _celebrated = false;
  bool _widgetUpdated = false;

  late final AnimationController _staggerCtrl;
  late final List<Animation<double>> _staggerAnims;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;
  double _currentSpacingScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initStaggerAnimations(itemDuration: const Duration(milliseconds: 350));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _checkForUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCommunityPrompt());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnkutatash());
  }

  void _initStaggerAnimations({required Duration itemDuration, Curve? curve, int count = 5}) {
    final gap = const Duration(milliseconds: 80);
    final totalDuration = itemDuration + gap * (count - 1);
    _staggerCtrl = AnimationController(vsync: this, duration: totalDuration);
    _staggerAnims = List.generate(count, (i) {
      final start = (gap.inMilliseconds * i) / totalDuration.inMilliseconds;
      final end = (gap.inMilliseconds * i + itemDuration.inMilliseconds) / totalDuration.inMilliseconds;
      return CurvedAnimation(
        parent: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerCtrl,
            curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: curve ?? Curves.easeOut),
          ),
        ),
        curve: curve ?? Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _staggerCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  double _h(double token) => (token * _currentSpacingScale).roundToDouble();

  double _milestoneProgress(int streak) {
    if (streak >= 90) return ((streak - 90) / 275).clamp(0.0, 1.0);
    if (streak >= 30) return ((streak - 30) / 60).clamp(0.0, 1.0);
    if (streak >= 14) return ((streak - 14) / 16).clamp(0.0, 1.0);
    if (streak >= 7) return ((streak - 7) / 7).clamp(0.0, 1.0);
    return (streak / 7).clamp(0.0, 1.0);
  }

  Future<void> _checkCommunityPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final prompted = prefs.getBool('communityPrompted') ?? false;
    if (!mounted || prompted) return;
    await prefs.setBool('communityPrompted', true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: const Text('Join our community on Telegram'),
      action: SnackBarAction(label: 'Join', onPressed: _openTelegram),
      duration: AppDurations.verySlow,
    ));
  }

  Future<void> _openTelegram() async {
    await launchUrl(
      Uri.parse('https://t.me/besletcommunity'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _showLoopCompleteDialog(ReadingLoop loop) async {
    final completed = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text('Loop ${loop.loopNumber} Complete!', style: AppTextStyles.labelLarge),
        content: Text('You finished ${loop.duration} days of reading. Start a new loop?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, -1), child: const Text('Not now', style: TextStyle(fontFamily: 'Inter'))),
          TextButton(onPressed: () => Navigator.pop(ctx, 7), child: const Text('7 days', style: TextStyle(fontFamily: 'Inter'))),
          TextButton(onPressed: () => Navigator.pop(ctx, 30), child: const Text('30 days', style: TextStyle(fontFamily: 'Inter'))),
          TextButton(onPressed: () => Navigator.pop(ctx, 66), child: const Text('66 days', style: TextStyle(fontFamily: 'Inter'))),
          TextButton(onPressed: () => Navigator.pop(ctx, 90), child: const Text('90 days', style: TextStyle(fontFamily: 'Inter'))),
        ],
      ),
    );
    if (completed != null && completed > 0 && mounted) {
      final db = ref.read(databaseProvider);
      final user = await db.select(db.users).get().then((u) => u.first);
      await LoopService.createNextLoop(db, user.biblePlan, completed);
      ref.invalidate(activeLoopProvider);
      setState(() {});
    }
  }

  Future<void> _checkEnkutatash() async {
    final now = DateTime.now();
    if (now.month != 9 || now.day != 11) return;
    if (now.year != 2026) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('enkutatashShown') ?? false;
    if (!shown && mounted) {
      await prefs.setBool('enkutatashShown', true);
      if (!mounted) return;
      final nav = Navigator.of(context);
      nav.push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EnkutatashOverlay(onDismiss: () => nav.pop()),
      ));
    }
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(AppDurations.slow);
    final update = await UpdateChecker.checkForUpdate();
    if (update != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final cc = AppColors.of(ctx);
          return AlertDialog(
            backgroundColor: cc.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
            title: Text(
              _isAm ? 'አዲስ ማሻሻያ አለ' : 'New update available',
              style: TextStyle(color: cc.primary, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Version ${update.latestVersion} is ready\n\n${update.releaseNotes}',
              style: TextStyle(color: cc.textSecondary, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(_isAm ? 'በኋላ' : 'Later', style: TextStyle(color: cc.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: cc.primary,
                  foregroundColor: cc.isDark ? const Color(0xFF07090E) : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await launchUrl(
                    Uri.parse(update.downloadUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Text(_isAm ? 'አውርድ' : 'Download Update'),
              ),
            ],
          );
        },
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
    final readingProgressAsync = ref.watch(readingProgressProvider);
    final activeLoopAsync = ref.watch(activeLoopProvider);
    final tone = ref.watch(toneServiceProvider);
    final engine = ref.watch(personalizationEngineProvider);

    _isAm = Localizations.localeOf(context).languageCode == 'am';
    final streakState = ref.watch(streakStateProvider).valueOrNull;
    final todaySoulLog = ref.watch(todaySoulLogProvider).valueOrNull;
    final l = AppLocalizations.of(context)!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_staggerCtrl.isAnimating && !_staggerCtrl.isCompleted) {
        _staggerCtrl.forward();
      }
    });

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
        final progress = readingProgressAsync.valueOrNull;
        final loop = activeLoopAsync.valueOrNull;
        final streak = tracking?.streak ?? 0;

        if (!_widgetUpdated) {
          _widgetUpdated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
            final planDay = (DateTime.now().difference(createdAt).inDays % 90) + 1;
            await WidgetService.updateWidgetData(planDay: planDay);
          });
        }

        final tasksDone = todoStats.total > 0 && todoStats.completed >= todoStats.total;
        final step1done = bibleRead;
        final step2done = bibleRead && prayed;
        final step3done = bibleRead && prayed && tasksDone;
        final currentStep = step1done ? (step2done ? (step3done ? 3 : 2) : 1) : 0;

        final allComplete = bibleRead && prayed && skillsMin > 0 && connectedToday && todoStats.total > 0 && todoStats.completed >= todoStats.total;

        if (allComplete && !_celebrated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showCelebration(user.name, tone, l);
              setState(() => _celebrated = true);
            }
          });
        } else if (!allComplete) {
          _celebrated = false;
        }

        if (loop != null && loop.status == 'active') {
          final loopStart = DateTime.tryParse(loop.startDate);
          if (loopStart != null) {
            final loopDay = DateTime.now().difference(loopStart).inDays + 1;
            if (loopDay > loop.duration && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _showLoopCompleteDialog(loop));
            }
          }
        }

        final season = AppSeason.fromStreak(streak);
        final dayState = DayState.detect(
          isFirstSessionToday: engine.isFirstSessionToday,
          allStepsComplete: allComplete,
          missedYesterday: streakState?.isAtRisk ?? false,
          wasAwayForDays: engine.wasAwayForDays,
        );
        final profile = getProfile(season, dayState, AppColors.of(context));

        _currentSpacingScale = profile.spacingScale;

        if (_staggerCtrl.duration != profile.animationDuration) {
          _initStaggerAnimations(
            itemDuration: profile.animationDuration,
            curve: profile.animationCurve,
            count: 5,
          );
        }

        if (streakState?.isAtRisk == true && !_pulseCtrl.isAnimating) {
          _pulseCtrl.repeat(reverse: true);
        } else if (streakState?.isAtRisk != true && _pulseCtrl.isAnimating) {
          _pulseCtrl.stop();
          _pulseCtrl.value = 1.0;
        }

        final todayXp = (bibleRead ? 20 : 0) + (prayed ? 15 : 0) + (todoStats.completed * 5) + (skillsMin > 0 ? 10 : 0) + (connectedToday ? 5 : 0);
        final gap = _h(24.0);

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(left: 20, right: 20, top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStaggered(0, _buildGreetingBlock(profile, user, inSummer, daysElapsed, totalDays, daysRemaining, l, tone)),
                    SizedBox(height: gap),
                    if (profile.showStreakRing) ...[
                      _buildStaggered(1, _buildStreakRitual(profile, streak, streakState?.isAtRisk ?? false)),
                      SizedBox(height: gap),
                    ],
                    _buildStaggered(2, _buildPrimaryStepCard(
                      profile, currentStep, bibleRead, prayed, todoStats,
                      streakState?.isSabbathToday ?? false, allComplete, user.name, tone, l,
                    )),
                    SizedBox(height: gap),
                    _buildStaggered(3, _buildSecondaryActions(
                      profile, skillsMin, connectedToday, todayXp, progress, todaySoulLog, l,
                    )),
                    SizedBox(height: gap),
                    _buildStaggered(4, _buildVerseCard(profile)),
                    SizedBox(height: _h(AppSpacing.xl)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaggered(int index, Widget child) {
    if (index >= _staggerAnims.length) return child;
    return AnimatedBuilder(
      animation: _staggerAnims[index],
      builder: (context, child) => Opacity(
        opacity: _staggerAnims[index].value,
        child: Transform.translate(
          offset: Offset(0, (1.0 - _staggerAnims[index].value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }

  Widget _buildGreetingBlock(ExperienceProfile profile, User user, bool inSummer, int daysElapsed, int totalDays, int daysRemaining, AppLocalizations l, ToneService tone) {
    final hour = DateTime.now().hour;
    final greeting = tone.greeting(l, hour);
    final name = user.name.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (inSummer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.of(context).primary.withValues(alpha: 0.25)),
              ),
              child: Text('Day $daysElapsed of $totalDays · $daysRemaining left',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).primary, fontSize: 11)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.of(context).primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.of(context).primary.withValues(alpha: 0.25)),
              ),
              child: Text(SummerService.outsideMessage,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).primary, fontSize: 11)),
            ),
        ]),
        SizedBox(height: _h(12.0)),
        _buildGreetingText(profile, greeting, name, l),
      ],
    );
  }

  Widget _buildGreetingText(ExperienceProfile profile, String greeting, String name, AppLocalizations l) {
    String displayText;
    switch (profile.greetingStyle) {
      case 'full':
        displayText = '$greeting, $name.';
      case 'short':
        displayText = '$name. $greeting.';
      case 'minimal':
        displayText = greeting;
      case 'nameOnly':
        displayText = name;
      default:
        displayText = '$greeting, $name.';
    }
    return Text(
      displayText,
      style: AppTextStyles.of(context).displayMedium.copyWith(
        color: profile.colors.greeting,
        fontWeight: profile.visualWeight,
        height: 1.2,
      ),
    );
  }

  Widget _buildStreakRitual(ExperienceProfile profile, int streak, bool isAtRisk) {
    final progress = _milestoneProgress(streak);
    return Center(
      child: SizedBox(
        width: 64,
        height: 64,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, _) => CustomPaint(
            painter: _StreakRingPainter(
              progress: progress,
              color: profile.colors.streakRing,
              isAtRisk: isAtRisk,
              pulseOpacity: isAtRisk ? _pulseAnim.value : 1.0,
            ),
            child: Center(
              child: Text(
                '$streak',
                style: AppTextStyles.displaySmall.copyWith(
                  fontSize: 18,
                  color: profile.colors.streakRing,
                  fontWeight: profile.visualWeight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryStepCard(
    ExperienceProfile profile, int currentStep, bool bibleRead, bool prayed, TodoStats todoStats,
    bool isSabbath, bool allComplete, String userName, ToneService tone, AppLocalizations l,
  ) {
    if (isSabbath) {
      return _buildSabbathContent(profile, l);
    }
    if (allComplete) {
      return _buildCelebrationCard(profile, userName, tone, l);
    }
    if (currentStep >= 3) {
      return _buildRhythmCompleteCard(profile, l);
    }
    final stepData = _nextStepData(currentStep, todoStats, l);
    return _buildStepCard(profile, stepData);
  }

  _StepData _nextStepData(int currentStep, TodoStats todoStats, AppLocalizations l) {
    switch (currentStep) {
      case 0:
        return _StepData(
          icon: '📖',
          title: _isAm ? 'ቃሉን አንብብ' : 'Read the Word',
          subtitle: _isAm ? 'የእግዚአብሔርን ድምፅ ስማ' : 'Hear His voice',
          ctaLabel: _isAm ? 'ማንበብ ጀምር' : 'Start Reading',
          route: '/bible',
        );
      case 1:
        return _StepData(
          icon: '🙏',
          title: _isAm ? 'ጸሎት' : 'Prayer',
          subtitle: _isAm ? 'ልብህን አፍስስ' : 'Pour out your heart',
          ctaLabel: _isAm ? 'ጸልይ' : 'Begin Prayer',
          route: '/prayer',
        );
      case 2:
        return _StepData(
          icon: '✅',
          title: _isAm ? 'የዛሬ ተግባራት' : "Today's Tasks",
          subtitle: _isAm
              ? (todoStats.total == 0 ? 'እቅድ አውጣ' : 'በታዛዥነት ሂድ')
              : (todoStats.total == 0 ? 'Set your intention' : 'Walk in obedience'),
          ctaLabel: _isAm
              ? (todoStats.total == 0 ? 'እቅድ ፍጠር' : 'አድርግ')
              : (todoStats.total == 0 ? 'Shape your day' : 'Do'),
          route: '/daily-todo',
        );
      default:
        return _StepData(
          icon: '📖',
          title: 'Read the Word',
          subtitle: 'Hear His voice',
          ctaLabel: 'Start Reading',
          route: '/bible',
        );
    }
  }

  Widget _buildStepCard(ExperienceProfile profile, _StepData step) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: profile.colors.accent.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: profile.colors.accent.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.icon, style: const TextStyle(fontSize: 28)),
          SizedBox(height: _h(AppSpacing.md)),
          Text(
            step.title,
            style: AppTextStyles.of(context).displaySmall.copyWith(
              fontWeight: profile.visualWeight,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: _h(AppSpacing.sm)),
          Text(
            step.subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: c.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          SizedBox(height: _h(AppSpacing.lg)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go(step.route),
              style: ElevatedButton.styleFrom(
                backgroundColor: profile.colors.accent,
                foregroundColor: c.isDark ? const Color(0xFF07090E) : Colors.white,
                padding: EdgeInsets.symmetric(vertical: _h(AppSpacing.sm + 4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                step.ctaLabel,
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSabbathContent(ExperienceProfile profile, AppLocalizations l) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.lg)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [profile.colors.accent.withValues(alpha: 0.85), profile.colors.accent.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        Text(_isAm ? '🕊️ የእረፍት ቀን' : '🕊️ Sabbath Rest',
            style: AppTextStyles.of(context).displaySmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        SizedBox(height: _h(AppSpacing.sm)),
        Text(
          _isAm
            ? '"ወደ እኔ የደከማችሁ..." — ማቴዎስ 11፥28'
            : '"Come to me, all who labor..." — Matthew 11:28',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70, height: 1.5),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: _h(AppSpacing.sm)),
        Text(
          _isAm ? 'እግዚአብሔር ዛሬ እንድታርፍ ይጋብዝሃል።' : 'God invites you to rest today.',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildRhythmCompleteCard(ExperienceProfile profile, AppLocalizations l) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: profile.colors.stepComplete.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        const Text('✅', style: TextStyle(fontSize: 32)),
        SizedBox(height: _h(AppSpacing.sm)),
        Text(
          _isAm ? 'የዛሬ ሥርዐት ተፈጸመ' : "Today's rhythm complete",
          style: AppTextStyles.of(context).displaySmall.copyWith(
            color: profile.colors.stepComplete,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: _h(AppSpacing.xs)),
        Text(
          _isAm ? 'ተጨማሪ ከታች አለ።' : 'More below.',
          style: AppTextStyles.bodySmall.copyWith(color: c.textMuted),
        ),
      ]),
    );
  }

  Widget _buildCelebrationCard(ExperienceProfile profile, String userName, ToneService tone, AppLocalizations l) {
    final c = AppColors.of(context);
    final msg = tone.completionMessage(l, userName);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: profile.colors.stepComplete.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text('🎉', style: const TextStyle(fontSize: 36)),
        SizedBox(height: _h(AppSpacing.sm)),
        Text(
          msg,
          style: AppTextStyles.of(context).displaySmall.copyWith(
            color: profile.colors.stepComplete,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }

  Widget _buildSecondaryActions(
    ExperienceProfile profile, int skillsMin, bool connectedToday, int todayXp,
    PlanProgress? planProgress, SoulLogData? todaySoulLog, AppLocalizations l,
  ) {
    final c = AppColors.of(context);
    return Opacity(
      opacity: 0.65,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _buildSecondaryPill('🎯', skillsMin > 0 ? '$skillsMin min' : (_isAm ? 'ጀምር' : 'Start'), () => context.go('/skills')),
            SizedBox(width: _h(AppSpacing.sm)),
            _buildSecondaryPill('👥', connectedToday ? (_isAm ? 'ተገናኝተዋል' : 'Connected') : (_isAm ? 'አገናኝ' : 'Connect'), () => context.go('/fellowship')),
            if (planProgress != null) ...[
              SizedBox(width: _h(AppSpacing.sm)),
              _buildSecondaryPill('📖', '${(planProgress.biblePercent * 100).round()}%', () => context.go('/progress')),
            ],
          ]),
          SizedBox(height: _h(AppSpacing.sm)),
          Row(children: [
            _buildSoulRow(todaySoulLog, l),
            const Spacer(),
            Text('+$todayXp', style: AppTextStyles.bodySmall.copyWith(color: c.textMuted, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  Widget _buildSecondaryPill(String emoji, String label, VoidCallback onTap) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: _h(AppSpacing.sm), vertical: _h(AppSpacing.xs)),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          SizedBox(width: _h(4)),
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: c.textMuted)),
        ]),
      ),
    );
  }

  Widget _buildSoulRow(SoulLogData? todayLog, AppLocalizations l) {
    if (todayLog != null) {
      return GestureDetector(
        onTap: () => _editSoulCheckIn(todayLog),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_moodEmoji(todayLog.mood), style: const TextStyle(fontSize: 16)),
          SizedBox(width: _h(4)),
          Text(_isAm ? _moodLabel(todayLog.mood, true) : _moodLabel(todayLog.mood, false),
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.of(context).textMuted)),
        ]),
      );
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Text('💭', style: TextStyle(fontSize: 14)),
      SizedBox(width: _h(4)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        _miniMoodBtn(1, '😢'), _miniMoodBtn(2, '😕'), _miniMoodBtn(3, '😐'),
        _miniMoodBtn(4, '🙂'), _miniMoodBtn(5, '😊'),
      ]),
    ]);
  }

  Widget _miniMoodBtn(int mood, String emoji) {
    return GestureDetector(
      onTap: () => _logSoulCheckIn(mood),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _h(2)),
        child: Text(emoji, style: const TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildVerseCard(ExperienceProfile profile) {
    final scripture = ScriptureService.getDailyScripture();
    final c = AppColors.of(context);
    return _FadeInAnimation(
      duration: profile.animationDuration,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: _h(AppSpacing.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '"${scripture.text}"',
              style: AppTextStyles.of(context).displaySmall.copyWith(
                fontFamily: 'CormorantGaramond',
                fontStyle: FontStyle.italic,
                height: 1.6,
                fontSize: 20,
                color: c.textSecondary.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _h(AppSpacing.sm)),
            Text(
              scripture.reference,
              style: AppTextStyles.bodySmall.copyWith(
                color: c.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (scripture.textAm != null) ...[
              SizedBox(height: _h(AppSpacing.sm)),
              Text(
                scripture.textAm!,
                style: AppTextStyles.amharicBody.copyWith(
                  fontSize: 13,
                  height: 1.5,
                  color: c.textMuted.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: _h(AppSpacing.md)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => context.go('/bible'),
                  icon: Icon(Icons.play_arrow, size: 14, color: c.textMuted),
                  label: Text('Listen', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: c.textMuted)),
                ),
                SizedBox(width: _h(AppSpacing.md)),
                TextButton.icon(
                  onPressed: () => context.go('/bible'),
                  icon: Icon(Icons.menu_book, size: 14, color: c.textMuted),
                  label: Text('Read', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: c.textMuted)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCelebration(String name, ToneService tone, AppLocalizations l) {
    final c = AppColors.of(context);
    final msg = tone.completionMessage(l, name);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('🎉 ', style: TextStyle(fontSize: 18)),
        Expanded(child: Text(msg, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white))),
      ]),
      backgroundColor: c.success,
      behavior: SnackBarBehavior.floating,
      duration: AppDurations.verySlow,
    ));
  }

  String _moodEmoji(int mood) {
    return ['😢', '😕', '😐', '🙂', '😊'][mood.clamp(1, 5) - 1];
  }

  String _moodLabel(int mood, bool isAm) {
    const labels = ['', 'Struggling', 'Down', 'Okay', 'Good', 'Great'];
    const amLabels = ['', 'እየታገልሁ ነው', 'አዝኛለሁ', 'እሺ', 'ጥሩ', 'በጣም ጥሩ'];
    return isAm ? amLabels[mood.clamp(0, 5)] : labels[mood.clamp(0, 5)];
  }

  Future<void> _logSoulCheckIn(int mood) async {
    await ref.read(soulLogNotifierProvider.notifier).logCheckIn(mood);
    setState(() {});
  }

  void _editSoulCheckIn(SoulLogData log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.md))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_isAm ? 'ስሜትህን ለውጥ' : 'Update your mood', style: AppTextStyles.labelLarge),
            SizedBox(height: AppSpacing.md),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _moodBtn(1, '😢'), _moodBtn(2, '😕'), _moodBtn(3, '😐'),
              _moodBtn(4, '🙂'), _moodBtn(5, '😊'),
            ]),
            SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isAm ? 'ተው' : 'Cancel')),
          ]),
        ),
      ),
    );
  }

  Widget _moodBtn(int mood, String emoji) {
    return GestureDetector(
      onTap: () => _logSoulCheckIn(mood),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.of(context).surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.of(context).border),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
    );
  }
}

class _FadeInAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const _FadeInAnimation({required this.child, this.duration = const Duration(milliseconds: 300)});
  @override State<_FadeInAnimation> createState() => _FadeInAnimationState();
}

class _FadeInAnimationState extends State<_FadeInAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(opacity: _anim, child: widget.child);
}

class _StreakRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isAtRisk;
  final double pulseOpacity;

  _StreakRingPainter({
    required this.progress,
    required this.color,
    this.isAtRisk = false,
    this.pulseOpacity = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    paint.color = color.withValues(alpha: 0.15 * pulseOpacity);
    canvas.drawCircle(center, radius, paint);

    if (progress > 0) {
      paint.color = color.withValues(alpha: pulseOpacity);
      final sweepAngle = 2 * 3.14159 * progress.clamp(0.0, 1.0);
      const startAngle = -3.14159 / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StreakRingPainter old) =>
    old.progress != progress || old.pulseOpacity != pulseOpacity || old.isAtRisk != isAtRisk;
}
