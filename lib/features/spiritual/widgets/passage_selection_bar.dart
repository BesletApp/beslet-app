import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// The bottom bar shown while selecting a passage. Prompts the reader to tap
/// another verse to extend the range, then offers the single Study action and
/// a quiet Cancel.
class PassageSelectionBar extends StatelessWidget {
  final String studyLabel;
  final String cancelLabel;
  final String hintLabel;
  final VoidCallback onStudy;
  final VoidCallback onCancel;

  const PassageSelectionBar({
    super.key,
    required this.studyLabel,
    required this.cancelLabel,
    required this.hintLabel,
    required this.onStudy,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xs, AppSpacing.md, AppSpacing.md),
      decoration: BoxDecoration(
        color: c.cardElevated.withValues(alpha: 0.6),
        border: Border(top: BorderSide(color: c.border.withValues(alpha: 0.3))),
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            hintLabel,
            style: TextStyle(fontSize: 11, color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: onCancel,
                child: Text(cancelLabel,
                    style: TextStyle(color: c.textSecondary)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: onStudy,
                  icon: const Icon(Icons.menu_book, size: 16, color: Color(0xFF07090E)),
                  label: Text(
                    studyLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                        color: const Color(0xFF07090E), fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
