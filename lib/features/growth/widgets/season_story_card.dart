import 'package:flutter/material.dart';

import '../../../core/services/growth_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/beslet_card.dart';

/// The season's story — the movement the journey is living through right now.
class SeasonStoryCard extends StatelessWidget {
  final JourneyMovement movement;
  final bool isAm;

  const SeasonStoryCard({super.key, required this.movement, required this.isAm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final title = GrowthContent.movementTitle(movement);
    final prose = GrowthContent.movementProse(movement);

    return BesletCard(
      variant: CardVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories, size: 18, color: AppColors.of(context).primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l.theSeason,
                style: t.labelLarge.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isAm ? title.am : title.en,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isAm ? prose.am : prose.en,
            style: t.bodyMedium.copyWith(color: c.textSecondary, height: 1.6),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            GrowthContent.movementVerse(movement),
            style: t.labelSmall.copyWith(
              color: AppColors.of(context).primary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
