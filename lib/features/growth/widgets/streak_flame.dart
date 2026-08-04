import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/streak_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// The streak, carried with grace — a flame that remembers days of abiding,
/// never a number to defend.
class StreakFlame extends ConsumerWidget {
  const StreakFlame({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final streak = ref.watch(streakStateProvider).valueOrNull;

    final current = streak?.currentStreak ?? 0;
    final tokens = streak?.freezeTokens ?? 0;
    final atRisk = streak?.isAtRisk ?? false;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF8E26A), Color(0xFFE89B2E), Color(0xFFD96A2E)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.local_fire_department, color: Color(0xFF4A1D08), size: 26),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$current',
                    style: t.displayMedium.copyWith(color: c.primary, fontSize: 30),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      l.dayLabel,
                      style: t.labelSmall.copyWith(color: c.textMuted),
                    ),
                  ),
                ],
              ),
              Text(
                atRisk ? l.streakFlameGrace : l.streakFlameGentle,
                style: t.bodySmall.copyWith(color: c.textMuted),
              ),
              if (tokens > 0)
                Text(
                  '$tokens ${l.freezeChip}',
                  style: t.labelSmall.copyWith(color: AppColors.of(context).info),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
