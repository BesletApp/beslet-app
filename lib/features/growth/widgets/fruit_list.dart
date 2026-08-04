import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/journal_provider.dart';
import '../../../core/services/growth_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/beslet_card.dart';

/// Your Fruit — the answered days of this journey. Every planted answer is
/// remembered here, never graded. Tapping a fruit opens its words.
class FruitList extends ConsumerWidget {
  final String startDate;
  final bool isAm;

  const FruitList({super.key, required this.startDate, required this.isAm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final history = ref.watch(journalHistoryProvider).valueOrNull ?? <JournalEntryData>[];

    final fruits = history
        .where((e) => e.date.compareTo(startDate) >= 0 && e.content?.trim().isNotEmpty == true)
        .toList();

    return BesletCard(
      variant: CardVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_basket_outlined, size: 18, color: AppColors.of(context).primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l.yourFruit,
                style: t.labelLarge.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (fruits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                l.vineRemembersEmpty,
                style: t.bodyMedium.copyWith(color: c.textMuted),
              ),
            )
          else
            ...fruits.map(
              (e) => _FruitTile(entry: e, isAm: isAm),
            ),
        ],
      ),
    );
  }
}

class _FruitTile extends StatelessWidget {
  final JournalEntryData entry;
  final bool isAm;

  const _FruitTile({required this.entry, required this.isAm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final content = entry.content ?? '';
    final start = DateTime.tryParse(entry.date);
    final day = start == null ? 1 : GrowthContent.journeyDay(start, start);
    final preview = content.length > 90 ? '${content.substring(0, 90)}…' : content;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => showFruitDialog(context, content: content, day: day, isAm: isAm),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
            decoration: BoxDecoration(
              color: c.cardElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l.dayLabel} $day',
                  style: t.labelSmall.copyWith(
                    color: AppColors.of(context).primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  preview,
                  style: t.bodySmall.copyWith(color: c.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a fruit's words in a gentle dialog (also reachable from the vine's
/// fruit taps).
void showFruitDialog(
  BuildContext context, {
  required String content,
  required int day,
  required bool isAm,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final c = AppColors.of(context);
      final t = AppTextStyles.of(context);
      final l = AppLocalizations.of(context)!;
      return Dialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l.dayLabel} $day',
                style: t.labelSmall.copyWith(
                  color: AppColors.of(context).primary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(content, style: t.bodyMedium.copyWith(height: 1.6)),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.close),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
