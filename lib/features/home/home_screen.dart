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
import '../../core/providers/streak_provider.dart';
import '../../core/providers/reading_plan_provider.dart';
import '../../core/services/plan_progress_service.dart';
import '../../core/providers/soul_log_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/loop_service.dart';
import '../../services/update_checker.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/enkutatash_overlay.dart';
import '../../core/services/streak_service.dart';
import '../../core/services/witness_service.dart';

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
  bool _isAm = false;
  bool _celebrated = false;
  bool _widgetUpdated = false;
  bool _showCommunity = false;
  bool _soulExpanded = false;
  bool _verseExpanded = false;

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCommunityPrompt());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkEnkutatash());
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
      Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => EnkutatashOverlay(onDismiss: () => Navigator.of(context).pop()),
      ));
    }
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
    final readingProgressAsync = ref.watch(readingProgressProvider);
    final activeLoopAsync = ref.watch(activeLoopProvider);

    _isAm = Localizations.localeOf(context).languageCode == 'am';
    final streakState = ref.watch(streakStateProvider).valueOrNull;
    final todaySoulLog = ref.watch(todaySoulLogProvider).valueOrNull;
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
        final progress = readingProgressAsync.valueOrNull;
        final loop = activeLoopAsync.valueOrNull;

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

        if (loop != null && loop.status == 'active') {
          final loopStart = DateTime.tryParse(loop.startDate);
          if (loopStart != null) {
            final loopDay = DateTime.now().difference(loopStart).inDays + 1;
            if (loopDay > loop.duration && mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _showLoopCompleteDialog(loop));
            }
          }
        }

        final todayXp = (bibleRead ? 20 : 0) + (prayed ? 15 : 0) + (todoStats.completed * 5) + (skillsMin > 0 ? 10 : 0) + (connectedToday ? 5 : 0);
        final phaseIdx = ScriptureService.getPhase(daysElapsed);

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(children: [
                  _buildCompactHeader(context, user, daysElapsed, totalDays, daysRemaining, inSummer, l),
                  const SizedBox(height: 16),
                  _buildLitPath(context, bibleRead, prayed, todoStats, todayXp, tracking, daysElapsed, totalDays, phaseIdx, l),
                  const SizedBox(height: 20),
                  if (streakState?.isSabbathToday == true) ...[
                    _buildSabbathBlessing(context, l),
                    const SizedBox(height: 20),
                  ],
                  _buildSoulCheckIn(context, todaySoulLog, l),
                  const SizedBox(height: 20),
                  if (progress != null) ...[
                    _buildReadingPlanCard(progress, loop, context, l),
                    const SizedBox(height: 20),
                  ],
                  _buildCollapsibleVerse(context),
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

  static const _promptNames = ['📖 Verse', '💝 Appreciate', '🤗 Check in', '💡 Share', '🙏 Pray', '📞 Call', '🕊️ Reflect'];
  static const _promptNamesAm = ['📖 ጥቅስ', '💝 አመሰግናለሁ', '🤗 ሰላም', '💡 አካፍል', '🙏 ጸልይ', '📞 ደውል', '🕊️ አሰላስል'];

  List<_PillarData> _computePillars(bool prayed, bool bibleRead, int skillsMin, bool connectedToday, TodoStats todoStats, AppLocalizations l) {
    final promptIdx = DateTime.now().weekday - 1;
    final promptText = connectedToday ? l.fellowshipConnected : (_isAm ? _promptNamesAm[promptIdx] : _promptNames[promptIdx]);
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
        statusText: promptText,
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

  Widget _buildReadingPlanCard(PlanProgress progress, ReadingLoop? loop, BuildContext context, AppLocalizations l) {
    final c = AppColors.of(context);
    final pct = (progress.biblePercent * 100).round();
    return GestureDetector(
      onTap: () => context.go('/progress'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('📖', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text('Reading Plan', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
            const Spacer(),
            Text('$pct%',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress.biblePercent,
              backgroundColor: c.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text('${progress.totalChaptersRead} of ${progress.totalChaptersInBible} chapters',
              style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, fontSize: 12)),
          if (loop != null) ...[
            const SizedBox(height: 6),
            Text('Loop ${loop.loopNumber}: Day ${_dayInLoop(loop)} of ${loop.duration}',
                style: AppTextStyles.bodySmall.copyWith(color: c.textMuted, fontSize: 11)),
          ],
          if (progress.currentBookName != null) ...[
            const SizedBox(height: 4),
            Text('Currently: ${progress.currentBookName} Ch. ${progress.currentBookChapter} of ${progress.currentBookTotal}',
                style: AppTextStyles.bodySmall.copyWith(color: c.textMuted, fontSize: 11)),
          ],
        ]),
      ),
    );
  }

  Widget _buildCollapsibleVerse(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _verseExpanded = !_verseExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Text('✨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_isAm ? 'የዛሬው ጥቅስ' : 'Verse of the Day',
                    style: AppTextStyles.labelLarge.copyWith(color: c.textPrimary)),
              ),
              Icon(_verseExpanded ? Icons.expand_less : Icons.expand_more, color: c.textMuted),
            ]),
          ),
        ),
        if (_verseExpanded) ...[
          Divider(height: 1, color: c.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildVerseHero(context),
          ),
        ],
      ]),
    );
  }

  int _dayInLoop(ReadingLoop loop) {
    final start = DateTime.tryParse(loop.startDate);
    if (start == null) return 1;
    return (DateTime.now().difference(start).inDays + 1).clamp(1, loop.duration);
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
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textSecondary, fontSize: 11, height: 1.4),
              ),
            ]),
          ),
          GestureDetector(
            onTap: _dismissCommunity,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.close, size: 18, color: AppColors.of(context).textMuted),
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

  Widget _buildSoulCheckIn(BuildContext context, SoulLogData? todayLog, AppLocalizations l) {
    if (todayLog case final log?) {
      return _buildSoulCheckInDone(log, l);
    }
    return _buildSoulCheckInPrompt(l);
  }

  Widget _buildSoulCheckInDone(SoulLogData log, AppLocalizations l) {
    final isAm = _isAm;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _editSoulCheckIn(log),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Text(_moodEmoji(log.mood), style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAm ? 'ዛሬ እንዴት ነህ: ${_moodLabel(log.mood, isAm)}' : 'How you are today: ${_moodLabel(log.mood, isAm)}',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.of(context).textSecondary),
              ),
            ),
            Icon(Icons.edit_square, size: 18, color: AppColors.of(context).textMuted),
          ]),
        ),
      ),
    );
  }

  Widget _buildSoulCheckInPrompt(AppLocalizations l) {
    final isAm = _isAm;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Column(children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _soulExpanded = !_soulExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              const Text('💭', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(isAm ? 'ነፍስህ እንዴት ናት?' : 'How\'s your soul?',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.of(context).textPrimary)),
              ),
              Icon(_soulExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.of(context).textMuted),
            ]),
          ),
        ),
        if (_soulExpanded) ...[
          Divider(height: 1, color: AppColors.of(context).border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Text(isAm ? 'ልብህ ላይ ያለው ምንድን ነው?' : 'What is on your heart?',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textMuted)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _moodBtn(1, '😢'), _moodBtn(2, '😕'), _moodBtn(3, '😐'),
                _moodBtn(4, '🙂'), _moodBtn(5, '😊'),
              ]),
            ]),
          ),
        ],
      ]),
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
    setState(() => _soulExpanded = false);
  }

  void _editSoulCheckIn(SoulLogData log) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_isAm ? 'ስሜትህን ለውጥ' : 'Update your mood',
                style: AppTextStyles.labelLarge),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              _moodBtn(1, '😢'), _moodBtn(2, '😕'), _moodBtn(3, '😐'),
              _moodBtn(4, '🙂'), _moodBtn(5, '😊'),
            ]),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isAm ? 'ተው' : 'Cancel')),
          ]),
        ),
      ),
    );
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
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textSecondary)),
      ]),
    ]);
  }

  Widget _buildLitPath(BuildContext context, bool bibleRead, bool prayed, TodoStats todoStats, int todayXp, TrackingData? tracking, int daysElapsed, int totalDays, int phaseIdx, AppLocalizations l) {
    final tasksDone = todoStats.total > 0 && todoStats.completed >= todoStats.total;
    final step1done = bibleRead;
    final step2done = bibleRead && prayed;
    final step3done = bibleRead && prayed && tasksDone;
    final currentStep = step1done ? (step2done ? (step3done ? 3 : 2) : 1) : 0;

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
                color: step1done ? AppColors.progressGreen : AppColors.of(context).border,
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
        isLocked: false,
        isCurrent: currentStep == 1,
        accent: AppColors.spiritualPurple,
        actionLabel: step2done ? null : 'Start Prayer →',
        onAction: !step2done ? () => context.go('/prayer') : null,
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
                color: step2done ? AppColors.progressGreen : AppColors.of(context).border,
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
        isLocked: false,
        isCurrent: currentStep == 2,
        accent: AppColors.progressGreen,
        actionLabel: step3done ? null : (todoStats.total == 0 ? 'Plan →' : 'Do →'),
        onAction: !step3done ? () => context.go('/daily-todo') : null,
        onView: step3done ? () => context.go('/daily-todo') : null,
      ),
      const SizedBox(height: 16),
      _buildRitualFooter(streak, todayXp, phaseName, phaseColor, daysElapsed, totalDays, phaseIdx, l),
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
    final bgColor = isCurrent ? AppColors.cardElevated : AppColors.of(context).card;
    final borderColor = isCurrent ? accent.withValues(alpha: 0.4) : (isComplete ? accent.withValues(alpha: 0.2) : AppColors.of(context).border);
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
                  Text(label, style: AppTextStyles.labelLarge.copyWith(fontSize: 14, color: isComplete ? accent : AppColors.of(context).textPrimary)),
                  Text(purpose, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.of(context).textMuted, fontStyle: FontStyle.italic)),
                ]),
              ),
              if (isComplete)
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.15)),
                  child: Icon(Icons.check, size: 14, color: accent),
                )
              else if (isLocked)
                Icon(Icons.lock_outline, size: 16, color: AppColors.of(context).textMuted),
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

  Widget _buildRitualFooter(int streak, int todayXp, String phaseName, Color phaseColor, int daysElapsed, int totalDays, int phaseIdx, AppLocalizations l) {
    final progress = totalDays > 0 ? daysElapsed / totalDays : 0.0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border, width: 0.5),
      ),
      child: Column(children: [
        Row(children: [
          Row(children: [
            Text(StreakService.growthEmoji(streak), style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text('$streak days', style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.of(context).textPrimary)),
          ]),
          const SizedBox(width: 16),
          Container(width: 1, height: 12, color: AppColors.of(context).border),
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
                backgroundColor: AppColors.of(context).border,
                valueColor: AlwaysStoppedAnimation(phaseColor),
                minHeight: 3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Day $daysElapsed of $totalDays', style: AppTextStyles.bodySmall.copyWith(fontSize: 9, color: AppColors.of(context).textMuted)),
        ]),
        const SizedBox(height: 8),
        Text(
          WitnessService.phaseMessage(phaseIdx, daysElapsed, _isAm),
          style: TextStyle(fontSize: 10, color: phaseColor, fontWeight: FontWeight.w500, height: 1.3),
        ),
      ]),
    );
  }

  Widget _buildSabbathBlessing(BuildContext context, AppLocalizations l) {
    final isAm = _isAm;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Text(isAm ? '🕊️ የእረፍት ቀን' : '🕊️ Sabbath Rest',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          isAm
            ? '"ወደ እኔ የደከማችሁ የተሸከማችሁም ሁሉ ኑ፤ እኔም አሳርፋችኋለሁ።" — ማቴዎስ 11፥28'
            : '"Come to me, all who labor and are heavy laden, and I will give you rest." — Matthew 11:28',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFE8F5E9)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          isAm ? 'እግዚአብሔር ዛሬ እንድታርፍ ይጋብዝሃል። ዘንድሮ ሥራ አልጠበቀብህም። 🌱' : 'God invites you to rest today. No tasks expected. 🌱',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: Color(0xFFC8E6C9)),
          textAlign: TextAlign.center,
        ),
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
            color: AppColors.of(context).card.withValues(alpha: 0.6),
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
              color: AppColors.of(context).card.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: AppColors.primary.withValues(alpha: 0.2), width: 2)),
            ),
            child: Text(scripture.textAm!,
                style: AppTextStyles.amharicBody.copyWith(fontSize: 13, height: 1.6, color: AppColors.of(context).textSecondary),
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
