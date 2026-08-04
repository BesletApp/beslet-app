import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/soul_log_provider.dart';
import '../../../core/services/growth_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/beslet_card.dart';

/// Weather of the heart — a gentle, one-tap way to log the day's mood. The sky
/// of the Vineyard responds to it; nothing is scored.
class WeatherCard extends ConsumerWidget {
  final int? mood;
  final bool isAm;

  const WeatherCard({super.key, required this.mood, required this.isAm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;

    return BesletCard(
      variant: CardVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_outlined, size: 18, color: AppColors.of(context).primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l.weatherOfTheHeart,
                style: t.labelLarge.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              for (var m = 1; m <= 5; m++) ...[
                Expanded(child: _moodButton(context, ref, m, mood == m)),
                if (m < 5) const SizedBox(width: AppSpacing.sm),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _moodButton(BuildContext context, WidgetRef ref, int mood, bool selected) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final weather = GrowthContent.weatherGlyph(mood);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => ref.read(soulLogNotifierProvider.notifier).logCheckIn(mood),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.of(context).primary.withValues(alpha: 0.12) : c.cardElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.of(context).primary : c.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            children: [
              Text(weather.glyph, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 2),
              Text(
                isAm ? weather.labelAm : weather.labelEn,
                style: t.labelSmall.copyWith(
                  color: selected ? AppColors.of(context).primary : c.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
