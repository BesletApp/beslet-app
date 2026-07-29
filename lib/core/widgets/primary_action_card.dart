import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 🔒 BESLET ENFORCEMENT: PRIMARY ACTION CARD (Z2)
///
/// Enforces:
/// - R1: Single primary action (exactly ONE CTA button)
/// - R2: Must live in Z2 (intended for ZoneLayout.primary)
/// - R3: Elevated card styling via accent border (no shadow)
/// - R4: Full-width CTA with zero elevation
/// - R5: No competing elevation (no shadow anywhere)
///
/// IMPORTANT:
/// - NO shadow allowed — visual hierarchy via color only
/// - ONLY one CTA — do NOT add multiple actions
/// - DO NOT extend this widget with a list of actions
///
/// LANGUAGE SAFETY:
/// - All text wraps safely with no overflow
/// - No fixed heights — adapts to content
/// - Button remains usable regardless of text length
class PrimaryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;
  final Color accentColor;

  const PrimaryActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final textStyles = AppTextStyles.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: c.cardElevated,
        borderRadius: BorderRadius.circular(16),
        // Accent border only — NO SHADOW
        border: Border.all(
          color: accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: AppSpacing.sm),
          // Title — multi-line safe
          Text(
            title,
            style: textStyles.displaySmall.copyWith(
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Subtitle — multi-line safe
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: c.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 🔴 ONLY CTA ALLOWED — full width, zero elevation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: c.isDark
                    ? const Color(0xFF07090E)
                    : Colors.white,
                elevation: 0, // R4: no elevation
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.sm + 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: onPressed,
              child: Text(
                buttonText,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                // Allow multi-line if text is long
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
