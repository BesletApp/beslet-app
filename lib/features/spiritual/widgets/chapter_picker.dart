import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/scripture_service.dart';

class ChapterPicker extends ConsumerWidget {
  final BibleBook book;
  final void Function(int chapter) onSelected;

  const ChapterPicker({super.key, required this.book, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final totalChapters = book.chapters;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: c.textPrimary, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: 8),
            Text(book.nameEn, style: AppTextStyles.labelLarge),
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
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelected(chapter),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: c.card,
                      ),
                      alignment: Alignment.center,
                      child: Text('$chapter',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: c.textPrimary,
                            fontSize: 16,
                          )),
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
