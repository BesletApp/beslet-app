import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/study_data.dart';
import '../../../core/theme/app_colors.dart';

class StudyGuideCard extends StatefulWidget {
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
  State<StudyGuideCard> createState() => _StudyGuideCardState();
}

class _StudyGuideCardState extends State<StudyGuideCard> {
  final _controller = TextEditingController();

  String get _key => 'study_answer_${widget.planId}_${widget.day}';

  @override
  void initState() {
    super.initState();
    _loadAnswer();
  }

  Future<void> _loadAnswer() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && _controller.text != saved) {
      _controller.text = saved;
    }
  }

  Future<void> _saveAnswer(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = Theme.of(context);
    final ctx = StudyData.getContext(widget.bookId, widget.isAmharic);
    final daily = StudyData.forDay(widget.day, widget.planId);

    final bigIdea = widget.isAmharic ? daily.bigIdeaAm : daily.bigIdeaEn;
    final question = widget.isAmharic ? daily.questionAm : daily.questionEn;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _section(c, theme, '📖 ${widget.isAmharic ? 'የመጽሐፉ ዳራ' : 'Book Context'}', ctx),
          const SizedBox(height: 12),
          _section(c, theme, '💡 ${widget.isAmharic ? 'ትልቁ ሐሳብ' : 'One Big Idea'}', bigIdea),
          const SizedBox(height: 12),
          _section(c, theme, '🤔 ${widget.isAmharic ? 'ማሰላሰያ' : 'Reflection Question'}', question),
        ],
      ),
    );
  }

  Widget _section(ThemePalette c, ThemeData theme, String title, String body) {
    final isReflection = title.contains('Reflection') || title.contains('ማሰላሰያ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(body, style: theme.textTheme.bodyMedium),
          if (isReflection) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: widget.isAmharic ? 'መልስህን ጻፍ...' : 'Write your answer...',
                filled: true,
                fillColor: c.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
              onChanged: _saveAnswer,
            ),
          ],
        ],
      ),
    );
  }
}
