import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// 🔒 BESLET ENFORCEMENT: ZONE LAYOUT
///
/// Enforces:
/// - R6: 4 zones (Z1 orientation, Z2 primary, Z3 support, Z4 anchor)
/// - R7: Fixed order (Z1 -> Z2 -> Z3 -> Z4)
/// - R8: Z2 position is stable (never moves, never conditionally hidden)
///
/// WHY:
/// Prevents layout violations and ensures consistent vertical flow.
///
/// RULES:
/// - Order is fixed
/// - Spacing is fixed
/// - No reordering allowed
///
/// NOTE:
/// This widget does NOT scroll. Scrolling is handled at screen level.
class ZoneLayout extends StatelessWidget {
  /// Z1 — Orientation (header, identity, context)
  final Widget orientation;

  /// Z2 — Primary Action (MANDATORY, SINGLE, DOMINANT)
  final Widget primary;

  /// Z3 — Support (secondary actions, stats, optional)
  final Widget? support;

  /// Z4 — Anchor (reflection, verse, grounding content)
  final Widget anchor;

  const ZoneLayout({
    super.key,
    required this.orientation,
    required this.primary,
    required this.anchor,
    this.support,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Z1 — Orientation
          orientation,

          const SizedBox(height: AppSpacing.zoneGap),

          // 🔴 Z2 — DO NOT MOVE OR CONDITIONALLY HIDE
          primary,

          const SizedBox(height: AppSpacing.zoneGap),

          // Z3 — Support (optional, but position is fixed when present)
          if (support != null) ...[
            support!,
            const SizedBox(height: AppSpacing.zoneGap),
          ],

          // Z4 — Anchor (ALWAYS LAST)
          anchor,

          // Bottom breathing room
          const SizedBox(height: AppSpacing.bottomPadding),
        ],
      ),
    );
  }
}
