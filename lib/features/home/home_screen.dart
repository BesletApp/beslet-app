import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_durations.dart';
import '../../core/personalization/tone_service.dart';
import '../../core/personalization/personalization_providers.dart';
import '../../core/emotional/experience_profile.dart';
import '../../core/services/summer_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/services/scripture_service.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/tracking_provider.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/providers/daily_flow_provider.dart';
import '../../core/providers/scripture_provider.dart';
import '../../core/providers/word_challenge_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/providers/fellowship_provider.dart';
import '../../core/providers/streak_provider.dart';
import '../../core/providers/soul_log_provider.dart';
import '../../core/services/scene_event_bus.dart';
import '../../core/emotional/mood_content.dart';
import '../../services/update_checker.dart';
import '../../shared/widgets/error_card.dart';
import '../../core/widgets/zone_layout.dart';
import '../../core/widgets/brand_mark.dart';
import '../word_challenge/verse_builder_loop.dart';
import 'widgets/today_heart_check_card.dart';


class _FlowStep {
  final String emoji;
  final String title;
  final String subtitle;
  final bool done;
  final bool current;
  final bool locked;
  final VoidCallback onTap;
  const _FlowStep({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.current,
    required this.locked,
    required this.onTap,
  });
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  bool _isAm = false;
  bool _celebrated = false;
  bool _widgetUpdated = false;

  AnimationController? _staggerCtrl;
  List<Animation<double>>? _staggerAnims;
  bool _staggerStarted = false;
  bool _showMoodPicker = false;

  late final AnimationController _pulseCtrl;
  double _currentSpacingScale = 1.0;

  @override
  void initState() {
    super.initState();
    _initStaggerAnimations(itemDuration: const Duration(milliseconds: 350));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _checkForUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCommunityPrompt());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLampInvitation());
    WidgetsBinding.instance.addPostFrameCallback((_) => _startStaggerOnce());
  }

  void _initStaggerAnimations({required Duration itemDuration, Curve? curve, int count = 4}) {
    // relaxed stagger for calm, intentional entry
    final gap = const Duration(milliseconds: 120);
    final totalDuration = itemDuration + gap * (count - 1);
    _staggerCtrl?.dispose();
    _staggerCtrl = AnimationController(vsync: this, duration: totalDuration);
    _staggerAnims = List.generate(count, (i) {
      final start = (gap.inMilliseconds * i) / totalDuration.inMilliseconds;
      final end = (gap.inMilliseconds * i + itemDuration.inMilliseconds) / totalDuration.inMilliseconds;
      return CurvedAnimation(
        parent: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _staggerCtrl!,
            curve: Interval(start.clamp(0.0, 1.0), end.clamp(0.0, 1.0), curve: curve ?? Curves.easeInOut),
          ),
        ),
        curve: curve ?? Curves.easeInOut,
      );
    });
    _staggerStarted = false;
  }

  void _startStaggerOnce() {
    final ctrl = _staggerCtrl;
    if (ctrl != null && !_staggerStarted) {
      ctrl.forward();
      _staggerStarted = true;
    }
  }

  @override
  void dispose() {
    _staggerCtrl?.dispose();
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
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.joinTelegram),
      action: SnackBarAction(label: l.join, onPressed: _openTelegram),
      duration: AppDurations.verySlow,
    ));
  }

  Future<void> _openTelegram() async {
    await launchUrl(
      Uri.parse('https://t.me/besletcommunity'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _checkLampInvitation() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('lampInviteSeen') ?? false;
    if (seen || !mounted) return;
    await prefs.setBool('lampInviteSeen', true);
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final cc = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: cc.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.md)),
          title: Text(
            _isAm ? 'መብራት ወደ ቤትህ ማያ ገጽ' : 'The Lamp at Dawn',
            style: TextStyle(color: cc.primary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isAm
                    ? 'አንድ ቃል በኪስህ የሚያስቀምጥ መብራት። በመንገድህ አይገባም፤ ምንም አይከታተልም።'
                    : 'A lamp that keeps one Word in your pocket. It stays out of your way, and it tracks nothing.',
                style: TextStyle(color: cc.textSecondary, fontSize: 13, height: 1.5),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                _isAm
                    ? 'ከሆነ በኋላ ፈልገህ ካወጣኸው፣ ዳግም አንጠይቅም።'
                    : 'If you ever remove it, we will never bring it up again.',
                style: TextStyle(color: cc.textMuted, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(_isAm ? 'አልፈልግም' : 'No, thank you', style: TextStyle(color: cc.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cc.primary,
                foregroundColor: cc.isDark ? const Color(0xFF07090E) : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.sm)),
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await HomeWidget.requestPinWidget(androidName: 'BesletWidget');
              },
              child: Text(_isAm ? 'መብራቱን ጨምር' : 'Add the lamp'),
            ),
          ],
        );
      },
    );
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
      ref.refresh(todayFellowshipProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final trackingAsync = ref.watch(trackingDataProvider);
    final todayFellowship = ref.watch(todayFellowshipProvider);
    final flow = ref.watch(dailyFlowProvider);
    final biblePlan = ref.watch(todayBiblePlanProvider);
    final todayWord = ref.watch(todayWordChallengeProvider).valueOrNull;
    final tone = ref.watch(toneServiceProvider);
    final engine = ref.watch(personalizationEngineProvider);

    _isAm = Localizations.localeOf(context).languageCode == 'am';
    final streakState = ref.watch(streakStateProvider).valueOrNull;
    final todaySoulLog = ref.watch(todaySoulLogProvider).valueOrNull;
    final l = AppLocalizations.of(context)!;

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: ErrorCard(message: 'Could not load your data', onRetry: _onRefresh)),
      data: (user) {
        final tracking = trackingAsync.valueOrNull;
        final skillsMin = tracking?.skillsMinutes ?? 0;
        final connectedToday = todayFellowship.valueOrNull != null;
        final streak = tracking?.streak ?? 0;

        if (!_widgetUpdated) {
          _widgetUpdated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await WidgetService.updateWidgetData(isAm: _isAm);
          });
        }

        final allComplete = flow.done >= flow.total;

        if (allComplete && !_celebrated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showCelebration(user.name, tone, l);
              ref.read(sceneEventBusProvider).emit(SceneEventType.bloom);
              setState(() => _celebrated = true);
            }
          });
        } else if (!allComplete) {
          _celebrated = false;
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

        if (_staggerCtrl?.duration != profile.animationDuration) {
          _initStaggerAnimations(
            itemDuration: profile.animationDuration,
            curve: profile.animationCurve,
            count: 4,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) => _startStaggerOnce());
        }

        if (streakState?.isAtRisk == true && !_pulseCtrl.isAnimating) {
          _pulseCtrl.repeat(reverse: true);
        } else if (streakState?.isAtRisk != true && _pulseCtrl.isAnimating) {
          _pulseCtrl.stop();
          _pulseCtrl.value = 1.0;
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ZoneLayout(
                  orientation: _buildStaggered(0, _buildGreetingBlock(profile, user, l, tone, streak, streakState?.isAtRisk ?? false, todaySoulLog?.mood)),
                  primary: _buildStaggered(1, _buildPrimaryStepCard(
                    profile, flow,
                    streakState?.isSabbathToday ?? false, allComplete, user.name, tone, l,
                    biblePlan, todayWord,
                  )),
                  support: _buildStaggered(2, _buildRhythmSurface(
                    profile, skillsMin, connectedToday, todaySoulLog, l,
                  )),
                  anchor: _buildStaggered(3, const VerseBuilderCard()),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaggered(int index, Widget child) {
    final anims = _staggerAnims;
    if (anims == null || index >= anims.length) return child;
    return AnimatedBuilder(
      animation: anims[index],
      builder: (context, child) => Opacity(
        opacity: anims[index].value,
        child: child,
      ),
      child: child,
    );
  }

  Widget _buildGreetingBlock(ExperienceProfile profile, User user, AppLocalizations l, ToneService tone, int streak, bool isAtRisk, int? currentMood) {
    final hour = DateTime.now().hour;
    final greeting = tone.greeting(l, hour, gender: user.gender);
    final name = user.name.split(' ').first;
    final c = AppColors.of(context);

    final seasonLine = _isAm
        ? SummerService.seasonFor(DateTime.now()).am
        : SummerService.seasonFor(DateTime.now()).en;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const TodayHeartCheckCard(),
        SizedBox(height: _h(AppSpacing.md)),
        Row(children: [
          const Spacer(),
          BrandMark(size: 30, color: AppColors.of(context).primary),
        ]),
        SizedBox(height: _h(AppSpacing.sm)),
        Text(
          seasonLine,
          style: AppTextStyles.bodySmall.copyWith(
            color: c.textSecondary.withValues(alpha: 0.45),
            fontSize: 11,
          ),
        ),
        SizedBox(height: _h(AppSpacing.sm)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildGreetingText(profile, greeting, name, l)),
            if (profile.showStreakRing) ...[
              SizedBox(width: _h(AppSpacing.sm)),
              _buildStreakInline(profile, streak, isAtRisk),
            ],
          ],
        ),
        if (currentMood != null) ...[
          SizedBox(height: _h(AppSpacing.sm)),
          Row(
            children: [
              Text(_moodEmoji(currentMood), style: const TextStyle(fontSize: 14)),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _isAm ? MoodContent.whisper[currentMood]!.am : MoodContent.whisper[currentMood]!.en,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: c.primary.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              SizedBox(width: 22),
              Expanded(
                child: Text(
                  _isAm ? MoodContent.identity[currentMood]!.am : MoodContent.identity[currentMood]!.en,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: c.textSecondary.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ] else if (_showMoodPicker)
          Padding(
            padding: EdgeInsets.only(top: _h(AppSpacing.sm)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                for (final m in [1, 2, 3, 4, 5])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _moodBtn(m, _moodEmoji(m)),
                  ),
              ]),
            ]),
          )
        else
          Material(color: Colors.transparent, child: InkWell(
            onTap: () => setState(() => _showMoodPicker = true),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.only(top: _h(AppSpacing.sm)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('💭', style: const TextStyle(fontSize: 14)),
                SizedBox(width: AppSpacing.xs),
                Text(
                  _isAm ? 'ስሜትህ እንዴት ነው?' : 'How are you?',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: c.textMuted),
                ),
              ]),
            ),
          )),
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

  Widget _buildStreakInline(ExperienceProfile profile, int streak, bool isAtRisk) {
    final p = _milestoneProgress(streak);
    final nextMilestone = streak < 7 ? 7 : streak < 14 ? 14 : streak < 30 ? 30 : streak < 90 ? 90 : 365;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/progress'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: profile.colors.streakRing.withValues(alpha: isAtRisk ? 0.08 : 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: profile.colors.streakRing.withValues(alpha: isAtRisk ? 0.5 : 0.25)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.local_fire_department, size: 14, color: profile.colors.streakRing),
            SizedBox(width: AppSpacing.xs),
            Text(
              '$streak',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: profile.colors.streakRing,
              ),
            ),
            if (p < 1.0 && !isAtRisk) ...[
              SizedBox(width: AppSpacing.xs),
              Text(
                '$nextMilestone',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 9,
                  color: profile.colors.streakRing.withValues(alpha: 0.4),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildPrimaryStepCard(
    ExperienceProfile profile, DailyFlow flow, bool isSabbath,
    bool allComplete, String userName, ToneService tone, AppLocalizations l,
    TodayReadingPlan plan, VerseChallengeData? todayWord,
  ) {
    if (isSabbath) {
      return _buildSabbathContent(profile, l);
    }
    if (allComplete) {
      // The day is never "finished" — celebration is a soft banner above the
      // still-open flow, never a replacement for it.
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildSoftDoneBanner(profile, userName, tone, l),
        SizedBox(height: _h(AppSpacing.zoneGap)),
        if (todayWord == null)
          _buildFlowCard(profile, flow, plan, l)
        else
          _buildWordRingCard(profile, flow, plan, l, todayWord, compact: true),
      ]);
    }
    if (todayWord == null) {
      return _buildFlowCard(profile, flow, plan, l);
    }
    return _buildWordRingCard(profile, flow, plan, l, todayWord);
  }

  Widget _buildWordRingCard(ExperienceProfile profile, DailyFlow flow, TodayReadingPlan plan, AppLocalizations l, VerseChallengeData todayWord, {bool compact = false}) {
    final c = AppColors.of(context);
    final acc = profile.colors.accent;

    final verseText = _isAm && todayWord.textAm != null && todayWord.textAm!.isNotEmpty
        ? todayWord.textAm!
        : todayWord.textEn;

    final request = todayWord.userPrayer;
    final act = todayWord.chosenAct;

    final steps = <_FlowStep>[
      _FlowStep(
        emoji: '📖',
        title: _isAm ? 'መጽሐፍ ቅዱስ' : 'Bible',
        subtitle: '${_isAm ? 'የዛሬ ንባብ' : "Today's reading"}: ${_isAm ? plan.labelAm : plan.labelEn}',
        done: flow.bibleDone,
        current: flow.currentStep == 0,
        locked: flow.currentStep > 0,
        onTap: () => _openFlowStep(true, '/bible?book=${plan.bookId}&chapter=${plan.chapter}'),
      ),
      _FlowStep(
        emoji: '🙏',
        title: _isAm ? 'ጸሎት' : 'Prayer',
        subtitle: _isAm ? 'ያነበብከውን መሠረት አድርገህ ጸልይ' : 'Pray based on what you read',
        done: flow.prayerDone,
        current: flow.currentStep == 1,
        locked: flow.currentStep > 1 || !flow.bibleDone,
        onTap: () => _openFlowStep(flow.bibleDone, '/prayer', hint: l.beginWithWord),
      ),
      _FlowStep(
        emoji: '🌱',
        title: _isAm ? 'ተግባር' : 'Act',
        subtitle: _isAm ? 'ተግባራት · ልምዶች · ክህሎት · ማህበር · ቤተሰብ' : 'Tasks · Habits · Skills · Fellowship · Family',
        done: flow.actionDone,
        current: flow.currentStep == 2,
        locked: flow.currentStep > 2 || !(flow.bibleDone && flow.prayerDone),
        onTap: () => _openFlowStep(
          flow.bibleDone && flow.prayerDone,
          '/daily-todo',
          hint: _isAm ? 'በመጀመሪያ ቃሉ እና ጸሎት' : 'Begin with the Word and Prayer first',
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: acc.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: acc.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                _isAm ? 'የዛሬ ቃልህ' : 'Your Word today',
                style: AppTextStyles.of(context).displaySmall.copyWith(
                  fontWeight: profile.visualWeight,
                  color: c.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: acc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: acc.withValues(alpha: 0.3)),
              ),
              child: Text(
                _isAm ? ScriptureService.amharicReference(todayWord.reference) : todayWord.reference,
                style: AppTextStyles.bodySmall.copyWith(fontSize: 11, fontWeight: FontWeight.w700, color: acc),
              ),
            ),
          ]),
          SizedBox(height: _h(AppSpacing.md)),
          Text(
            verseText,
            style: _isAm
                ? AppTextStyles.amharicBody.copyWith(fontSize: 17, color: c.textPrimary, height: 1.55)
                : AppTextStyles.bodyLarge.copyWith(fontSize: 17, color: c.textPrimary, height: 1.55),
          ),
          if (request != null && request.isNotEmpty) ...[
            SizedBox(height: _h(AppSpacing.md)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_h(AppSpacing.sm)),
              decoration: BoxDecoration(
                color: acc.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: acc.withValues(alpha: 0.5), width: 3)),
              ),
              child: Text(
                _isAm ? 'ጸሎትህ፦  $request' : 'You prayed:  $request',
                style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, height: 1.45, fontSize: 12),
              ),
            ),
          ],
          if (act != null && act.isNotEmpty) ...[
            SizedBox(height: _h(AppSpacing.sm)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(_h(AppSpacing.sm)),
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: c.primary.withValues(alpha: 0.5), width: 3)),
              ),
              child: Text(
                _isAm ? 'ዛሬ ማድረግእት የመረጥከው፦ $act' : "What you chose to live today:  $act",
                style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, height: 1.45, fontSize: 12),
              ),
            ),
          ],
          if (!compact) ...[
            SizedBox(height: _h(AppSpacing.md)),
            Divider(height: 1, color: c.border.withValues(alpha: 0.5)),
            SizedBox(height: _h(AppSpacing.sm)),
            Row(children: [
              Expanded(child: Text(l.todaysFlow, style: AppTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: c.textMuted))),
              Text(
                '${flow.done}/${flow.total}',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: acc),
              ),
            ]),
            SizedBox(height: _h(AppSpacing.xs)),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: flow.total == 0 ? 0 : flow.done / flow.total,
                minHeight: 4,
                backgroundColor: c.border.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(acc),
              ),
            ),
          ],
          SizedBox(height: _h(AppSpacing.sm)),
          for (final s in steps) ...[
            _buildFlowRow(profile, s, profile.colors.stepComplete),
            SizedBox(height: _h(AppSpacing.xs)),
          ],
          if (flow.currentStep < flow.total)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => steps[flow.currentStep].onTap(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: acc,
                  foregroundColor: c.isDark ? const Color(0xFF07090E) : Colors.white,
                  padding: EdgeInsets.symmetric(vertical: _h(AppSpacing.sm + 4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _currentStepCta(flow, l),
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFlowCard(ExperienceProfile profile, DailyFlow flow, TodayReadingPlan plan, AppLocalizations l) {
    final c = AppColors.of(context);
    final acc = profile.colors.accent;
    final complete = profile.colors.stepComplete;
    final steps = <_FlowStep>[
      _FlowStep(
        emoji: '📖',
        title: _isAm ? 'መጽሐፍ ቅዱስ' : 'Bible',
        subtitle: '${_isAm ? 'የዛሬ ንባብ' : "Today's reading"}: ${_isAm ? plan.labelAm : plan.labelEn}',
        done: flow.bibleDone,
        current: flow.currentStep == 0,
        locked: flow.currentStep > 0,
        onTap: () => _openFlowStep(true, '/bible?book=${plan.bookId}&chapter=${plan.chapter}'),
      ),
      _FlowStep(
        emoji: '🙏',
        title: _isAm ? 'ጸሎት' : 'Prayer',
        subtitle: _isAm ? 'ያነበብከውን መሠረት አድርገህ ጸልይ' : 'Pray based on what you read',
        done: flow.prayerDone,
        current: flow.currentStep == 1,
        locked: flow.currentStep > 1 || !flow.bibleDone,
        onTap: () => _openFlowStep(flow.bibleDone, '/prayer', hint: l.beginWithWord),
      ),
      _FlowStep(
        emoji: '🌱',
        title: _isAm ? 'ተግባር' : 'Act',
        subtitle: _isAm ? 'ተግባራት · ልምዶች · ክህሎት · ማህበር · ቤተሰብ' : 'Tasks · Habits · Skills · Fellowship · Family',
        done: flow.actionDone,
        current: flow.currentStep == 2,
        locked: flow.currentStep > 2 || !(flow.bibleDone && flow.prayerDone),
        onTap: () => _openFlowStep(
          flow.bibleDone && flow.prayerDone,
          '/daily-todo',
          hint: _isAm ? 'በመጀመሪያ ቃሉ እና ጸሎት' : 'Begin with the Word and Prayer first',
        ),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.lg)),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: acc.withValues(alpha: 0.3), width: 1),
        boxShadow: [
          BoxShadow(color: acc.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                l.todaysFlow,
                style: AppTextStyles.of(context).displaySmall.copyWith(
                  fontWeight: profile.visualWeight,
                  color: c.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: complete.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: complete.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${flow.done}/${flow.total}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: complete,
                ),
              ),
            ),
          ]),
          SizedBox(height: _h(AppSpacing.sm)),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: flow.total == 0 ? 0 : flow.done / flow.total,
              minHeight: 6,
              backgroundColor: c.border.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(complete),
            ),
          ),
          SizedBox(height: _h(AppSpacing.md)),
          for (final s in steps) ...[
            _buildFlowRow(profile, s, complete),
            SizedBox(height: _h(AppSpacing.sm)),
          ],
          if (flow.currentStep < flow.total)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => steps[flow.currentStep].onTap(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: acc,
                  foregroundColor: c.isDark ? const Color(0xFF07090E) : Colors.white,
                  padding: EdgeInsets.symmetric(vertical: _h(AppSpacing.sm + 4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  _currentStepCta(flow, l),
                  style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _currentStepCta(DailyFlow flow, AppLocalizations l) {
    switch (flow.currentStep) {
      case 0:
        return l.openWord;
      case 1:
        return l.beginPrayer;
      default:
        return l.liveItOut;
    }
  }

  /// Soft lock on Home: locked steps are dimmed and tapping offers a gentle
  /// nudge. The routes themselves stay reachable elsewhere — grace, not gates.
  void _openFlowStep(bool allowed, String route, {String? hint}) {
    if (allowed) {
      context.go(route);
      return;
    }
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(hint ?? l.beginWithWord),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildFlowRow(ExperienceProfile profile, _FlowStep s, Color completeColor) {
    final c = AppColors.of(context);
    final Widget trailing;
    if (s.done) {
      trailing = Icon(Icons.check_circle, size: 18, color: completeColor);
    } else if (s.current) {
      trailing = Icon(Icons.arrow_forward, size: 18, color: profile.colors.accent);
    } else {
      trailing = Icon(Icons.lock_outline, size: 16, color: c.textMuted.withValues(alpha: 0.6));
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: s.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(_h(AppSpacing.sm + 2)),
          decoration: BoxDecoration(
            color: s.current ? profile.colors.accent.withValues(alpha: 0.08) : c.cardElevated.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: s.current ? profile.colors.accent.withValues(alpha: 0.45) : c.border.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Text(s.emoji, style: const TextStyle(fontSize: 18)),
            SizedBox(width: _h(AppSpacing.sm)),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  s.title,
                  style: AppTextStyles.of(context).bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: s.done ? completeColor : c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  s.done ? _isAm ? 'ዛሬ ተጠናቋል' : 'Done today' : s.subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: s.done
                        ? completeColor.withValues(alpha: 0.8)
                        : (s.current ? c.textSecondary : c.textMuted),
                  ),
                ),
              ]),
            ),
            SizedBox(width: _h(AppSpacing.xs)),
            trailing,
          ]),
        ),
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
          style: _isAm
              ? AppTextStyles.amharicBody.copyWith(color: Colors.white70, height: 1.5)
              : AppTextStyles.bodyMedium.copyWith(color: Colors.white70, height: 1.5),
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

  Widget _buildSoftDoneBanner(ExperienceProfile profile, String userName, ToneService tone, AppLocalizations l) {
    final c = AppColors.of(context);
    final msg = tone.completionMessage(l, userName);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.md)),
      decoration: BoxDecoration(
        color: profile.colors.stepComplete.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: profile.colors.stepComplete.withValues(alpha: 0.35)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('🎉', style: TextStyle(fontSize: 18)),
        SizedBox(width: _h(AppSpacing.sm)),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              l.dayStaysOpen,
              style: AppTextStyles.of(context).bodySmall.copyWith(
                color: profile.colors.stepComplete,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg,
              style: AppTextStyles.of(context).bodyMedium.copyWith(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRhythmSurface(
    ExperienceProfile profile, int skillsMin, bool connectedToday,
    SoulLogData? todaySoulLog, AppLocalizations l,
  ) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(_h(AppSpacing.cardPadding)),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _buildActionPill('🎯', skillsMin > 0 ? '$skillsMin min' : (_isAm ? 'ጀምር' : 'Start'), () => context.go('/skills')),
            SizedBox(width: _h(AppSpacing.sm)),
            _buildActionPill('👥', connectedToday ? (_isAm ? 'ተገናኝተዋል' : 'Connected') : (_isAm ? 'አገናኝ' : 'Connect'), () => context.go('/fellowship')),
            SizedBox(width: _h(AppSpacing.sm)),
            _buildActionPill('📝', _isAm ? 'ማስታወሻ' : 'Journal', () => context.go('/journal')),
          ]),
          SizedBox(height: _h(AppSpacing.sm)),
          _buildSoulCheckIn(todaySoulLog, l),
        ],
      ),
    );
  }

  Widget _buildActionPill(String emoji, String label, VoidCallback onTap) {
    final c = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: _h(AppSpacing.sm), vertical: _h(AppSpacing.xs)),
          decoration: BoxDecoration(
            color: c.cardElevated.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            SizedBox(width: _h(AppSpacing.xs)),
            Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: c.textSecondary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSoulCheckIn(SoulLogData? todayLog, AppLocalizations l) {
    final c = AppColors.of(context);
    if (todayLog != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editSoulCheckIn(todayLog),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(_h(AppSpacing.xs)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(_moodEmoji(todayLog.mood), style: const TextStyle(fontSize: 18)),
              SizedBox(width: _h(AppSpacing.xs)),
              Text(
                _isAm ? _moodLabel(todayLog.mood, true) : _moodLabel(todayLog.mood, false),
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: c.textMuted),
              ),
            ]),
          ),
        ),
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _logSoulCheckIn(3),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(_h(AppSpacing.xs)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('💭', style: TextStyle(fontSize: 18)),
            SizedBox(width: _h(AppSpacing.xs)),
            Text(
              _isAm ? 'ስሜትህ እንዴት ነው?' : 'How are you feeling?',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 12, color: c.textMuted),
            ),
          ]),
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
    setState(() => _showMoodPicker = false);
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
    final c = AppColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _logSoulCheckIn(mood),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.border),
          ),
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
      ),
    );
  }
}

