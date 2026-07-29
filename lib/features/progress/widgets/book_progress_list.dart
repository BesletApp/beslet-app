import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/plan_progress_service.dart';

class BookProgressList extends StatefulWidget {
  final PlanProgress progress;

  const BookProgressList({super.key, required this.progress});

  @override
  State<BookProgressList> createState() => _BookProgressListState();
}

class _BookProgressListState extends State<BookProgressList> {
  bool _showOT = true;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final progress = widget.progress;
    final books = _showOT ? progress.otProgress : progress.ntProgress;
    final chaptersRead = _showOT ? progress.otChaptersRead : progress.ntChaptersRead;
    final totalChapters = _showOT ? progress.otTotalChapters : progress.ntTotalChapters;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _tab(isAm ? 'ብሉይ' : 'OT', true, c),
        const SizedBox(width: 8),
        _tab(isAm ? 'አዲስ' : 'NT', false, c),
      ]),
      const SizedBox(height: 12),
      Text(isAm ? '$chaptersRead ከ$totalChapters ምዕራፎች' : '$chaptersRead of $totalChapters chapters',
          style: AppTextStyles.of(context).bodySmall.copyWith(color: c.textSecondary)),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: totalChapters > 0 ? chaptersRead / totalChapters : 0,
          minHeight: 6,
          backgroundColor: c.border,
          valueColor: AlwaysStoppedAnimation<Color>(_showOT ? c.primary : c.audioBlue),
        ),
      ),
      const SizedBox(height: 16),
      ...books.map((bp) => _bookRow(bp, c, isAm)),
    ]);
  }

  Widget _tab(String label, bool isOt, ThemePalette c) {
    final selected = _showOT == isOt;
    return GestureDetector(
      onTap: () => setState(() => _showOT = isOt),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? c.primary : c.border),
        ),
        child: Text(label, style: TextStyle(
          fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700,
          color: selected ? (c.isDark ? const Color(0xFF07090E) : Colors.white) : c.textPrimary,
        )),
      ),
    );
  }

  Widget _bookRow(BookProgress bp, ThemePalette c, bool isAm) {
    final ratio = bp.book.chapters > 0 ? bp.chaptersRead / bp.book.chapters : 0.0;
    final completeColor = c.progressGreen;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 120,
          child: Text(isAm ? bp.book.nameAm : bp.book.nameEn,
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: c.textPrimary), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: c.border,
              valueColor: AlwaysStoppedAnimation<Color>(bp.isComplete ? completeColor : c.primary),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 36,
          child: Text('${bp.chaptersRead}/${bp.book.chapters}', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: c.textSecondary)),
        ),
        if (bp.isComplete)
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Icon(Icons.check_circle, size: 14, color: completeColor),
          ),
      ]),
    );
  }
}
