import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// A tappable stat tile that expands to reveal its visual. Used to keep the
/// Growth Zone quiet at a glance — the vine leads; the numbers follow.
class DisclosureTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final List<Widget> children;

  /// Whether the tile starts expanded. The first visit opens every tile so the
  /// visuals are seen once; afterwards they rest closed.
  final bool initiallyOpen;

  const DisclosureTile({
    super.key,
    required this.icon,
    required this.title,
    required this.trailing,
    required this.children,
    this.initiallyOpen = false,
  });

  @override
  State<DisclosureTile> createState() => _DisclosureTileState();
}

class _DisclosureTileState extends State<DisclosureTile> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 18, color: c.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(widget.title, style: t.labelLarge.copyWith(color: c.textSecondary)),
                    ),
                    widget.trailing,
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more, size: 20, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
            crossFadeState: _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}
