import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/wisdom_provider.dart';
import '../../../core/services/scripture_service.dart';

Future<void> showWisdomDialog(BuildContext context, WidgetRef ref, String bookId, bool isAm) async {
  final c = AppColors.of(context);
  final book = ScriptureService.bookMap[bookId];
  final bookName = book != null ? (isAm ? book.nameAm : book.nameEn) : bookId;
  final ctrl = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(children: [
        Text('📜', style: TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Text(isAm ? '$bookName ተጠናቋል!' : '$bookName Completed!', style: AppTextStyles.labelLarge),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          isAm ? 'ለሚቀጥለው መንገደኛ ቃለ ጥበብ ተው' : 'Leave wisdom for the next traveler...',
          style: TextStyle(fontSize: 13, color: c.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          maxLines: 4,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: isAm ? 'ይህን መጽሐፍ ስታነብ እግዚአብሔር ምን አሳየህ?' : 'What did God show you through this book?',
            hintStyle: TextStyle(color: c.textMuted, fontSize: 13),
            filled: true, fillColor: c.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(isAm ? 'ተው' : 'Skip', style: TextStyle(color: c.textMuted)),
        ),
        TextButton(
          onPressed: () {
            final text = ctrl.text.trim();
            if (text.isNotEmpty) {
              ref.read(wisdomNotifierProvider.notifier).saveWisdom(bookId, text);
            }
            Navigator.pop(ctx);
          },
          child: Text(isAm ? 'አስቀምጥ' : 'Save', style: TextStyle(color: AppColors.primary)),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.send, size: 16),
          label: Text(isAm ? 'አጋራ' : 'Share'),
          onPressed: () {
            final text = ctrl.text.trim();
            if (text.isNotEmpty) {
              ref.read(wisdomNotifierProvider.notifier).saveWisdom(bookId, text);
            }
            Navigator.pop(ctx);
            SharePlus.instance.share(ShareParams(
              text: isAm
                ? 'አሁን $bookName በብስለት አጠናቄያለሁ። የተማርኩት፦ ${ctrl.text.trim()}'
                : 'I just finished $bookName on Beslet. Here\'s what I learned: ${ctrl.text.trim()}',
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: const Color(0xFF07090E),
          ),
        ),
      ],
    ),
  );
}
