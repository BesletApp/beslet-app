import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Deterministic, procedural vine geometry. The same [seed] always yields the
/// same living vine — pure math, offline, untrackable. [sway] adds a tiny
/// time-based wiggle without changing the underlying structure.
VineGeometry buildVine({
  required int seed,
  required double growth01,
  required int branches,
  required Size size,
  double sway = 0,
}) {
  final rng = math.Random(seed);
  final segments = <VineSegment>[];
  final tips = <Offset>[];

  final cx = size.width / 2;
  final soilY = size.height * 0.9;

  // Trunk: rises from the soil toward the sky.
  final trunkBase = Offset(cx, soilY);
  final trunkLen = size.height * 0.32 * growth01;
  final trunkEnd = trunkBase + Offset(0, -trunkLen);
  segments.add(VineSegment(from: trunkBase, to: trunkEnd, width: 11, depth: 0));

  final depth = _depthFor(branches);
  _grow(
    rng,
    trunkEnd,
    depth,
    -math.pi / 2,
    size.height * 0.30 * growth01,
    6.0,
    sway,
    segments,
    tips,
    size,
  );
  return VineGeometry(segments: segments, tips: tips);
}

int _depthFor(int branches) {
  if (branches <= 0) return 0;
  var depth = 0;
  var leaves = 1;
  while (leaves < branches) {
    depth++;
    leaves *= 2;
  }
  return depth;
}

void _grow(
  math.Random rng,
  Offset from,
  int depth,
  double baseAngle,
  double length,
  double width,
  double sway,
  List<VineSegment> segments,
  List<Offset> tips,
  Size size,
) {
  if (depth <= 0) {
    tips.add(from);
    return;
  }
  final spread = math.pi / 4 + rng.nextDouble() * (math.pi / 5);
  for (final dir in const [-1.0, 1.0]) {
    final angle = baseAngle + dir * spread + sway * 0.04;
    final len = length * (0.72 + rng.nextDouble() * 0.12);
    final to = from + Offset(math.cos(angle), math.sin(angle)) * len;
    if (to.dy < -24) continue;
    segments.add(VineSegment(from: from, to: to, width: width, depth: depth));
    _grow(rng, to, depth - 1, angle, len, width * 0.72, sway, segments, tips, size);
  }
}

class VineSegment {
  final Offset from;
  final Offset to;
  final double width;
  final int depth;
  const VineSegment({required this.from, required this.to, required this.width, required this.depth});
}

class VineGeometry {
  final List<VineSegment> segments;
  final List<Offset> tips;
  const VineGeometry({required this.segments, required this.tips});
}

/// Palette used by the vine painter.
class VinePalette {
  final Color soil;
  final Color trunk;
  final Color branch;
  final Color leaf;
  final Color blossom;
  const VinePalette({
    required this.soil,
    required this.trunk,
    required this.branch,
    required this.leaf,
    required this.blossom,
  });

  static const VinePalette light = VinePalette(
    soil: Color(0xFF6B4F2E),
    trunk: Color(0xFF6B4F2E),
    branch: Color(0xFF8A6A3C),
    leaf: Color(0xFF4C8C4A),
    blossom: Color(0xFFF3E2B8),
  );

  static const VinePalette dark = VinePalette(
    soil: Color(0xFF3A2E1E),
    trunk: Color(0xFF7A5C38),
    branch: Color(0xFF9A7A48),
    leaf: Color(0xFF5CA85A),
    blossom: Color(0xFFF0DCB0),
  );
}

/// Paints the living vine. Ripening is visual only: [fruitColor] is expected to
/// be ramped from green to gold by the caller as the journey grows.
class VinePainter extends CustomPainter {
  final int seed;
  final double growth01;
  final int branches;
  final int fruitCount;
  final Color fruitColor;
  final double sway;
  final VinePalette palette;
  final bool showBlossoms;

  const VinePainter({
    required this.seed,
    required this.growth01,
    required this.branches,
    required this.fruitCount,
    required this.fruitColor,
    required this.palette,
    this.sway = 0,
    this.showBlossoms = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = buildVine(
      seed: seed,
      growth01: growth01,
      branches: branches,
      size: size,
      sway: sway,
    );

    _paintSoil(canvas, size);

    final branchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final seg in geometry.segments) {
      final t = (seg.depth / 4).clamp(0.0, 1.0);
      final color = Color.lerp(palette.trunk, palette.branch, t)!;
      branchPaint.color = color;
      branchPaint.strokeWidth = seg.width * (1 - t * 0.55);
      canvas.drawLine(seg.from, seg.to, branchPaint);
    }

    _paintLeaves(canvas, geometry.tips);
    if (showBlossoms) _paintBlossoms(canvas, geometry.tips);
    _paintFruits(canvas, geometry.tips);
  }

  void _paintSoil(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.soil
      ..style = PaintingStyle.fill;
    final soilY = size.height * 0.9;
    final w = size.width * 0.72;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, soilY + 2), width: w, height: w * 0.18), paint);
    paint.color = palette.soil.withValues(alpha: 0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width / 2, soilY + 6), width: w * 0.86, height: w * 0.16), paint);
  }

  void _paintLeaves(Canvas canvas, List<Offset> tips) {
    final paint = Paint()
      ..color = palette.leaf.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    for (final tip in tips) {
      final base = tip + const Offset(0, 2);
      final left = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx - 10, base.dy - 8, base.dx - 12, base.dy - 16)
        ..quadraticBezierTo(base.dx - 4, base.dy - 12, base.dx, base.dy - 8)
        ..close();
      final right = Path()
        ..moveTo(base.dx, base.dy)
        ..quadraticBezierTo(base.dx + 10, base.dy - 8, base.dx + 12, base.dy - 16)
        ..quadraticBezierTo(base.dx + 4, base.dy - 12, base.dx, base.dy - 8)
        ..close();
      canvas.drawPath(left, paint);
      canvas.drawPath(right, paint);
    }
  }

  void _paintBlossoms(Canvas canvas, List<Offset> tips) {
    final paint = Paint()..style = PaintingStyle.fill;
    final half = tips.length ~/ 2;
    for (var i = 0; i < half; i++) {
      final c = tips[i];
      paint.color = palette.blossom.withValues(alpha: 0.75);
      canvas.drawCircle(c + const Offset(0, -6), 3.2, paint);
      paint.color = palette.blossom;
      canvas.drawCircle(c + const Offset(0, -6), 1.6, paint);
    }
  }

  void _paintFruits(Canvas canvas, List<Offset> tips) {
    if (tips.isEmpty) return;
    final count = fruitCount.clamp(0, tips.length);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final c = tips[i];
      final radius = 5.5;
      paint.color = fruitColor;
      canvas.drawCircle(c + const Offset(0, -8), radius, paint);
      paint.color = fruitColor.withValues(alpha: 0.5);
      canvas.drawCircle(c + Offset(-1.5, -9.5), radius * 0.45, paint);
    }
  }

  @override
  bool shouldRepaint(covariant VinePainter old) {
    return old.seed != seed ||
        old.growth01 != growth01 ||
        old.branches != branches ||
        old.fruitCount != fruitCount ||
        old.fruitColor != fruitColor ||
        old.sway != sway ||
        old.palette != palette ||
        old.showBlossoms != showBlossoms;
  }
}
