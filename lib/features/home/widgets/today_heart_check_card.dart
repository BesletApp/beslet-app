import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/question_content_provider.dart';
import '../../../core/services/provocative_question_service.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_durations.dart';
import '../../../core/theme/app_text_styles.dart';
/// Today's Heart Check: one quiet, biblically curated question at the very top
/// of the Today screen. Collapsed it is a single line; tapped, it expands in
/// place to two references and one short reflection. No card, no shadow, no
/// streak or XP pressure, fully offline, and the expanded state never leaves
/// the widget.
class TodayHeartCheckCard extends ConsumerStatefulWidget {
  const TodayHeartCheckCard({super.key});

  @override
  ConsumerState<TodayHeartCheckCard> createState() => _TodayHeartCheckCardState();
}

class _TodayHeartCheckCardState extends ConsumerState<TodayHeartCheckCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final questionAsync = ref.watch(todayQuestionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        questionAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (question) => AnimatedSize(
            duration: AppDurations.slow,
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(6),
                child: _expanded
                    ? _buildExpanded(c, isAm, question)
                    : _buildCollapsed(c, isAm, question),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCollapsed(ThemePalette c, bool isAm, ProvocativeQuestion question) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        '❝ ${question.questionFor(isAm)}',
        style: AppTextStyles.of(context).bodyMedium.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: c.primary,
              height: 1.35,
            ),
      ),
    );
  }

  Widget _buildExpanded(ThemePalette c, bool isAm, ProvocativeQuestion question) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '❝ ${question.questionFor(isAm)}',
            style: AppTextStyles.of(context).bodyMedium.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < question.verses.length; i++) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                isAm
                    ? '— ${ScriptureService.amharicReference(question.verses[i])}'
                    : '— ${question.verses[i]}',
                style: AppTextStyles.of(context).bodySmall.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
              ),
            ),
            if (i < question.verses.length - 1) const SizedBox(height: 2),
          ],
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              question.reflectionFor(isAm),
              style: AppTextStyles.of(context).bodySmall.copyWith(
                    fontSize: 13,
                    color: c.textPrimary.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}