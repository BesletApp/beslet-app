import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChartSection extends ConsumerStatefulWidget {
  final Map<String, List<bool>> weeklyCompletions;
  final List<double> weeklyXp;
  final List<double> dailyXp;
  final bool isDark;
  final double? dailyGoal;
  final double? weeklyGoal;

  const ChartSection({
    super.key,
    required this.weeklyCompletions,
    required this.weeklyXp,
    required this.dailyXp,
    required this.isDark,
    this.dailyGoal,
    this.weeklyGoal,
  });

  @override
  ConsumerState<ChartSection> createState() => _ChartSectionState();
}

class _ChartSectionState extends ConsumerState<ChartSection> {
  bool _daily = true;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppColors.surface : AppColors.backgroundLight;
    final toggleBg =
        widget.isDark ? AppColors.card : AppColors.backgroundLight;
    final toggleActive = widget.isDark ? AppColors.primary : AppColors.primary;
    final toggleText = widget.isDark
        ? const Color(0xFF07090E)
        : AppColors.textPrimaryLight;
    final cardBorder =
        widget.isDark ? AppColors.border : AppColors.borderLightTheme;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: toggleBg,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _daily = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: _daily ? toggleActive : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Daily XP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                _daily ? toggleText : AppColors.textSecondary)),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _daily = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: !_daily ? toggleActive : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Weekly XP',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: !_daily
                                ? toggleText
                                : AppColors.textSecondary)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder, width: 0.5),
          ),
          child: _daily ? _buildDailyChart() : _buildWeeklyChart(),
        ),
      ],
    );
  }

  Widget _buildDailyChart() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = widget.dailyXp;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final ceiling = maxVal > 0 ? (maxVal / 20).ceil() * 20.0 : 100.0;
    final primaryText = widget.isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final mutedText = widget.isDark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;
    final gridColor =
        widget.isDark ? AppColors.border : AppColors.borderLightTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily XP earned',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryText)),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: ceiling,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ceiling / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: gridColor.withValues(alpha: 0.4),
                  strokeWidth: 0.5,
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (widget.dailyGoal != null && widget.dailyGoal! > 0)
                  HorizontalLine(
                    y: widget.dailyGoal!,
                    color: AppColors.primary,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.primary,
                      ),
                      labelResolver: (_) => 'goal ${widget.dailyGoal!.round()}',
                    ),
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[i],
                            style: TextStyle(
                                fontSize: 9, color: mutedText)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) {
                final isToday = i == DateTime.now().weekday - 1;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: i < values.length ? values[i] : 0,
                      color: isToday
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                  ],
                );
              }),
            ),
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    const labels = ['Wk1', 'Wk2', 'Wk3', 'Wk4'];
    final values = widget.weeklyXp;
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final ceiling = maxVal > 0 ? (maxVal / 100).ceil() * 100.0 : 100.0;
    final primaryText = widget.isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final mutedText = widget.isDark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;
    final gridColor =
        widget.isDark ? AppColors.border : AppColors.borderLightTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Weekly XP earned',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: primaryText)),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: ceiling,
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: ceiling / 4,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: gridColor.withValues(alpha: 0.4),
                  strokeWidth: 0.5,
                ),
              ),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (widget.weeklyGoal != null && widget.weeklyGoal! > 0)
                  HorizontalLine(
                    y: widget.weeklyGoal!,
                    color: AppColors.primary,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      style: TextStyle(
                        fontSize: 8,
                        color: AppColors.primary,
                      ),
                      labelResolver: (_) => 'goal ${widget.weeklyGoal!.round()}',
                    ),
                  ),
                ],
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[i],
                            style: TextStyle(
                                fontSize: 9, color: mutedText)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(values.length, (i) {
                final isCurrent = i == 0;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      color: isCurrent
                          ? AppColors.primaryLight
                          : AppColors.primary,
                      width: 24,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(5),
                        topRight: Radius.circular(5),
                      ),
                    ),
                  ],
                );
              }),
            ),
            duration: const Duration(milliseconds: 200),
          ),
        ),
      ],
    );
  }
}
