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
    final c = AppColors.of(context);
    final card = Container(
      padding: padding ?? EdgeInsets.all(variant == CardVariant.tertiary ? 12 : 16),
      decoration: _decoration(c),
      child: child,
    );
    if (onTap != null) return GestureDetector(onTap: onTap, child: card);
    return card;
  }

  BoxDecoration _decoration(ThemePalette c) {
    switch (variant) {
      case CardVariant.hero:
        return BoxDecoration(
          color: c.cardElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.primary.withValues(alpha: 0.5), width: 1),
          boxShadow: [
            BoxShadow(
              color: c.primary.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        );
      case CardVariant.secondary:
        return BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 0.5),
        );
      case CardVariant.tertiary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        );
    }
  }
}
