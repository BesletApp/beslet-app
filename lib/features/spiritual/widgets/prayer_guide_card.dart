import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/daily_flow_provider.dart';
import '../../../core/providers/scripture_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../prayer_modes.dart';

/// A quiet guide to the real prayer life a Christian can live — not a room to
/// attend. The Word opens each posture, and each posture carries today's
/// verse, so nothing depends on remembering. Expand to read, collapse and go.
class PrayerGuideCard extends ConsumerWidget {
  const PrayerGuideCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final plan = ref.watch(todayBiblePlanProvider);
    final bibleDone = ref.watch(dailyFlowProvider).bibleDone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l.waysToPray,
                style: AppTextStyles.of(context).labelLarge.copyWith(color: AppColors.primary)),
          ),
        ]),
        Text(
          '${l.prayWhatYouRead} — ${isAm ? plan.labelAm : plan.labelEn}',
          style: AppTextStyles.of(context).bodySmall.copyWith(
                color: c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!bibleDone) ...[
          const SizedBox(height: 4),
          Text(
            '✨ ${l.beginWithWord}',
            style: AppTextStyles.of(context).bodySmall.copyWith(
                  fontSize: 11, color: AppColors.primary, fontStyle: FontStyle.italic),
          ),
        ],
        const SizedBox(height: 8),
        for (final mode in prayerModes) _ModeTile(mode: mode),
        const SizedBox(height: 4),
        const _PrayerWordsTile(),
      ]),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final PrayerMode mode;
  const _ModeTile({required this.mode});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final verse = verseForMode(mode, DateTime.now());
    final verseText = isAm ? (verse.textAm ?? verse.text) : verse.text;
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: Icon(mode.icon, size: 20, color: AppColors.primary),
      title: Text(modeLabel(l, mode),
          style: AppTextStyles.of(context)
              .bodyMedium
              .copyWith(color: c.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(modeGuide(l, mode),
          style: AppTextStyles.of(context).bodySmall.copyWith(color: c.textMuted)),
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.primary,
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(verseText,
                  style: AppTextStyles.of(context)
                      .bodyMedium
                      .copyWith(color: c.textSecondary, fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              Text(verse.reference,
                  style: AppTextStyles.of(context).bodySmall.copyWith(color: c.textMuted)),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PrayerWordsTile extends StatelessWidget {
  const _PrayerWordsTile();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book, size: 20, color: AppColors.primary),
      title: Text(l.prayerWords,
          style: AppTextStyles.of(context)
              .bodyMedium
              .copyWith(color: c.textPrimary, fontWeight: FontWeight.w600)),
      iconColor: AppColors.primary,
      collapsedIconColor: AppColors.primary,
      shape: const Border(),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.lordsPrayer,
                  style: AppTextStyles.of(context)
                      .bodyMedium
                      .copyWith(color: c.textSecondary, height: 1.6)),
              const SizedBox(height: 12),
              Text(l.lordHaveMercy,
                  style: AppTextStyles.of(context)
                      .bodySmall
                      .copyWith(color: c.textMuted, fontStyle: FontStyle.italic)),
            ]),
          ),
        ),
      ],
    );
  }
}
