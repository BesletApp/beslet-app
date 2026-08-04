import 'package:flutter/material.dart';

import '../../../core/services/growth_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/beslet_card.dart';

/// A Scripture encouragement that responds to the weather of the heart —
/// gentle words for a storm, hope for a cloud, gladness for a clear sky.
class EncouragementCard extends StatelessWidget {
  final int day;
  final int? mood;
  final bool isAm;

  const EncouragementCard({super.key, required this.day, required this.mood, required this.isAm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final e = GrowthContent.encouragementFor(day, mood);

    return BesletCard(
      variant: CardVariant.secondary,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            mood != null && mood! <= 2 ? Icons.wb_twilight : Icons.light_mode_outlined,
            size: 20,
            color: AppColors.of(context).primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isAm ? e.am : e.en,
              style: t.bodyMedium.copyWith(
                color: c.textSecondary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
