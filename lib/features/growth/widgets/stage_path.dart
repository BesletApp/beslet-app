import 'package:flutter/material.dart';

import '../../../core/services/growth_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// The journey as a path of five stages — seed, sprout, rooted, blooming,
/// fruiting. The vine stands where it stands; the path is grace, not a race.
/// Shown as pure dots and a single quiet line — see, not read.
class StagePath extends StatelessWidget {
  final VineStage stage;

  const StagePath({super.key, required this.stage});

  static const List<VineStage> _order = [
    VineStage.seed,
    VineStage.sprout,
    VineStage.rooted,
    VineStage.blooming,
    VineStage.fruiting,
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final currentIndex = _order.indexOf(stage);
    final reached = currentIndex < 0 ? 0 : currentIndex + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              for (var i = 0; i < _order.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= currentIndex
                          ? c.primary.withValues(alpha: 0.6)
                          : c.border.withValues(alpha: 0.4),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= currentIndex ? c.primary : c.cardElevated,
                    border: Border.all(
                      color: i <= currentIndex ? c.primary : c.border,
                      width: i == currentIndex ? 2 : 1,
                    ),
                  ),
                  child: i <= currentIndex
                      ? const Icon(Icons.check, size: 13, color: Color(0xFFFFFFFF))
                      : null,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                l.theSeasonChanged,
                style: t.labelSmall.copyWith(color: c.textMuted),
              ),
            ),
            Text(
              '${l.dayLabel} $reached / ${_order.length}',
              style: t.labelSmall.copyWith(color: c.textMuted, letterSpacing: 0.6),
            ),
          ],
        ),
      ],
    );
  }
}
