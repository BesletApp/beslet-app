import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/word_challenge_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';

/// Every verse the user has worked on, laid out like a quiet garden. Rooted
/// verses sit at the top; any verse whose gentle review has come due gets a
/// small nudge.
class MemoryGardenScreen extends ConsumerWidget {
  const MemoryGardenScreen({super.key});

  static const List<Color> _masteryColors = [
    Color(0xFF9CBD8A),
    Color(0xFF6FA85A),
    Color(0xFF2E7D32),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cCol = AppColors.of(context);
    final garden = ref.watch(allWordChallengesProvider);
    final rooted = ref.watch(rootedVerseCountProvider).valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l.memoryGarden),
      ),
      body: SafeArea(
        child: garden.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l.somethingWentWrong)),
          data: (verses) {
            if (verses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.eco, size: 56, color: _masteryColors.first),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l.memoryGardenEmpty,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.of(context).bodyMedium.copyWith(
                              color: cCol.textSecondary,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final sorted = [...verses]
              ..sort((a, b) {
                final m = b.masteryLevel.compareTo(a.masteryLevel);
                if (m != 0) return m;
                return (b.lastCompletedDate ?? '').compareTo(a.lastCompletedDate ?? '');
              });

            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _GardenSummary(count: rooted, total: verses.length),
                const SizedBox(height: AppSpacing.md),
                for (final v in sorted) ...[
                  _GardenCard(verse: v),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GardenSummary extends StatelessWidget {
  final int count;
  final int total;

  const _GardenSummary({required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final cCol = AppColors.of(context);
    final t = AppTextStyles.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cCol.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cCol.border),
      ),
      child: Row(
        children: [
          Icon(Icons.forest, color: _MemoryGardenColors.rooted, size: 30),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              '$count / $total',
              style: t.displayMedium.copyWith(fontSize: 22),
            ),
          ),
          Text(
            '${count * 100 ~/ (total > 0 ? total : 1)}%',
            style: t.labelSmall.copyWith(color: cCol.primary, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _MemoryGardenColors {
  static const Color rooted = Color(0xFF2E7D32);
}

class _GardenCard extends ConsumerWidget {
  final VerseChallengeData verse;

  const _GardenCard({required this.verse});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cCol = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final color = MemoryGardenScreen._masteryColors[verse.masteryLevel.clamp(0, 2)];
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final today = _today();
    final due = verse.nextReviewDate != null && verse.nextReviewDate!.compareTo(today) <= 0;

    final display = isAm ? (verse.textAm ?? verse.textEn) : verse.textEn;
    final snippet = display.length > 90 ? '${display.substring(0, 90)}…' : display;

    return Material(
      color: cCol.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          '/word-challenge',
          extra: {'reviewId': verse.id},
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: due ? cCol.primary.withValues(alpha: 0.5) : cCol.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco, color: color, size: 26),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            verse.reference,
                            style: t.bodySmall.copyWith(
                              color: color,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (due)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cCol.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l.reviewDue(1),
                              style: t.bodySmall.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cCol.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      snippet,
                      style: isAm
                          ? t.bodyMedium.copyWith(fontSize: 14, height: 1.6, color: cCol.textSecondary)
                          : t.bodyMedium.copyWith(
                              fontFamily: 'CormorantGaramond',
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                              color: cCol.textSecondary,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _today() {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}
