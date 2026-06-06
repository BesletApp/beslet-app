import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/prayer_provider.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});
  @override ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  DateTime? _startTime;
  Timer? _timer;
  bool _isRunning = false;
  late TabController _tabController;

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _tabController = TabController(length: 2, vsync: this); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); _tabController.dispose(); WakelockPlus.disable(); super.dispose(); }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && _isRunning && _startTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
    }
  }

  int get _elapsedSeconds => _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;

  void _startTimer() {
    setState(() { _isRunning = true; _startTime = DateTime.now(); });
    WakelockPlus.enable();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    WakelockPlus.disable();
    if (_isRunning) {
      final minutes = (_elapsedSeconds / 60).ceil().clamp(1, 999);
      ref.read(prayerNotifierProvider.notifier).logPrayer(minutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Logged $minutes minutes of prayer!', style: AppTextStyles.bodyMedium),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        ));
      }
    }
    setState(() { _startTime = null; _isRunning = false; });
  }

  @override Widget build(BuildContext context) {
    final todayLog = ref.watch(todayPrayerLogProvider);
    final weekMinutes = ref.watch(prayerMinutesThisWeekProvider);
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: const Text('Prayer'), bottom: TabBar(
        controller: _tabController, tabs: const [Tab(text: 'Pray'), Tab(text: 'History')],
        indicatorColor: AppColors.primary, labelColor: AppColors.primary, unselectedLabelColor: AppColors.textMuted,
      )),
      body: TabBarView(controller: _tabController, children: [
        _buildPrayTab(todayLog, weekMinutes),
        _buildHistoryTab(),
      ]),
    );
  }

  Widget _buildPrayTab(AsyncValue<PrayerLog?> todayLog, AsyncValue<int> weekMinutes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: AppColors.gradientGoldSoft,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            const Text('🙏', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(_formatTime(_elapsedSeconds), style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontSize: 56)),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (!_isRunning)
                _timerButton('Start', Icons.play_arrow, AppColors.success, _startTimer)
              else ...[
                _timerButton('Stop', Icons.stop, AppColors.error, _stopTimer),
                const SizedBox(width: 16),
                _timerButton('Reset', Icons.refresh, AppColors.textMuted, () { _timer?.cancel(); WakelockPlus.disable(); setState(() { _startTime = null; _isRunning = false; }); }),
              ],
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          _statCard('This Week', '${weekMinutes.valueOrNull ?? 0} min', Icons.timer, AppColors.primary),
          const SizedBox(width: 12),
          _statCard('Today', todayLog.valueOrNull != null ? '${todayLog.valueOrNull!.minutes} min' : 'Not yet', Icons.check_circle, AppColors.success),
        ]),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Weekly Goal', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            const SizedBox(height: 8),
            Text('"Pray without ceasing." — 1 Thessalonians 5:17', style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (weekMinutes.valueOrNull ?? 0) / 30.0,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text('Goal: 30 min / week', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHistoryTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Text('This Week\'s Prayer', style: AppTextStyles.displaySmall),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: ref.watch(prayerWeeklyProvider).when(
            data: (weeklyData) {
              final days = weeklyData.map((d) => d['dayName'] as String).toList();
              final values = weeklyData.map((d) => (d['prayerMinutes'] as int).toDouble()).toList();
              final maxY = values.isEmpty ? 10.0 : values.reduce((a, b) => a > b ? a : b).clamp(5.0, double.infinity) + 5.0;
              return BarChart(BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: List.generate(values.length, (i) => BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: values[i], color: AppColors.primary, width: 16.0, borderRadius: const BorderRadius.all(Radius.circular(4))),
                ])),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v, _) => Text('${v.toInt()}m', style: AppTextStyles.bodySmall.copyWith(fontSize: 10)))),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (i, _) => Text(days[i.toInt()], style: AppTextStyles.bodySmall.copyWith(fontSize: 10)))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: AppColors.border, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
              ));
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
      ]),
    );
  }

  Widget _timerButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.5))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: color, size: 20), const SizedBox(width: 8), Text(label, style: AppTextStyles.labelLarge.copyWith(color: color))]),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
          Text(title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
