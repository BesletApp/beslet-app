import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/identity_provider.dart';
import '../../../core/providers/scripture_provider.dart';
import '../../../core/providers/word_challenge_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// Choose the one Word to carry. Options: today's Thread verse and today's
/// reading plan verse — both already part of the app's daily flow.
Future<void> showChooseWordSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChooseWordSheet(),
  );
}

class _ChooseWordSheet extends ConsumerWidget {
  const _ChooseWordSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);

    final today = ref.watch(todayWordChallengeProvider);
    final plan = ref.watch(todayBiblePlanProvider);

    return SafeArea(
      top: false,
      child: Material(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(l.profileLampChoose, style: t.displaySmall),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l.profileLampEmpty,
                style: t.bodySmall.copyWith(color: c.textSecondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              today.when(
                data: (data) => _wordTile(
                  context: context,
                  ref: ref,
                  reference: data.reference,
                  text: data.textEn,
                  textAm: data.textAm,
                  subtitle: l.wordChallenge,
                ),
                loading: () => const SizedBox(
                  height: 48,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.sm),
              _wordTile(
                context: context,
                ref: ref,
                reference: plan.labelEn,
                text: null,
                textAm: null,
                subtitle: l.readToday,
                isPlan: true,
                bookId: plan.bookId,
                chapter: plan.chapter,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wordTile({
    required BuildContext context,
    required WidgetRef ref,
    required String reference,
    required String? text,
    required String? textAm,
    required String subtitle,
    bool isPlan = false,
    String? bookId,
    int? chapter,
  }) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    Widget title;
    if (text != null && text.isNotEmpty) {
      title = Text(
        isAm && textAm != null ? textAm : text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium.copyWith(height: 1.4),
      );
    } else {
      title = Text(
        isAm ? l.wordChallenge : l.wordChallenge,
        style: t.bodyMedium.copyWith(color: c.textMuted),
      );
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (isPlan) {
          _choosePlanVerse(context, ref, bookId!, chapter!, reference);
          return;
        }
        ref
            .read(identityNotifierProvider.notifier)
            .setKeptWord(
              text: isAm && textAm != null ? textAm : text,
              reference: reference,
            );
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reference,
                    style: t.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ),
                Text(
                  subtitle,
                  style: t.labelSmall.copyWith(color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            title,
          ],
        ),
      ),
    );
  }

  Future<void> _choosePlanVerse(
    BuildContext context,
    WidgetRef ref,
    String bookId,
    int chapter,
    String reference,
  ) async {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final chapterData = await ref
        .read(scriptureProvider((bookId: bookId, chapter: chapter, isAmharic: isAm)).future);
    if (chapterData == null || chapterData.verses.isEmpty) return;
    final v = chapterData.verses.first;
    await ref
        .read(identityNotifierProvider.notifier)
        .setKeptWord(text: v.text, reference: reference);
    if (context.mounted) Navigator.of(context).pop();
  }
}
