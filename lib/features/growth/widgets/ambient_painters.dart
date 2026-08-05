import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soft clouds drifting across the sky on the garden's clock. Deterministic
/// from [seed] so they never feel noisy or tracked.
class CloudPainter extends CustomPainter {
  final int seed;
  final double t;
  final Color color;

  const CloudPainter({required this.seed, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint();
    for (var c = 0; c < 3; c++) {
      final speed = 0.008 + rng.nextDouble() * 0.012;
      final baseX = rng.nextDouble();
      final y = size.height * (0.10 + rng.nextDouble() * 0.24);
      final w = size.width * (0.30 + rng.nextDouble() * 0.24);
      final x = ((baseX + t * speed) % 1.3 - 0.15) * size.width;
      paint.color = color.withValues(alpha: 0.10);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: w * 0.34), paint);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x - w * 0.18, y - w * 0.05), width: w * 0.5, height: w * 0.28),
        paint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + w * 0.2, y - w * 0.04), width: w * 0.45, height: w * 0.26),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CloudPainter old) =>
      old.t != t || old.seed != seed || old.color != color;
}

/// Grass tufts at the soil line, swaying gently with the clock.
class GrassPainter extends CustomPainter {
  final int seed;
  final double t;
  final Color color;

  const GrassPainter({required this.seed, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final soilY = size.height * 0.9;
    final cx = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.7);
    const tufts = 16;
    for (var i = 0; i < tufts; i++) {
      final bx = cx -
          size.width * 0.34 +
          (size.width * 0.68) * i / (tufts - 1) +
          (rng.nextDouble() - 0.5) * 8;
      final h = 8 + rng.nextDouble() * 12;
      final sway = math.sin(t * 3 + i * 0.8) * 3;
      paint.strokeWidth = 1.4;
      canvas.drawLine(
        Offset(bx, soilY + 4),
        Offset(bx + sway, soilY - h),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GrassPainter old) =>
      old.t != t || old.seed != seed || old.color != color;
}

/// An occasional bird arcing across the sky — two wing beats, then gone.
class BirdPainter extends CustomPainter {
  final int seed;
  final double t;
  final Color color;

  const BirdPainter({required this.seed, required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cycle = t % 26;
    if (cycle > 4) return;
    final rng = math.Random(seed);
    final progress = cycle / 4;
    final x = (-0.1 + progress * 1.2) * size.width;
    final lane = size.height * (0.18 + (rng.nextDouble() % 1) * 0.16);
    final flap = math.sin(cycle * math.pi * 4);
    final y = lane - math.sin(progress * math.pi) * 12;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 4, y - flap * 2), Offset(x, y), paint);
    canvas.drawLine(Offset(x, y), Offset(x + 4, y - flap * 2), paint);
  }

  @override
  bool shouldRepaint(covariant BirdPainter old) =>
      old.t != t || old.seed != seed || old.color != color;
}
