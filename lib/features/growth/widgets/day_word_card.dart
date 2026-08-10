import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/audio_player_provider.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/beslet_card.dart';

/// The day's Word — the lamp of the Vine. Never a task; just the Lamp's light.
class DayWordCard extends ConsumerWidget {
  final Scripture verse;
  final bool isAm;

  const DayWordCard({super.key, required this.verse, required this.isAm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final text = isAm ? (verse.textAm ?? verse.text) : verse.text;
    final reference =
        isAm ? ScriptureService.amharicReference(verse.reference) : verse.reference;

    return BesletCard(
      variant: CardVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book, size: 18, color: AppColors.of(context).primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l.daysWord,
                style: t.labelLarge.copyWith(color: c.textSecondary),
              ),
              const Spacer(),
              if (!isAm)
                TextButton.icon(
                  onPressed: () => ref
                      .read(audioPlayerProvider.notifier)
                      .speakVerse(text, isAmharic: isAm),
                  icon: Icon(Icons.volume_up, size: 16, color: AppColors.of(context).primary),
                  label: Text(l.listen),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.of(context).primary,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: t.bodyMedium.copyWith(
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            reference,
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
