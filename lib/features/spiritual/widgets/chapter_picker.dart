import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/providers/bible_session_provider.dart';

class ChapterPicker extends ConsumerWidget {
  final BibleBook book;
  final void Function(int chapter) onSelected;

  const ChapterPicker({super.key, required this.book, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedAsync = ref.watch(bookCompletionProvider);
    final chaptersRead = completedAsync.valueOrNull?[book.id] ?? 0;
    final totalChapters = book.chapters;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Text(book.nameEn, style: AppTextStyles.labelLarge),
            const Spacer(),
            Text('$chaptersRead/$totalChapters',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8,
                childAspectRatio: 1.2,
              ),
              itemCount: totalChapters,
              itemBuilder: (ctx, i) {
                final chapter = i + 1;
                final isRead = chapter <= chaptersRead;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelected(chapter),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isRead ? AppColors.progressGreen.withValues(alpha: 0.1) : AppColors.card,
                        border: Border.all(
                          color: isRead ? AppColors.progressGreen.withValues(alpha: 0.3) : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$chapter',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: isRead ? AppColors.progressGreen : AppColors.textPrimary,
                                fontSize: 16,
                              )),
                          if (isRead)
                            Icon(Icons.check, size: 12, color: AppColors.progressGreen),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
