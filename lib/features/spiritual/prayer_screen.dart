import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/services/prayer_reminder_service.dart';
import '../../core/services/prayer_alarm_sound_service.dart';
import '../../core/services/prayer_topics_service.dart';
import '../../core/services/scene_event_bus.dart';
import '../growth/widgets/mini_vine.dart';
import 'widgets/prayer_guide_card.dart';
import '../../l10n/app_localizations.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});
  @override ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> with WidgetsBindingObserver {
  DateTime? _startTime;
  Timer? _timer;
  bool _isRunning = false;
  bool _timerExpanded = false;
  final _noteController = TextEditingController();
  List<PrayerTime> _prayerTimes = [];
  String? _soundName;
  bool _usingCustomSound = false;
  Timer? _countdownTimer;
  final _topicsController = TextEditingController();
  Timer? _topicsSaveTimer;
  bool _topicsSaved = false;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReminder();
    _loadTopics();
    _startCountdown();
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _countdownTimer?.cancel();
    _topicsSaveTimer?.cancel();
    WakelockPlus.disable();
    _noteController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadReminder() async {
    final times = await PrayerReminderService.getPrayerTimes();
    final soundName = await PrayerAlarmSoundService.getSoundDisplayName();
    final custom = await PrayerAlarmSoundService.hasCustomSound();
    if (mounted) {
      setState(() {
        _prayerTimes = times;
        _soundName = soundName;
        _usingCustomSound = custom;
      });
    }
  }

  Future<void> _loadTopics() async {
    final text = await PrayerTopicsService.getTopics();
    if (mounted) _topicsController.text = text;
  }

  void _onTopicsChanged(String value) {
    _topicsSaveTimer?.cancel();
    if (_topicsSaved) setState(() => _topicsSaved = false);
    _topicsSaveTimer = Timer(const Duration(milliseconds: 1200), () async {
      await PrayerTopicsService.saveTopics(value);
      if (mounted) setState(() => _topicsSaved = true);
    });
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_isRunning && _startTime != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
      }
      _onResumed();
    }
  }

  /// The countdown froze while the app was suspended; recompute it now and
  /// reload the prayer list so a time changed elsewhere, an alarm firing, or
  /// a day rollover is reflected immediately instead of on the next 30s tick.
  void _onResumed() {
    _loadReminder();
    if (mounted) setState(() {});
  }

  int get _elapsedSeconds => _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;

  void _logNow() {
    final note = _noteController.text.trim();
    ref.read(prayerNotifierProvider.notifier).logPrayer(0, note: note.isEmpty ? null : note);
    _noteController.clear();
    ref.read(sceneEventBusProvider).emit(SceneEventType.water);
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.prayerXpEarned, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF07090E))),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
      ));
    }
  }

  void _startTimer() {
    setState(() { _isRunning = true; _startTime = DateTime.now(); });
    WakelockPlus.enable();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _completeTimer() {
    _timer?.cancel();
    WakelockPlus.disable();
    final minutes = (_elapsedSeconds / 60).ceil().clamp(1, 999);
    final note = _noteController.text.trim();
    ref.read(prayerNotifierProvider.notifier).logPrayer(minutes, note: note.isEmpty ? null : note);
    _noteController.clear();
    ref.read(sceneEventBusProvider).emit(SceneEventType.water);
    setState(() { _startTime = null; _isRunning = false; _timerExpanded = false; });
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l.prayerXpEarned, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF07090E))),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2),
      ));
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: isError ? 4 : 2),
    ));
  }

  Future<void> _handlePermissionDenied(PrayerAlarmPermissionStatus status) async {
    if (!mounted) return;
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(isAm ? 'ፍቃድ ያስፈልጋል' : 'Permission needed', style: AppTextStyles.labelLarge),
        content: Text(
          status == PrayerAlarmPermissionStatus.exactAlarmDenied
              ? (isAm ? '«Alarms & reminders» ያንቁ።' : 'Turn on "Alarms & reminders".')
              : (isAm ? 'ማሳሰቢያዎችን ያንቁ።' : 'Enable notifications for Beslet.'),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.of(context).textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(isAm ? 'ይቅር' : 'Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (status == PrayerAlarmPermissionStatus.exactAlarmDenied) {
                PrayerReminderService.openExactAlarmSettings();
              } else {
                PrayerReminderService.openNotificationSettings();
              }
            },
            child: Text(isAm ? 'ቅንብሮች' : 'Open Settings', style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _addPrayerTime() async {
    final l = AppLocalizations.of(context)!;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final permission = await PrayerReminderService.ensurePermissions();
    if (permission != PrayerAlarmPermissionStatus.granted) {
      await _handlePermissionDenied(permission);
      return;
    }
    try {
      await PrayerReminderService.addPrayerTime(time.hour, time.minute);
      if (mounted) _showSnack(l.timeAdded);
    } catch (e) {
      if (mounted) _showSnack('Failed: $e', isError: true);
    }
    await _loadReminder();
  }

  Future<void> _togglePrayerTime(PrayerTime t, bool enabled) async {
    await PrayerReminderService.setPrayerTimeEnabled(t.id, enabled);
    await _loadReminder();
  }

  Future<void> _confirmRemovePrayerTime(PrayerTime t) async {
    final l = AppLocalizations.of(context)!;
    final timeLabel = _formatPrayerTime(t.hour, t.minute);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.letGoTime),
        content: Text(l.removePrayerTimeConfirm(timeLabel)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await PrayerReminderService.removePrayerTime(t.id);
      _showSnack(l.timeRemoved);
      await _loadReminder();
    }
  }

  Future<void> _pickAlarmSound() async {
    try {
      await PrayerAlarmSoundService.pickAndSaveFromPhone();
      await PrayerReminderService.rescheduleAfterSoundChange();
      _showSnack('Alarm tone updated 🎵');
    } on PrayerAlarmSoundException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack('Could not pick sound: $e', isError: true);
    }
    await _loadReminder();
  }

  Future<void> _useDefaultSound() async {
    await PrayerAlarmSoundService.useDefaultTone();
    await PrayerReminderService.rescheduleAfterSoundChange();
    _showSnack('Using default alarm tone');
    await _loadReminder();
  }

  Widget _buildSoundRow(AppLocalizations l) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final toneLabel = _usingCustomSound
        ? (_soundName ?? (isAm ? 'ብጁ ድምፅ' : 'Custom tone'))
        : (isAm ? 'ነባሪ የማንቂያ ድምፅ' : 'Default alarm tone');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isAm ? 'የማንቂያ ድምፅ' : 'Alarm tone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textMuted)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.music_note, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(toneLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickAlarmSound,
              icon: const Icon(Icons.library_music, size: 16),
              label: Text(isAm ? 'ከስልክ ምረጥ' : 'From phone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: BorderSide(color: AppColors.of(context).border), padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          if (_usingCustomSound)
            Expanded(
              child: OutlinedButton(
                onPressed: _useDefaultSound,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.of(context).textSecondary, side: BorderSide(color: AppColors.of(context).border), padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(isAm ? 'ነባሪ' : 'Default', style: AppTextStyles.bodySmall),
              ),
            ),
        ]),
        const SizedBox(height: 8),
      ],
    );
  }

  @override Widget build(BuildContext context) {
    final todayLog = ref.watch(todayPrayerLogProvider);
    final weekDays = ref.watch(prayerDaysThisWeekProvider);
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        title: Text(l.prayer),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          MiniVine(
            seed: 901,
            emphasis: MiniVineEmphasis.water,
            eventSource: ref.read(sceneEventBusProvider),
          ),
          const SizedBox(height: 20),
          const PrayerGuideCard(),
          const SizedBox(height: 20),
          _buildTopicsCard(l),
          const SizedBox(height: 20),
          _buildPrayerCard(todayLog, l),
          const SizedBox(height: 20),
          _buildWeekDots(weekDays, l),
          const SizedBox(height: 20),
          _buildReminderSection(l),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  /// The topics written once and remembered every time. A quiet field like the
  /// journal: type, and it is recorded right there — no button, no fuss.
  Widget _buildTopicsCard(AppLocalizations l) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.edit_note_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.prayerTopics,
                style: AppTextStyles.of(context).labelLarge.copyWith(color: AppColors.primary)),
          ),
          if (_topicsSaved)
            Text(l.topicsSaved,
                style: AppTextStyles.of(context).bodySmall.copyWith(color: c.textMuted)),
        ]),
        const SizedBox(height: 10),
        TextField(
          controller: _topicsController,
          maxLines: 5,
          minLines: 3,
          onChanged: _onTopicsChanged,
          style: AppTextStyles.of(context).bodyMedium,
          decoration: InputDecoration(
            hintText: l.topicsPlaceholder,
            hintStyle: AppTextStyles.of(context).bodySmall,
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ]),
    );
  }

  Widget _buildPrayerCard(AsyncValue<PrayerLog?> todayLog, AppLocalizations l) {
    final alreadyPrayed = todayLog.valueOrNull != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGoldSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: alreadyPrayed ? _buildPrayedView(l) : _buildNotPrayedView(l),
    );
  }

  Widget _buildNotPrayedView(AppLocalizations l) {
    return Column(children: [
      const Text('🙏', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text(l.didYouPray, style: AppTextStyles.displaySmall),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: _logNow,
          icon: const Icon(Icons.check_circle, color: Color(0xFF07090E)),
          label: Text(l.iPrayedToday, style: AppTextStyles.labelLarge.copyWith(color: Color(0xFF07090E))),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: TextField(
          controller: _noteController,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: l.notePlaceholder,
            hintStyle: AppTextStyles.bodySmall,
            filled: true, fillColor: AppColors.of(context).card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 2, minLines: 1,
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => setState(() => _timerExpanded = !_timerExpanded),
        child: AnimatedCrossFade(
          firstChild: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.timer_outlined, size: 16, color: AppColors.of(context).textMuted),
            const SizedBox(width: 4),
            Text(l.trackTime, style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textMuted)),
          ]),
          secondChild: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.of(context).card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.of(context).border.withValues(alpha: 0.5)),
            ),
            child: Column(children: [
              Row(children: [
                const Text('🕊️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'am'
                        ? 'ልብህን ለእግዚአብሔር አፍስስ'
                        : 'Pour out your heart to God — Psalm 62:8',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.of(context).textPrimary)),
                ),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.timer_outlined, size: 14),
                  label: Text(
                    Localizations.localeOf(context).languageCode == 'am'
                        ? 'ሰዓት ቆጣሪ' : 'Optional: Track time',
                    style: const TextStyle(fontSize: 12)),
                  onPressed: () => setState(() => _timerExpanded = true),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.of(context).textMuted,
                    side: BorderSide(color: AppColors.of(context).border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ]),
          ),
          crossFadeState: _timerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: _buildTimerSection(l),
        ),
        crossFadeState: _timerExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }

  Widget _buildTimerSection(AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        if (!_isRunning) ...[
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _startTimer,
              icon: const Icon(Icons.play_arrow, color: Color(0xFF07090E), size: 20),
              label: Text(l.prayerStart, style: AppTextStyles.labelLarge.copyWith(color: Color(0xFF07090E), fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ] else ...[
          Text(_formatTime(_elapsedSeconds), style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 40)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton.icon(
              onPressed: _completeTimer,
              icon: const Icon(Icons.stop, color: Color(0xFF07090E), size: 20),
              label: Text(l.prayerComplete, style: AppTextStyles.labelLarge.copyWith(color: Color(0xFF07090E), fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildPrayedView(AppLocalizations l) {
    return Column(children: [
      const Text('🙏', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text(l.prayerCompletedToday, style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary)),
      const SizedBox(height: 8),
      Text('+15 XP', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary)),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity, height: 56,
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() { _startTime = null; _isRunning = false; _timerExpanded = false; });
            ref.read(prayerNotifierProvider.notifier).logPrayer(0);
          },
          icon: const Icon(Icons.refresh, color: Color(0xFF07090E)),
          label: Text(l.prayerPrayAgain, style: AppTextStyles.labelLarge.copyWith(color: Color(0xFF07090E))),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    ]);
  }

  Widget _buildWeekDots(AsyncValue<List<bool>> weekDays, AppLocalizations l) {
    return weekDays.when(
      data: (days) {
        final dayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.of(context).card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.of(context).border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.thisWeek, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (i) {
              final prayed = i < days.length && days[i];
              return Column(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: prayed ? AppColors.success.withValues(alpha: 0.2) : AppColors.of(context).border,
                    border: Border.all(color: prayed ? AppColors.success : AppColors.borderLight, width: 2),
                  ),
                  child: Center(child: prayed
                    ? const Icon(Icons.check, size: 18, color: AppColors.success)
                    : Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.of(context).textMuted))),
                ),
                const SizedBox(height: 6),
                Text(dayLabels[i], style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.of(context).textMuted)),
              ]);
            })),
          ]),
        );
      },
      loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildReminderSection(AppLocalizations l) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.alarm, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(l.prayerTimes, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: 4),
        Text(l.prayWithoutCeasing,
            style: AppTextStyles.bodySmall.copyWith(color: c.textMuted)),
        const SizedBox(height: 12),
        if (_prayerTimes.isEmpty)
          Text(l.noPrayerTimes,
              style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted)),
        ...() {
          final next =
              PrayerReminderService.nextPrayerOccurrence(_prayerTimes, DateTime.now());
          if (next == null) return const <Widget>[];
          final remaining = _remainingUntilNow(next.when);
          if (remaining == null) return const <Widget>[];
          return <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                l.nextAlarmRings(
                  remaining,
                  _formatPrayerTime(next.time.hour, next.time.minute),
                ),
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 12),
          ];
        }(),
        ..._prayerTimes.map((t) {
          final timeLabel = _formatPrayerTime(t.hour, t.minute);
          return Opacity(
            opacity: t.enabled ? 1.0 : 0.55,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.schedule, size: 18, color: AppColors.primary),
              title: Text(timeLabel,
                  style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
              trailing: Switch(
                value: t.enabled,
                onChanged: (v) => _togglePrayerTime(t, v),
              ),
              onLongPress: () => _confirmRemovePrayerTime(t),
            ),
          );
        }),
        const SizedBox(height: 8),
        if (_prayerTimes.isNotEmpty)
          Text(l.prayerTimesHint,
              style: AppTextStyles.bodySmall.copyWith(color: c.textMuted)),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity, height: 44,
          child: ElevatedButton.icon(
            onPressed: _addPrayerTime,
            icon: const Icon(Icons.alarm_add, size: 18, color: Colors.white),
            label: Text(l.addPrayerTime,
                style: AppTextStyles.labelLarge.copyWith(color: const Color(0xFF07090E), fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildSoundRow(l),
      ]),
    );
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatPrayerTime(int hour, int minute) {
    final l = AppLocalizations.of(context)!;
    final hh = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? l.eveningAbbr : l.morningAbbr;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$h12:$hh $period';
  }

  String? _remainingUntilNow(DateTime when) {
    final diff = when.difference(DateTime.now());
    if (diff.isNegative) return null;
    final l = AppLocalizations.of(context)!;
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    if (hours > 0) {
      return l.hoursAndMinutes(hours, minutes);
    }
    return l.minutesOnly(diff.inMinutes);
  }
}
