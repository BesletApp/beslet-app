import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 🔒 BESLET ENFORCEMENT: ANCHOR (Z4)
///
/// Enforces:
/// - R9: Hairline divider at the top
/// - R10: All content is center-aligned
/// - R11: NON-INTERACTIVE — no buttons, no taps, no InkWell
///
/// WHY:
/// Provides a calm, reflective ending to every screen.
///
/// RULES:
/// - NON-INTERACTIVE by construction (accepts ONLY String, not Widget)
/// - CENTERED content
/// - Minimal visual weight
///
/// LANGUAGE SAFETY:
/// - Text wraps safely with no overflow
/// - Always centered regardless of text length
class AnchorSection extends StatelessWidget {
  /// The reflective text content (must be non-null)
  final String text;

  const AnchorSection({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hairline divider — 0.5pt, 15% opacity (R9)
        Container(
          height: 0.5,
          width: double.infinity,
          color: c.border.withValues(alpha: 0.15),
        ),

        const SizedBox(height: AppSpacing.cardPadding),

        // 🔒 Centered text ONLY — no interactive elements (R10, R11)
        Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: c.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
