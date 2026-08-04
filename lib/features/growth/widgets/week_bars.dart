import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/growth_streams_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Seven days of living — how full each day was, at a glance. The bars are
/// silhouettes of rhythm, not grades.
class WeekBars extends ConsumerWidget {
  const WeekBars({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final week = ref.watch(weekLivingProvider).valueOrNull ?? List<int>.filled(7, 0);

    final today = DateTime.now();
    final labels = List.generate(7, (i) {
      final d = today.subtract(Duration(days: 6 - i));
      return switch (d.weekday) {
        1 => 'M',
        2 => 'T',
        3 => 'W',
        4 => 'T',
        5 => 'F',
        6 => 'S',
        _ => 'S',
      };
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final value = i < week.length ? week[i] : 0;
        final isToday = i == 6;
        final fraction = value / 5;
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                height: 6 + 76 * fraction,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      c.primary.withValues(alpha: 0.25 + 0.55 * fraction),
                      c.primary.withValues(alpha: 0.55 * fraction + 0.1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: t.labelSmall.copyWith(
                  color: isToday ? c.primary : c.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
