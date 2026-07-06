import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/scripture_service.dart';

class PhaseBar extends StatelessWidget {
  final int day;
  final int phaseIdx;
  final List<String> phaseNames;
  final bool isAm;
  final List<BiblePlanEntry> plan;
  final int totalDays;
  final int phaseCount;
  final void Function(int day)? onDaySelected;

  const PhaseBar({
    super.key,
    required this.day,
    required this.phaseIdx,
    required this.phaseNames,
    required this.isAm,
    required this.plan,
    this.totalDays = 90,
    this.phaseCount = 4,
    this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    final daysPerPhase = totalDays ~/ phaseCount;
    final phaseColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF6F00),
      const Color(0xFF9C27B0),
    ];

    // Calculate which days fall in the current week (7 days centered on current day)
    final weekStart = ((day - 4) ~/ 7) * 7 + 1;
    final weekDays = List.generate(7, (i) => weekStart + i).where((d) => d >= 1 && d <= totalDays).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                isAm ? 'የ$totalDays ቀን እቅድ' : '$totalDays-Day Plan',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                isAm ? 'ቀን $day ከ$totalDays' : 'Day $day of $totalDays',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(phaseCount, (i) {
              final active = i == phaseIdx;
              final done = i < phaseIdx;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < phaseCount - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: done ? phaseColors[i] : (active ? phaseColors[i].withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(phaseCount, (i) {
              final active = i == phaseIdx;
              final start = i * daysPerPhase + 1;
              final end = i == phaseCount - 1 ? totalDays : (i + 1) * daysPerPhase;
              return Expanded(
                child: Text(
                  '${phaseNames[i]}\n${isAm ? "ቀን $start-$end" : "D$start-$end"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 9,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                isAm ? 'ይህ ሳምንት' : 'This Week',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary, letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekDays.map((d) {
              final isCurrentDay = d == day;
              final isEarlierDay = d < day;
              final phaseForDay = ScriptureService.getPhase(d);
              return GestureDetector(
                onTap: () => onDaySelected?.call(d),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAm ? _amDayAbbr(d) : ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][(d - 1) % 7],
                      style: TextStyle(
                        fontFamily: 'Inter', fontSize: 8,
                        color: isCurrentDay ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEarlierDay ? phaseColors[phaseForDay].withValues(alpha: 0.3) : (isCurrentDay ? phaseColors[phaseIdx] : AppColors.border.withValues(alpha: 0.2)),
                        border: Border.all(
                          color: isCurrentDay ? phaseColors[phaseIdx] : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$d',
                        style: TextStyle(
                          fontFamily: 'Inter', fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isEarlierDay ? AppColors.textPrimary : (isCurrentDay ? Colors.white : AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _amDayAbbr(int d) {
    const abbrs = ['ሰኞ', 'ማክ', 'ረቡ', 'ሐሙ', 'አርብ', 'ቅዳ', 'እሁድ'];
    return abbrs[(d - 1) % 7];
  }
}
