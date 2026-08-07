import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/prayer_provider.dart';
import '../../core/providers/prayer_rooms_provider.dart';
import '../../core/services/scene_event_bus.dart';
import '../../l10n/app_localizations.dart';

/// The inner room (Matthew 6:6). A full-screen threshold where the user turns
/// from the day into a single named presence before God. No numbers, no
/// chrome — just the room, a quietly breathing mark, and the simple verbs of
/// prayer: Begin, Step away, Return, Rest. An optional gentle time softly
/// calls the presence to a close; the room always lets you Continue or Rest.
class PrayerFocusScreen extends ConsumerStatefulWidget {
  final PrayerRoom room;
  const PrayerFocusScreen({super.key, required this.room});

  @override
  ConsumerState<PrayerFocusScreen> createState() => _PrayerFocusScreenState();
}

/// Gentle-time choices, in minutes. Picking none means open presence.
const List<int> _presets = [5, 10, 15, 20, 30];

class _PrayerFocusScreenState extends ConsumerState<PrayerFocusScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  DateTime? _runningSince;
  Duration _elapsed = Duration.zero;
  bool _isRunning = false;
  bool _showTime = false;
  Timer? _timer;

  // Optional gentle time. null = open presence.
  int? _gentleMinutes;
  int? _totalSeconds;
  int? _remainingSeconds;
  bool _arrival = false;

  late final AnimationController _breath;
  late final Animation<double> _breathScale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _breath = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _breathScale = Tween(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: _breath, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _breath.dispose();
    _timer?.cancel();
    _sleep();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _pausePresence();
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
    }
  }

  int get _feltSeconds => _runningSince != null
      ? _elapsed.inSeconds + DateTime.now().difference(_runningSince!).inSeconds
      : _elapsed.inSeconds;

  double? get _countdownFraction {
    final total = _totalSeconds;
    final remaining = _remainingSeconds;
    if (total == null || remaining == null || total == 0) return null;
    return (remaining / total).clamp(0.0, 1.0);
  }

  Future<void> _keepAwake() async {
    try {
      await WakelockPlus.enable();
    } catch (_) {
      // Some environments have no wakelock channel.
    }
  }

  Future<void> _sleep() async {
    try {
      await WakelockPlus.disable();
    } catch (_) {
      // Some environments have no wakelock channel.
    }
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds != null) {
        final next = _remainingSeconds! - 1;
        if (next <= 0) {
          _arrive();
          return;
        }
        setState(() => _remainingSeconds = next);
      } else {
        setState(() {});
      }
    });
  }

  void _begin() {
    final minutes = _gentleMinutes;
    setState(() {
      _isRunning = true;
      _runningSince = DateTime.now();
      _elapsed = Duration.zero;
      _arrival = false;
      _totalSeconds = minutes == null ? null : minutes * 60;
      _remainingSeconds = minutes == null ? null : minutes * 60;
    });
    _keepAwake();
    _tick();
    ref.read(prayerRoomNotifierProvider.notifier).touchRoom(widget.room.id);
  }

  void _arrive() {
    _timer?.cancel();
    _sleep();
    setState(() {
      _arrival = true;
      _isRunning = false;
      _runningSince = null;
      _remainingSeconds = 0;
    });
  }

  void _continueAfterArrival() {
    setState(() {
      _arrival = false;
      _gentleMinutes = null;
      _totalSeconds = null;
      _remainingSeconds = null;
      _isRunning = true;
      _runningSince = DateTime.now();
    });
    _keepAwake();
    _tick();
  }

  void _pausePresence() {
    _timer?.cancel();
    _sleep();
    setState(() {
      _elapsed = Duration(seconds: _feltSeconds);
      _runningSince = null;
      _isRunning = false;
    });
  }

  void _returnHere() {
    setState(() {
      _isRunning = true;
      _runningSince = DateTime.now();
    });
    _keepAwake();
    _tick();
  }

  void _rest() {
    _timer?.cancel();
    _sleep();
    final minutes = (_feltSeconds / 60).ceil().clamp(1, 999);
    ref.read(prayerNotifierProvider.notifier).logPrayer(minutes);
    ref.read(sceneEventBusProvider).emit(SceneEventType.water);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.prayerRestLogged,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: Color(0xFF07090E))),
      backgroundColor: AppColors.primary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
    Navigator.of(context).pop();
  }

  void _leave() {
    if (_isRunning) _pausePresence();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.close),
              color: c.textSecondary,
              tooltip: l.cancel,
              onPressed: _leave,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _showTime = !_showTime),
              icon: Icon(_showTime ? Icons.timer_off_outlined : Icons.timer_outlined,
                  size: 16, color: c.textMuted),
              label: Text(_showTime ? l.hideTime : l.revealTime,
                  style: AppTextStyles.of(context).bodySmall.copyWith(color: c.textMuted)),
            ),
            const SizedBox(width: 8),
          ]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _presenceMark(c),
                  const SizedBox(height: 28),
                  Text(
                    widget.room.name,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.of(context)
                        .displayMedium
                        .copyWith(fontSize: isAm ? 26 : 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.justBeStill,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.of(context)
                        .bodySmall
                        .copyWith(color: c.textMuted, fontStyle: FontStyle.italic),
                  ),
                  if (_showTime) ...[
                    const SizedBox(height: 16),
                    Text(
                      _formatTime(_feltSeconds),
                      style: AppTextStyles.of(context)
                          .bodyMedium
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildControls(l, c),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _presenceMark(ThemePalette c) {
    final mark = Container(
      width: 120, height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.gradientGoldSoft,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: _isRunning ? 0.7 : 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 30, spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
          child: Text(_isRunning ? '🕊️' : '🕯️', style: const TextStyle(fontSize: 40))),
    );
    final breathing = ScaleTransition(scale: _breathScale, child: mark);
    final fraction = _countdownFraction;
    if (fraction == null) return breathing;
    return SizedBox(
      width: 136, height: 136,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 136, height: 136,
          child: CircularProgressIndicator(
            value: fraction,
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
            color: AppColors.primary,
            backgroundColor: c.border,
          ),
        ),
        breathing,
      ]),
    );
  }

  Widget _buildControls(AppLocalizations l, ThemePalette c) {
    if (_arrival) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(children: [
          Text(l.timeComplete, style: AppTextStyles.of(context).displaySmall),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _continueAfterArrival,
                  icon: const Icon(Icons.play_arrow, color: Color(0xFF07090E)),
                  label: Text(l.continueStill,
                      style: AppTextStyles.of(context).labelLarge.copyWith(color: Color(0xFF07090E), fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _rest,
                  icon: const Icon(Icons.stop),
                  label: Text(l.restNow,
                      style: AppTextStyles.of(context).labelLarge.copyWith(fontSize: 14)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.textSecondary,
                    side: BorderSide(color: c.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      );
    }

    final idle = !_isRunning && _runningSince == null;
    if (idle) {
      return Column(children: [
        Text(l.prayerTimeLabel,
            style: AppTextStyles.of(context).labelSmall.copyWith(color: c.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
          children: [
            ChoiceChip(
              label: Text(l.noTimer, style: AppTextStyles.of(context).bodySmall),
              selected: _gentleMinutes == null,
              onSelected: (_) => setState(() => _gentleMinutes = null),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundColor: c.surface,
              side: BorderSide(
                  color: _gentleMinutes == null ? AppColors.primary : c.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            for (final m in _presets)
              ChoiceChip(
                label: Text('$m', style: AppTextStyles.of(context).bodySmall),
                selected: _gentleMinutes == m,
                onSelected: (_) => setState(() => _gentleMinutes = m),
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                backgroundColor: c.surface,
                side: BorderSide(
                    color: _gentleMinutes == m ? AppColors.primary : c.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton.icon(
            onPressed: _begin,
            icon: const Icon(Icons.play_arrow, color: Color(0xFF07090E)),
            label: Text(l.beginPresence,
                style: AppTextStyles.of(context).labelLarge.copyWith(color: Color(0xFF07090E), fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ]);
    }

    final primaryAction = _isRunning ? _pausePresence : _returnHere;
    final primaryLabel = _isRunning ? l.stepAway : l.returnHere;
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: primaryAction,
            icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: const Color(0xFF07090E)),
            label: Text(primaryLabel,
                style: AppTextStyles.of(context).labelLarge.copyWith(color: const Color(0xFF07090E), fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _rest,
            icon: const Icon(Icons.stop),
            label: Text(l.restNow,
                style: AppTextStyles.of(context).labelLarge.copyWith(fontSize: 14)),
            style: OutlinedButton.styleFrom(
              foregroundColor: c.textSecondary,
              side: BorderSide(color: c.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    ]);
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
