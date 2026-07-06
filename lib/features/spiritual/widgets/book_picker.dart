import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/providers/bible_session_provider.dart';

class BookPicker extends ConsumerWidget {
  final void Function(BibleBook book) onSelected;

  const BookPicker({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final completedAsync = ref.watch(bookCompletionProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: ScriptureService.sections.map((section) {
        final sectionBooks = section.books;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Container(
                  width: 3, height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isAm ? section.nameAm : section.nameEn,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary, fontSize: 13,
                  ),
                ),
              ]),
            ),
            ...sectionBooks.map((book) => _BookTile(
              book: book,
              isAm: isAm,
              completed: completedAsync.valueOrNull ?? {},
              onTap: () => onSelected(book),
            )),
            const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }
}

class _BookTile extends StatelessWidget {
  final BibleBook book;
  final bool isAm;
  final Map<String, int> completed;
  final VoidCallback onTap;

  const _BookTile({
    required this.book, required this.isAm, required this.completed, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = (completed[book.id] ?? 0) >= book.chapters;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: done ? AppColors.progressGreen.withValues(alpha: 0.06) : null,
            ),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    isAm ? book.nameAm : book.nameEn,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: done ? AppColors.progressGreen : AppColors.textPrimary,
                      fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    isAm ? book.themeAm : book.themeEn,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              Text(
                done ? '✓ ${book.chapters}' : '${completed[book.id] ?? 0}/${book.chapters}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: done ? AppColors.progressGreen : AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
