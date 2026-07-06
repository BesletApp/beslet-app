import 'package:flutter/material.dart';
import '../../../core/services/study_data.dart';
import '../../../core/theme/app_colors.dart';

class StudyGuideCard extends StatelessWidget {
  final String bookId;
  final int chapter;
  final int day;
  final String planId;
  final bool isAmharic;

  const StudyGuideCard({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.day,
    required this.planId,
    required this.isAmharic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctx = StudyData.getContext(bookId, isAmharic);
    final daily = StudyData.forDay(day, planId);

    final bigIdea = isAmharic ? daily.bigIdeaAm : daily.bigIdeaEn;
    final question = isAmharic ? daily.questionAm : daily.questionEn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(theme, '📖 ${isAmharic ? 'የመጽሐፉ ዳራ' : 'Book Context'}', ctx, null),
          const SizedBox(height: 12),
          _section(theme, '💡 ${isAmharic ? 'ትልቁ ሐሳብ' : 'One Big Idea'}', bigIdea, null),
          const SizedBox(height: 12),
          _section(theme, '🤔 ${isAmharic ? 'ማሰላሰያ' : 'Reflection Question'}', question, context),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, String title, String body, BuildContext? ctx) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
          if (title.contains('Reflection') || title.contains('ማሰላሰያ')) ...[
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: isAmharic ? 'መልስህን ጻፍ...' : 'Write your answer...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
