import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class StreakCard extends StatelessWidget {
  final int streak;
  final int bestStreak;
  final List<bool> weekDays;
  final double sanctityScore;
  final bool isDark;
  final bool isBroken;
  final VoidCallback? onRepair;

  const StreakCard({
    super.key,
    required this.streak,
    required this.bestStreak,
    required this.weekDays,
    required this.sanctityScore,
    required this.isDark,
    this.isBroken = false,
    this.onRepair,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final bg = isDark ? AppColors.cardElevated : AppColors.cardLight;
    final dotDone = isDark ? AppColors.progressGreen : AppColors.progressGreen;
    final dotMiss = isDark ? AppColors.border : AppColors.borderLightTheme;
    final primaryText = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final secondaryText = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final mutedText = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final border = isDark ? AppColors.border : AppColors.borderLightTheme;

    final dayLabels = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: labels
          .map((l) => SizedBox(
                width: 30,
                child: Text(l,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: mutedText)),
              ))
          .toList(),
    );
    final dayDots = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: weekDays
          .map((done) => Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? dotDone : dotMiss,
                ),
                child: done
                    ? Icon(Icons.check,
                        size: 13, color: isDark ? bg : bg)
                    : null,
              ))
          .toList(),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text('Consistency Streak',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$streak',
                        style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                            height: 1)),
                    const SizedBox(height: 2),
                    Text('days',
                        style: TextStyle(
                            fontSize: 14,
                            color: secondaryText)),
                    const SizedBox(height: 8),
                    Text('Best: $bestStreak days',
                        style: TextStyle(
                            fontSize: 11,
                            color: mutedText)),
                    if (isBroken) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.replay, size: 14),
                          label: const Text('Repair Streak',
                              style: TextStyle(fontSize: 12)),
                          onPressed: onRepair,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warningOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [dayLabels, const SizedBox(height: 2), dayDots],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text('Sanctity score today',
                    style: TextStyle(
                        fontSize: 11, color: mutedText)),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text('${(sanctityScore * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
