import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/fellowship_provider.dart';
import '../../../core/providers/habits_provider.dart';
import '../../../core/providers/prayer_provider.dart';
import '../../../core/providers/tracking_provider.dart';
import '../../../core/providers/growth_streams_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// The day's rhythm: five gentle steps — the Word, prayer, habits, skills,
/// and fellowship. A quiet ring, never a score.
class RhythmRing extends ConsumerWidget {
  const RhythmRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;

    final read = ref.watch(todayReadingProvider).valueOrNull != null;
    final prayed = ref.watch(todayPrayerLogProvider).valueOrNull != null;
    final habits = ref.watch(todayCompletionsProvider).valueOrNull?.isNotEmpty == true;
    final skills = (ref.watch(trackingDataProvider).valueOrNull?.skillsMinutes ?? 0) > 0;
    final connected = ref.watch(todayFellowshipProvider).valueOrNull != null;
    final rhythm = ref.watch(todayRhythmProvider);

    final steps = [
      (icon: Icons.menu_book, label: l.bible, done: read),
      (icon: Icons.auto_awesome, label: l.prayer, done: prayed),
      (icon: Icons.check_circle_outline, label: l.habits, done: habits),
      (icon: Icons.build_outlined, label: l.skills, done: skills),
      (icon: Icons.people_outline, label: l.community, done: connected),
    ];

    final progress = rhythm.total == 0 ? 0.0 : rhythm.done / rhythm.total;

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              final center = size.center(Offset.zero);
              final radius = size.shortestSide / 2 - 14;
              final dots = <Widget>[];
              for (var i = 0; i < steps.length; i++) {
                final angle = -math.pi / 2 + i * (2 * math.pi / steps.length);
                final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;
                dots.add(Positioned(
                  left: pos.dx - 18,
                  top: pos.dy - 18,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: steps[i].done
                          ? c.primary.withValues(alpha: 0.15)
                          : c.cardElevated,
                      border: Border.all(
                        color: steps[i].done ? c.primary : c.border,
                        width: steps[i].done ? 1.5 : 1,
                      ),
                    ),
                    child: Icon(
                      steps[i].icon,
                      size: 17,
                      color: steps[i].done ? c.primary : c.textMuted,
                    ),
                  ),
                ));
              }
              return Stack(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => CustomPaint(
                      size: size,
                      painter: _RingPainter(
                        progress: value,
                        track: c.border,
                        fill: c.primary,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${rhythm.done}',
                          style: t.displayMedium.copyWith(color: c.primary, fontSize: 34),
                        ),
                        Text(
                          l.stepsOf(rhythm.done, rhythm.total),
                          style: t.bodySmall.copyWith(color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  ...dots,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            for (final s in steps)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(s.done ? Icons.check_circle : Icons.circle, size: 9, color: s.done ? AppColors.of(context).success : c.textMuted),
                  const SizedBox(width: 4),
                  Text(s.label, style: t.labelSmall.copyWith(color: s.done ? c.textSecondary : c.textMuted)),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color fill;

  const _RingPainter({required this.progress, required this.track, required this.fill});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 14;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        fillPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) {
    return old.progress != progress || old.track != track || old.fill != fill;
  }
}
