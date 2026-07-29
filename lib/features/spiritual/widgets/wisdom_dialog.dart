import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        Text(bookName, style: AppTextStyles.labelLarge),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: ctrl,
          maxLines: 4,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            filled: true, fillColor: c.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ]),
      actions: [
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
      ],
    ),
  );
}
