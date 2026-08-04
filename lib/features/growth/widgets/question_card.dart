import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/journal_provider.dart';
import '../../../core/services/scene_event_bus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/beslet_card.dart';

/// One question from the day's journey. The answer is planted into the shared
/// per-day journal — it later becomes a fruit on the vine.
class QuestionCard extends ConsumerWidget {
  final String question;
  final String questionAm;
  final bool isAm;

  const QuestionCard({
    super.key,
    required this.question,
    required this.questionAm,
    required this.isAm,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final answered = ref.watch(journalEntryProvider).valueOrNull?.content?.trim().isNotEmpty == true;

    return BesletCard(
      variant: CardVariant.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, size: 18, color: AppColors.of(context).primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l.oneQuestion,
                style: t.labelLarge.copyWith(color: c.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isAm ? questionAm : question,
            style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openAnswerSheet(context, isAm, question, questionAm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.of(context).primary.withValues(alpha: answered ? 0.08 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.of(context).primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      answered ? Icons.check_circle_outline : Icons.edit_outlined,
                      size: 18,
                      color: AppColors.of(context).primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      answered ? l.answeredTapToRead : l.answerIt,
                      style: t.labelLarge.copyWith(
                        color: AppColors.of(context).primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAnswerSheet(
    BuildContext context,
    bool isAm,
    String question,
    String questionAm,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AnswerSheet(isAm: isAm, question: question, questionAm: questionAm),
    );
  }
}

class _AnswerSheet extends ConsumerStatefulWidget {
  final bool isAm;
  final String question;
  final String questionAm;

  const _AnswerSheet({required this.isAm, required this.question, required this.questionAm});

  @override
  ConsumerState<_AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends ConsumerState<_AnswerSheet> {
  final _ctrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(journalNotifierProvider.notifier).saveEntry(_ctrl.text);
    ref.read(sceneEventBusProvider).emit(SceneEventType.fruitPop);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    ref.listen(journalEntryProvider, (prev, next) {
      final content = next.valueOrNull?.content;
      if (content != null && !_loaded && _ctrl.text.isEmpty) {
        _loaded = true;
        _ctrl.text = content;
      }
    });
    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                Text(widget.isAm ? widget.questionAm : widget.question, style: t.bodyLarge),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _ctrl,
                  maxLines: 4,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l.writeYourAnswer,
                    filled: true,
                    fillColor: c.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.of(context).primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(l.plantIt),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
