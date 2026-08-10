import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/audio_player_provider.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// The day's Word, folded into a small quiet chip — the lamp, always lit,
/// never a task.
class DayWordChip extends ConsumerWidget {
  final Scripture verse;
  final bool isAm;

  const DayWordChip({super.key, required this.verse, required this.isAm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final text = isAm ? (verse.textAm ?? verse.text) : verse.text;
    final reference =
        isAm ? ScriptureService.amharicReference(verse.reference) : verse.reference;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.primary.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.primary.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.menu_book, size: 17, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall.copyWith(
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reference,
                  style: t.labelSmall.copyWith(color: c.primary, letterSpacing: 0.6),
                ),
              ],
            ),
          ),
          if (!isAm)
            TextButton.icon(
              onPressed: () => ref
                  .read(audioPlayerProvider.notifier)
                  .speakVerse(text, isAmharic: isAm),
              icon: Icon(Icons.volume_up, size: 16, color: AppColors.of(context).primary),
              label: Text(l.listen, style: t.labelSmall.copyWith(color: AppColors.of(context).primary)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.of(context).primary,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}
