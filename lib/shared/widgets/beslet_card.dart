import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CardVariant { hero, secondary, tertiary }

class BesletCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final CardVariant variant;

  const BesletCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.variant = CardVariant.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? EdgeInsets.all(variant == CardVariant.tertiary ? 12 : 16),
      decoration: _decoration,
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }

  BoxDecoration get _decoration {
    switch (variant) {
      case CardVariant.hero:
        return BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        );
      case CardVariant.secondary:
        return BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        );
      case CardVariant.tertiary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        );
    }
  }
}
