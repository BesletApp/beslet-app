import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/reading_preferences_provider.dart';
import '../../../core/services/scripture_service.dart';
import 'journal_sheet.dart';

class KeptVersesSheet extends ConsumerWidget {
  final bool isAm;
  const KeptVersesSheet({super.key, required this.isAm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verses = ref.watch(allKeptVersesProvider);
    final c = AppColors.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Expanded(
          child: verses.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  itemCount: verses.length,
                  itemBuilder: (_, i) {
                    final v = verses[i];
                    final book = ScriptureService.bookMap[v.bookId];
                    final refStr =
                        '${isAm ? book?.nameAm ?? v.bookId : book?.nameEn ?? v.bookId} ${v.verse}';
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (!context.mounted) return;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            sheetAnimationStyle: AnimationStyle(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                            builder: (_) => JournalSheet(
                              reference: refStr,
                              verseText: v.text,
                              verseId: '${v.bookId}_${v.verse}',
                            ),
                          );
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              refStr,
                              style: TextStyle(
                                fontSize: 11,
                                color: c.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              v.text,
                              style: TextStyle(
                                fontSize: 14,
                                color: c.textPrimary,
                                height: 1.5,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
