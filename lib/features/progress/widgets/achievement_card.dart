import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AchievementCard extends StatelessWidget {
  final String icon;
  final String name;
  final String subtitle;
  final bool unlocked;
  final bool isDark;

  const AchievementCard({
    super.key,
    required this.icon,
    required this.name,
    required this.subtitle,
    required this.unlocked,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? AppColors.card : AppColors.cardLight;
    final primaryText = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final mutedText = isDark ? AppColors.textMuted : AppColors.textMutedLight;
    final veryMuted = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? bg : bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.border : AppColors.borderLightTheme,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surface
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 17)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: unlocked
                            ? primaryText
                            : mutedText)),
                const SizedBox(height: 1),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 10,
                        color: unlocked ? veryMuted : mutedText)),
              ],
            ),
          ),
          Icon(
            unlocked ? Icons.check_circle : Icons.lock,
            size: 18,
            color: unlocked
                ? AppColors.primary
                : mutedText,
          ),
        ],
      ),
    );
  }
}
