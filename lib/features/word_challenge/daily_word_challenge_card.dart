import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/word_challenge_provider.dart';
import '../../core/services/widget_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import 'emphasized_verse_text.dart';

/// The Home anchor for the Word Challenge: today's verse, one tap away from
/// the full See & Hear → Build → Pray → Live-it-out journey, with a quiet
/// nudge when a review has come due.
class DailyWordChallengeCard extends ConsumerWidget {
  const DailyWordChallengeCard({super.key});

  static const List<Color> _masteryColors = [
    Color(0xFF9CBD8A),
    Color(0xFF6FA85A),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final challenge = ref.watch(todayWordChallengeProvider);
    final reviewDue = ref.watch(reviewDueCountProvider).valueOrNull ?? 0;

    final light = WidgetService.lightStateFor(DateTime.now());
    final lightTint = switch (light) {
      LampLight.dawn => const Color(0x14C8A96E),
      LampLight.noon => const Color(0x149FD0F0),
      LampLight.dusk => const Color(0x14E8965C),
      LampLight.night => const Color(0x148F8FD0),
    };

    return Column(
      children: [
        Divider(height: 1, thickness: 0.5, color: c.border.withValues(alpha: 0.15)),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/word-challenge'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              decoration: BoxDecoration(
                color: lightTint,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border.withValues(alpha: 0.15)),
              ),
              child: challenge.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                ),
                error: (_, __) => Center(child: Text(l.somethingWentWrong)),
                data: (v) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _MasteryPill(level: v.masteryLevel),
                        const Spacer(),
                        if (reviewDue > 0)
                          _ReviewPill(count: reviewDue)
                        else
                          Text(
                            v.reference,
                            style: AppTextStyles.of(context).labelSmall.copyWith(
                                  color: c.primary.withValues(alpha: 0.7),
                                  letterSpacing: 0.5,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    EmphasizedVerseText(
                      text: isAm ? (v.textAm ?? v.textEn) : v.textEn,
                      emphasize: !isAm,
                      style: isAm
                          ? AppTextStyles.of(context).bodyMedium.copyWith(
                              fontSize: 16,
                              height: 1.65,
                              color: c.textSecondary.withValues(alpha: 0.95),
                            )
                          : AppTextStyles.of(context).displaySmall.copyWith(
                              fontFamily: 'CormorantGaramond',
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                              fontSize: 18,
                              color: c.textSecondary.withValues(alpha: 0.85),
                            ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        textStyle: AppTextStyles.of(context).labelLarge,
                      ),
                      onPressed: () => context.push('/word-challenge'),
                      child: Text(l.startTodaysWord),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.enterThreshold,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.of(context).bodySmall.copyWith(
                            fontSize: 11,
                            color: c.textMuted,
                            decoration: TextDecoration.underline,
                            decorationColor: c.textMuted.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MasteryPill extends StatelessWidget {
  final int level;

  const _MasteryPill({required this.level});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = DailyWordChallengeCard._masteryColors[level.clamp(0, 2)];
    final label = switch (level) {
      1 => l.masteryGrowing,
      2 => l.masteryRooted,
      _ => l.masteryNew,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.of(context).bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPill extends StatelessWidget {
  final int count;

  const _ReviewPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Material(
      color: c.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push('/memory-garden'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                l.reviewDue(count),
                style: AppTextStyles.of(context).bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
