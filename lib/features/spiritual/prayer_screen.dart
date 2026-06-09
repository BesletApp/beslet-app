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
  ({int hour, int minute})? _reminderTime;
  String? _soundName;
  bool _usingCustomSound = false;
  bool _alarmActive = false;
  Timer? _alarmCheckTimer;

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadReminder();
    _startAlarmCheck();
  }
  @override void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _alarmCheckTimer?.cancel();
    WakelockPlus.disable();
    _noteController.dispose();
    super.dispose();
  }

  void _startAlarmCheck() {
    _alarmCheckTimer?.cancel();
    _checkAlarmActive();
    _alarmCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkAlarmActive());
  }

  Future<void> _checkAlarmActive() async {
    final active = await PrayerReminderService.isAlarmActive();
    if (mounted && active != _alarmActive) {
      setState(() { _alarmActive = active; });
    }
  }

  Future<void> _loadReminder() async {
    final time = await PrayerReminderService.getReminderTime();
    final soundName = await PrayerAlarmSoundService.getSoundDisplayName();
    final custom = await PrayerAlarmSoundService.hasCustomSound();
    if (mounted) {
      setState(() {
        _reminderTime = time;
        _soundName = soundName;
        _usingCustomSound = custom;
      });
    }
  }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _checkAlarmActive();
      if (_isRunning && _startTime != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
      }
    }
  }

  int get _elapsedSeconds => _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;

  void _logNow() {
    final note = _noteController.text.trim();
    ref.read(prayerNotifierProvider.notifier).logPrayer(0, note: note.isEmpty ? null : note);
    _noteController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('+15 XP — Prayer logged!', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF07090E))),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
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
    setState(() { _startTime = null; _isRunning = false; _timerExpanded = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('+15 XP — Prayer logged!', style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF07090E))),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
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
        backgroundColor: AppColors.card,
        title: Text(isAm ? 'ፍቃድ ያስፈልጋል' : 'Permission needed', style: AppTextStyles.labelLarge),
        content: Text(
          status == PrayerAlarmPermissionStatus.exactAlarmDenied
              ? (isAm ? '«Alarms & reminders» ያንቁ።' : 'Turn on "Alarms & reminders".')
              : (isAm ? 'ማሳሰቢያዎችን ያንቁ።' : 'Enable notifications for Beslet.'),
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
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

  Future<void> _setReminder() async {
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final permission = await PrayerReminderService.ensurePermissions();
    if (permission != PrayerAlarmPermissionStatus.granted) {
      await _handlePermissionDenied(permission);
      return;
    }
    try {
      await PrayerReminderService.schedulePrayerReminder(time.hour, time.minute);
      _showSnack('Prayer reminder set! 🙏');
    } on PrayerReminderException catch (e) {
      _showSnack(e.message, isError: true);
    } catch (e) {
      _showSnack('Failed: $e', isError: true);
    }
    await _loadReminder();
  }

  Future<void> _pickAlarmSound() async {
    try {
      await PrayerAlarmSoundService.pickAndSaveFromPhone();
      if (_reminderTime != null) await PrayerReminderService.rescheduleAfterSoundChange();
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
    if (_reminderTime != null) await PrayerReminderService.rescheduleAfterSoundChange();
    _showSnack('Using default alarm tone');
    await _loadReminder();
  }

  Future<void> _testAlarm() async {
    final permission = await PrayerReminderService.ensurePermissions();
    if (permission != PrayerAlarmPermissionStatus.granted) {
      await _handlePermissionDenied(permission);
      return;
    }
    try {
      await PrayerReminderService.testAlarmNow();
      _showSnack('Test alarm in 3 seconds — turn volume up!');
    } on PrayerReminderException catch (e) {
      _showSnack(e.message, isError: true);
    }
  }

  Widget _buildSoundRow(AppLocalizations l) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final toneLabel = _usingCustomSound
        ? (_soundName ?? (isAm ? 'ብጁ ድምፅ' : 'Custom tone'))
        : (isAm ? 'ነባሪ የማንቂያ ድምፅ' : 'Default alarm tone');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(isAm ? 'የማንቂያ ድምፅ' : 'Alarm tone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.music_note, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Expanded(child: Text(toneLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickAlarmSound,
              icon: const Icon(Icons.library_music, size: 16),
              label: Text(isAm ? 'ከስልክ ምረጥ' : 'From phone', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          if (_usingCustomSound)
            Expanded(
              child: OutlinedButton(
                onPressed: _useDefaultSound,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary, side: const BorderSide(color: AppColors.border), padding: const EdgeInsets.symmetric(vertical: 10)),
                child: Text(isAm ? 'ነባሪ' : 'Default', style: AppTextStyles.bodySmall),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        if (_alarmActive)
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: () async {
                await PrayerReminderService.stopAlarmNow();
                await _checkAlarmActive();
              },
              icon: const Icon(Icons.notifications_off, size: 18, color: Colors.white),
              label: Text(isAm ? 'ማንቂያ አቁም' : 'Stop alarm', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        else
          SizedBox(
            width: double.infinity, height: 40,
            child: OutlinedButton.icon(
              onPressed: _testAlarm,
              icon: const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.primary),
              label: Text(isAm ? 'አሁን ሙከራ አድርግ' : 'Test alarm now', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4))),
            ),
          ),
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
            filled: true, fillColor: AppColors.card,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          maxLines: 2, minLines: 1,
        ),
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => setState(() => _timerExpanded = !_timerExpanded),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(_timerExpanded ? Icons.expand_less : Icons.timer_outlined, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(l.trackTime, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ]),
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
        color: AppColors.card,
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
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
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
                    color: prayed ? AppColors.success.withValues(alpha: 0.2) : AppColors.border,
                    border: Border.all(color: prayed ? AppColors.success : AppColors.borderLight, width: 2),
                  ),
                  child: Center(child: prayed
                    ? const Icon(Icons.check, size: 18, color: AppColors.success)
                    : Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMuted))),
                ),
                const SizedBox(height: 6),
                Text(dayLabels[i], style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.textMuted)),
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
    final reminderTime = _reminderTime;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.alarm, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.prayerReminder, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        if (reminderTime != null) ...[
          Text(AppLocalizations.of(context)!.dailyAt(TimeOfDay(hour: reminderTime.hour, minute: reminderTime.minute).format(context)),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _setReminder,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(AppLocalizations.of(context)!.change, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: TextButton.icon(
                onPressed: () async {
                  await PrayerReminderService.cancelPrayerReminder();
                  await _loadReminder();
                },
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                label: Text(AppLocalizations.of(context)!.removeReminder, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ),
            ),
          ]),
        ] else ...[
          Text(AppLocalizations.of(context)!.notSet, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton.icon(
              onPressed: _setReminder,
              icon: const Icon(Icons.alarm_add, size: 18, color: Colors.white),
              label: Text(AppLocalizations.of(context)!.setReminder, style: AppTextStyles.labelLarge.copyWith(color: Color(0xFF07090E), fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
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
}
