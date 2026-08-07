import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/providers/prayer_rooms_provider.dart';
import '../../core/providers/daily_flow_provider.dart';
import '../../core/providers/scripture_provider.dart';
import '../../core/services/prayer_reminder_service.dart';
import '../../core/services/prayer_alarm_sound_service.dart';
import '../../core/services/scene_event_bus.dart';
import '../growth/widgets/mini_vine.dart';
import '../spiritual/widgets/prayer_room_tile.dart';
import 'prayer_focus_screen.dart';
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
    final timeLabel = TimeOfDay(hour: t.hour, minute: t.minute).format(context);
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
          MiniVine(
            seed: 901,
            emphasis: MiniVineEmphasis.water,
            eventSource: ref.read(sceneEventBusProvider),
          ),
          const SizedBox(height: 20),
          _buildRoomsSection(l),
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

  /// The threshold: named rooms of prayer, each a place to turn into His
  /// presence. The day's reading stays anchored above them — prayer is the
  /// Word become a conversation (never a gate).
  Widget _buildRoomsSection(AppLocalizations l) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final c = AppColors.of(context);
    final plan = ref.watch(todayBiblePlanProvider);
    final bibleDone = ref.watch(dailyFlowProvider).bibleDone;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.door_front_door_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.roomsOfPrayer, style: AppTextStyles.of(context).labelLarge.copyWith(color: AppColors.primary)),
          ),
          IconButton(
            onPressed: _showAddRoomSheet,
            icon: const Icon(Icons.add, size: 20, color: AppColors.primary),
            tooltip: l.newRoom,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ]),
        Text(
          '${l.prayWhatYouRead} — ${isAm ? plan.labelAm : plan.labelEn}',
          style: AppTextStyles.of(context).bodySmall.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!bibleDone) ...[
          const SizedBox(height: 4),
          Text(
            '✨ ${l.beginWithWord}',
            style: AppTextStyles.of(context).bodySmall.copyWith(
                  fontSize: 11, color: AppColors.primary, fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 12),
        _roomsList(l),
      ]),
    );
  }

  Widget _roomsList(AppLocalizations l) {
    final rooms = ref.watch(prayerRoomsProvider);
    return rooms.when(
      data: (list) => Column(children: [
        for (final room in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: PrayerRoomTile(
              room: room,
              onTap: () => _enterRoom(room),
              onLongPress: () => _showRoomActionsSheet(room),
            ),
          ),
      ]),
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox(),
    );
  }

  void _enterRoom(PrayerRoom room) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PrayerFocusScreen(room: room)),
    );
  }

  Future<void> _showAddRoomSheet() async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final nameController = TextEditingController();
    var selectedGroup = PrayerRoomGroup.personal;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.card,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.newRoom, style: AppTextStyles.of(context).labelLarge.copyWith(color: AppColors.primary)),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                autofocus: true,
                style: AppTextStyles.of(context).bodyMedium,
                decoration: InputDecoration(
                  hintText: l.roomNamePlaceholder,
                  hintStyle: AppTextStyles.of(context).bodySmall,
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _createRoom(ctx, nameController, selectedGroup),
              ),
              const SizedBox(height: 16),
              Text(l.roomKind, style: AppTextStyles.of(context).bodySmall.copyWith(color: c.textMuted)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final g in PrayerRoomGroup.all)
                  ChoiceChip(
                    label: Text(prayerRoomGroupLabel(l, g), style: AppTextStyles.of(context).bodySmall),
                    selected: selectedGroup == g,
                    onSelected: (_) => setSheetState(() => selectedGroup = g),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundColor: c.surface,
                    side: BorderSide(
                        color: selectedGroup == g ? AppColors.primary : c.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _createRoom(ctx, nameController, selectedGroup),
                  icon: const Icon(Icons.add, color: Color(0xFF07090E)),
                  label: Text(l.newRoom,
                      style: AppTextStyles.of(context).labelLarge.copyWith(color: Color(0xFF07090E))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    nameController.dispose();
  }

  Future<void> _createRoom(
      BuildContext sheetCtx, TextEditingController ctrl, String group) async {
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    await ref.read(prayerRoomNotifierProvider.notifier).addRoom(name, group);
    if (!sheetCtx.mounted) return;
    Navigator.of(sheetCtx).pop();
    if (!mounted) return;
    _showSnack(AppLocalizations.of(context)!.roomCreated);
  }

  Future<void> _showRoomActionsSheet(PrayerRoom room) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            title: Text(room.name,
                style: AppTextStyles.of(context).displaySmall.copyWith(fontSize: 18)),
            subtitle: Text(prayerRoomGroupLabel(l, room.group),
                style: AppTextStyles.of(context).bodySmall),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
            title: Text(l.renameRoom, style: AppTextStyles.of(context).bodyMedium),
            onTap: () {
              Navigator.pop(ctx);
              _renameRoom(room);
            },
          ),
          ListTile(
            leading: const Icon(Icons.drive_file_move_outline, color: AppColors.primary),
            title: Text(l.moveRoomAction, style: AppTextStyles.of(context).bodyMedium),
            onTap: () {
              Navigator.pop(ctx);
              _moveRoom(room);
            },
          ),
          ListTile(
            leading: const Icon(Icons.back_hand_outlined, color: AppColors.error),
            title: Text(l.letGoRoom,
                style: AppTextStyles.of(context).bodyMedium.copyWith(color: AppColors.error)),
            onTap: () {
              Navigator.pop(ctx);
              _letGoRoom(room);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _renameRoom(PrayerRoom room) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final controller = TextEditingController(text: room.name);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(l.renameRoom, style: AppTextStyles.of(context).labelLarge),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.of(context).bodyMedium,
          decoration: InputDecoration(
            hintText: l.roomNamePlaceholder,
            hintStyle: AppTextStyles.of(context).bodySmall,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.save, style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    final name = controller.text.trim();
    controller.dispose();
    if (saved == true && name.isNotEmpty) {
      await ref.read(prayerRoomNotifierProvider.notifier).renameRoom(room.id, name);
    }
  }

  Future<void> _moveRoom(PrayerRoom room) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    var selectedGroup = room.group;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: c.card,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.moveRoomAction,
                    style: AppTextStyles.of(context).labelLarge.copyWith(color: AppColors.primary)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final g in PrayerRoomGroup.all)
                    ChoiceChip(
                      label: Text(prayerRoomGroupLabel(l, g),
                          style: AppTextStyles.of(context).bodySmall),
                      selected: selectedGroup == g,
                      onSelected: (_) => setSheetState(() => selectedGroup = g),
                      selectedColor: AppColors.primary.withValues(alpha: 0.2),
                      backgroundColor: c.surface,
                      side: BorderSide(
                          color: selectedGroup == g ? AppColors.primary : c.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                ]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await ref.read(prayerRoomNotifierProvider.notifier)
                          .moveRoom(room.id, selectedGroup);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l.save,
                        style: AppTextStyles.of(context).labelLarge.copyWith(color: Color(0xFF07090E))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _letGoRoom(PrayerRoom room) async {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(l.letGoRoom, style: AppTextStyles.of(context).labelLarge),
        content: Text(l.roomRemoved, style: AppTextStyles.of(context).bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.letGoRoom, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(prayerRoomNotifierProvider.notifier).deleteRoom(room.id);
      if (mounted) _showSnack(l.roomRemoved);
    }
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
        ..._prayerTimes.map((t) {
          final timeLabel = TimeOfDay(hour: t.hour, minute: t.minute).format(context);
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
}
