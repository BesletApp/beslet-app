import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/services/widget_service.dart' show LampLight;

/// A soft cinematic light pass over the whole garden: warm god-ray shafts
/// falling from the sun/moon, a subtle bloom around the light body, and a
/// gentle breathing warm wash. Implemented procedurally (GPU gradients) so it
/// works on every device and in every test environment — the same role a
/// screen-space color-grade shader would play, without the build risk.
class SceneLightPainter extends CustomPainter {
  final LampLight light;
  final bool isDark;
  final double t;
  final double breath;
  final int seed;

  const SceneLightPainter({
    required this.light,
    required this.isDark,
    required this.t,
    required this.breath,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final (x: sx, y: sy, glow: glowColor, r: sr) = _lightBody(size);
    // The light body breathes and drifts.
    final bx = sx + math.sin(t * 0.35 + seed) * size.width * 0.02;
    final by = sy + math.cos(t * 0.29 + seed * 1.3) * size.height * 0.015;

    // Bloom: a warm soft circle around the sun/moon.
    final bloom = Paint()
      ..shader = ui.Gradient.radial(
        Offset(bx, by),
        sr * (3.6 + breath * 0.5),
        [
          glowColor.withValues(alpha: (isDark ? 0.10 : 0.16) + breath * 0.05),
          glowColor.withValues(alpha: 0),
        ],
      );
    canvas.drawRect(Offset.zero & size, bloom);

    if (light == LampLight.night) return; // moon shafts feel wrong; keep glow

    // God rays: soft, faint, fanning down from the light body.
    final rays = Paint()
      ..shader = ui.Gradient.radial(
        Offset(bx, by),
        sr * 3.4,
        [
          const Color(0xFFF9E6B0).withValues(alpha: 0.10 + breath * 0.03),
          const Color(0xFFF9E6B0).withValues(alpha: 0),
        ],
      );
    canvas.save();
    canvas.translate(bx, by);
    final spread = 0.5 + breath * 0.15;
    final seedRng = math.Random(seed);
    for (var i = 0; i < 5; i++) {
      final baseAngle = seedRng.nextDouble() * 0.5 - 0.25 + 0.05;
      final width = 0.05 + seedRng.nextDouble() * 0.06;
      canvas.save();
      canvas.rotate(baseAngle);
      canvas.skew(0.2, 0);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(size.height * 0.55 * spread, 0),
          width: width * size.width * 2.2,
          height: size.height * (1.1 + spread),
        ),
        rays,
      );
      canvas.restore();
    }
    canvas.restore();

    // A few motes drifting in the light shafts.
    final mote = Paint()..style = PaintingStyle.fill;
    final mRng = math.Random(seed + 17);
    for (var i = 0; i < 12; i++) {
      final driftX = math.sin(t * 0.8 + mRng.nextDouble() * 6) * 6;
      final baseY = mRng.nextDouble();
      final y = ((baseY * size.height * 0.7 + t * 8) % (size.height * 0.7)) + size.height * 0.05;
      final x = size.width * 0.5 + (mRng.nextDouble() - 0.5) * size.width * 0.5 + driftX;
      final alpha = 0.10 + 0.12 * math.sin(t * 1.2 + i * 2.1);
      mote.color = const Color(0xFFF3D66A).withValues(alpha: alpha.clamp(0.0, 0.22));
      canvas.drawCircle(Offset(x, y), 1 + mRng.nextDouble() * 1.6, mote);
    }
  }

  ({double x, double y, Color glow, double r}) _lightBody(Size size) {
    switch (light) {
      case LampLight.dawn:
        return (x: size.width * 0.24, y: size.height * 0.5, glow: const Color(0xFFF2C879), r: size.width * 0.085);
      case LampLight.noon:
        return (x: size.width * 0.5, y: size.height * 0.12, glow: const Color(0xFFF7B733), r: size.width * 0.08);
      case LampLight.dusk:
        return (x: size.width * 0.76, y: size.height * 0.46, glow: const Color(0xFFE88A3C), r: size.width * 0.085);
      case LampLight.night:
        return (x: size.width * 0.78, y: size.height * 0.14, glow: const Color(0xFFB8CEE8), r: size.width * 0.055);
    }
  }

  @override
  bool shouldRepaint(covariant SceneLightPainter old) {
    return old.light != light ||
        old.isDark != isDark ||
        old.t != t ||
        old.breath != breath ||
        old.seed != seed;
  }
}
