import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/journal_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import 'fruit_list.dart';

/// Your fruit, folded into a single quiet row. Tapping it opens the drawer —
/// every planted answer is remembered there, and the harvest waits at the end.
class FruitDrawer extends ConsumerWidget {
  final String startDate;
  final bool isAm;
  final int fruitCount;
  final VoidCallback? onHarvest;

  const FruitDrawer({
    super.key,
    required this.startDate,
    required this.isAm,
    required this.fruitCount,
    this.onHarvest,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;

    final history = ref.watch(journalHistoryProvider).valueOrNull ?? <JournalEntryData>[];
    final fruits = history
        .where((e) => e.date.compareTo(startDate) >= 0 && e.content?.trim().isNotEmpty == true)
        .toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDrawer(context, fruits),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_basket_outlined, size: 18, color: AppColors.of(context).primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l.yourFruit,
                  style: t.labelLarge.copyWith(color: c.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$fruitCount',
                  style: t.labelLarge.copyWith(color: AppColors.of(context).primary, fontSize: 13),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrawer(BuildContext context, List<JournalEntryData> fruits) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FruitDrawerSheet(
        fruits: fruits,
        isAm: isAm,
        onHarvest: onHarvest,
      ),
    );
  }
}

class _FruitDrawerSheet extends StatelessWidget {
  final List<JournalEntryData> fruits;
  final bool isAm;
  final VoidCallback? onHarvest;

  const _FruitDrawerSheet({
    required this.fruits,
    required this.isAm,
    this.onHarvest,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Material(
          color: c.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Column(
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
                      Row(
                        children: [
                          Icon(Icons.shopping_basket_outlined, size: 18, color: AppColors.of(context).primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l.yourFruit, style: t.labelLarge.copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: fruits.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(l.vineRemembersEmpty, style: t.bodyMedium.copyWith(color: c.textMuted)),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: fruits.length,
                          itemBuilder: (context, i) {
                            final e = fruits[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: Material(
                                color: c.cardElevated,
                                borderRadius: BorderRadius.circular(10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(10),
                                  onTap: () => showFruitDialog(
                                    context,
                                    content: e.content ?? '',
                                    day: i + 1,
                                    isAm: isAm,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(
                                      e.content ?? '',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: t.bodySmall.copyWith(color: c.textSecondary, height: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (onHarvest != null)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onHarvest!();
                        },
                        icon: const Icon(Icons.shopping_basket),
                        label: Text(l.harvestWhenReady),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.of(context).primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
