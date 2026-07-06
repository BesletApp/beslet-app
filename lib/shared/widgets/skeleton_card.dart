import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SkeletonCard extends StatefulWidget {
  final double height;
  final double? width;
  final int lineCount;
  final bool hasCircle;
  final bool isDark;

  const SkeletonCard({
    super.key,
    this.height = 80,
    this.width,
    this.lineCount = 2,
    this.hasCircle = false,
    this.isDark = false,
  });

  @override
  State<SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<SkeletonCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.isDark ? AppColors.card : AppColors.cardLight;
    final highlight = widget.isDark ? AppColors.surface : AppColors.backgroundLight;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = (_controller.value * 2).clamp(0.0, 1.0);
        final color = Color.lerp(base, highlight, t)!;
        return Container(
          width: widget.width,
          height: widget.height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(children: [
            if (widget.hasCircle)
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            if (widget.hasCircle) const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.lineCount, (i) {
                final w = i == 0 ? 0.7 : (i == 1 ? 0.9 : 0.5);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(height: 10, width: double.infinity * w, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
                );
              })),
            ),
          ]),
        );
      },
    );
  }
}
