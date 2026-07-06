import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/streak_service.dart';

class StreakBar extends StatelessWidget {
  final int currentStreak;
  final int freezeTokens;
  final List<bool> weekDays;
  final bool isAtRisk;
  final bool isBroken;
  final VoidCallback? onRepair;

  const StreakBar({
    super.key,
    required this.currentStreak,
    required this.freezeTokens,
    required this.weekDays,
    this.isAtRisk = false,
    this.isBroken = false,
    this.onRepair,
  });

  @override
  Widget build(BuildContext context) {
    final color = StreakService.flameColor(currentStreak);
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text('🔥', style: TextStyle(fontSize: currentStreak >= 90 ? 22 : 18)),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('$currentStreak-day streak',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
          if (freezeTokens > 0)
            Text('❄️ $freezeTokens freeze${freezeTokens != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
        ]),
        const Spacer(),
        if (isBroken)
          TextButton.icon(
            icon: const Icon(Icons.replay, size: 14),
            label: const Text('Repair', style: TextStyle(fontSize: 11)),
            onPressed: onRepair,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              foregroundColor: AppColors.warning,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        if (!isBroken)
          ...weekDays.asMap().entries.map((e) {
            final done = e.value;
            return Container(
              width: 20, height: 20, margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? color : AppColors.border.withValues(alpha: 0.4),
              ),
              alignment: Alignment.center,
              child: done
                  ? Icon(Icons.check, size: 11, color: Colors.white)
                  : Text(labels[e.key], style: TextStyle(fontSize: 8, color: AppColors.textMuted)),
            );
          }),
      ]),
    );
  }
}
