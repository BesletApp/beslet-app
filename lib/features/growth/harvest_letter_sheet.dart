import 'package:flutter/material.dart';

import '../../../core/services/growth_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

enum HarvestChoice { harvest, continueAbiding }

/// The Harvest Letter — a letter composed from the user's own planted words.
/// No grades, no numbers; only what they wrote. From here they may harvest
/// (a moment, never a verdict) or simply continue abiding.
Future<HarvestChoice?> showHarvestLetterSheet(
  BuildContext context, {
  required List<String> answers,
  required JourneyMovement movement,
  required bool isAm,
}) {
  return showModalBottomSheet<HarvestChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HarvestLetterSheet(answers: answers, movement: movement, isAm: isAm),
  );
}

class _HarvestLetterSheet extends StatelessWidget {
  final List<String> answers;
  final JourneyMovement movement;
  final bool isAm;

  const _HarvestLetterSheet({required this.answers, required this.movement, required this.isAm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final letter = GrowthContent.harvestLetter(answers, movement, isAm: isAm);

    return SafeArea(
      top: false,
      child: Material(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: Text(
                  l.theHarvest,
                  style: t.displaySmall,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: c.cardElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.of(context).primary.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      letter,
                      style: t.bodyMedium.copyWith(height: 1.7),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(HarvestChoice.continueAbiding),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.of(context).primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.of(context).primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l.continueAbiding),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(HarvestChoice.harvest),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.of(context).primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l.harvestVerb),
                    ),
                  ),                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
