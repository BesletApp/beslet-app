import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// The single action at the very bottom of a finished chapter: "I have read".
/// It only exists here — never at the top — so a quick skip is impossible.
class BottomConfirmationButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onPressed;

  const BottomConfirmationButton({
    super.key,
    this.busy = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF07090E)),
              )
            : const Icon(Icons.check, size: 18),
        label: Text(
          l.iHaveRead,
          style: AppTextStyles.labelLarge.copyWith(fontSize: 14),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
