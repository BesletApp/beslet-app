import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Deterministic, procedural vine geometry. The same [seed] always yields the
/// same living vine — pure math, offline, untrackable. [sway] adds a tiny
/// time-based wiggle without changing the underlying structure. [fullness]
/// (0..1) adds interior sub-branches for a lush, movie-style canopy; the
/// default keeps the classic spare look (MiniVine).
VineGeometry buildVine({
  required int seed,
  required double growth01,
  required int branches,
  required Size size,
  double sway = 0,
  double fullness = 0,
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
    fullness,
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
  double fullness,
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
    _grow(rng, to, depth - 1, angle, len, width * 0.72, sway, fullness, segments, tips, size);
  }
  if (fullness > 0 && depth >= 2 && rng.nextDouble() < 0.7 * fullness) {
    final midAngle = baseAngle + (rng.nextDouble() - 0.5) * 0.55;
    final midLen = length * (0.5 + rng.nextDouble() * 0.16);
    final to = from + Offset(math.cos(midAngle), math.sin(midAngle)) * midLen;
    if (to.dy >= -24) {
      segments.add(VineSegment(from: from, to: to, width: width * 0.7, depth: depth));
      _grow(rng, to, depth - 1, midAngle, midLen, width * 0.62, sway, fullness, segments, tips, size);
    }
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

/// The static skeleton (soil + trunk + branches) is cached as a [ui.Picture]
/// so per-frame painting only replays the recorded canvas and draws the small
/// living parts (leaves, fruits, dew) — cheap for low-end devices.
class _SkeletonCache {
  static final Map<_SkeletonKey, ui.Picture> _cache = {};
  static const int _max = 10;

  static ui.Picture pictureFor({
    required int seed,
    required double growth01,
    required int branches,
    required Size size,
    required VinePalette palette,
    required double branchOpen,
  }) {
    final key = _SkeletonKey(
      seed: seed,
      growth: (growth01 * 100).roundToDouble() / 100,
      branches: branches,
      width: size.width,
      height: size.height,
      paletteHash: palette.hashCode,
      branchOpenBucket: (branchOpen * 100).round(),
    );
    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _drawSkeleton(canvas, size, palette, branchOpen, seed, growth01, branches);
    final picture = recorder.endRecording();
    _cache[key] = picture;
    if (_cache.length > _max) {
      _cache.remove(_cache.keys.first);
    }
    return picture;
  }

  static void _drawSkeleton(
    Canvas canvas,
    Size size,
    VinePalette palette,
    double branchOpen,
    int seed,
    double growth01,
    int branches,
  ) {
    final geometry = buildVine(
      seed: seed,
      growth01: growth01,
      branches: branches,
      size: size,
    );
    _paintSoil(canvas, size, palette, branchOpen);
    final branchPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final seg in geometry.segments) {
      final t = (seg.depth / 4).clamp(0.0, 1.0);
      final color = Color.lerp(palette.trunk, palette.branch, t)!;
      branchPaint.color = color;
      branchPaint.strokeWidth = seg.width * (1 - t * 0.55) * (0.92 + branchOpen * 0.16);
      canvas.drawLine(seg.from, seg.to, branchPaint);
    }
    _paintOpenArms(canvas, size, palette, branchOpen);
  }

  static void _paintSoil(Canvas canvas, Size size, VinePalette palette, double hydration) {
    final soilY = size.height * 0.9;
    final cx = size.width / 2;
    final w = size.width * 0.72;
    final wet = (hydration - 0.6).clamp(0.0, 1.0);

    final paint = Paint()..style = PaintingStyle.fill;

    paint.color = palette.soil;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, soilY + 2), width: w, height: w * 0.18),
      paint,
    );

    paint.color = Color.lerp(palette.soil.withValues(alpha: 0.4), palette.soil, wet)!;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, soilY + 6), width: w * 0.86, height: w * 0.16),
      paint,
    );

    if (wet > 0.15) {
      paint.color = const Color(0xFF2E4A22).withValues(alpha: wet * 0.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(cx, soilY - 2), width: w * 0.55, height: w * 0.09),
        paint,
      );
    }

    if (wet > 0.5) {
      paint.color = const Color(0xFFBFE8F7).withValues(alpha: (wet - 0.5) * 0.85);
      const drops = 5;
      for (var i = 0; i < drops; i++) {
        final dx = cx - w * 0.2 + (w * 0.4) * i / (drops - 1) + math.sin(i * 3.7) * 5;
        final dy = soilY - 5 - ((i % 2) * 7);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(dx, dy), width: 6, height: 3.5),
          paint,
        );
      }
    }
  }

  /// Fellowship opens the vine outward: two gentle arms reach from the canopy
  /// when a connection is made. A structural change, not a tint.
  static void _paintOpenArms(Canvas canvas, Size size, VinePalette palette, double branchOpen) {
    final open = (branchOpen - 0.5).clamp(0.0, 1.0);
    if (open <= 0) return;
    final cx = size.width / 2;
    final baseY = size.height * 0.6;
    final paint = Paint()
      ..color = palette.branch.withValues(alpha: 0.55 + open * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 30, baseY),
      Offset(cx - 120 * open, baseY - 34 * open),
      paint,
    );
    canvas.drawLine(
      Offset(cx + 30, baseY),
      Offset(cx + 120 * open, baseY - 34 * open),
      paint,
    );
  }
}

class _SkeletonKey {
  final int seed;
  final double growth;
  final int branches;
  final double width;
  final double height;
  final int paletteHash;
  final int branchOpenBucket;

  const _SkeletonKey({
    required this.seed,
    required this.growth,
    required this.branches,
    required this.width,
    required this.height,
    required this.paletteHash,
    required this.branchOpenBucket,
  });

  @override
  bool operator ==(Object other) =>
      other is _SkeletonKey &&
      other.seed == seed &&
      other.growth == growth &&
      other.branches == branches &&
      other.width == width &&
      other.height == height &&
      other.paletteHash == paletteHash &&
      other.branchOpenBucket == branchOpenBucket;

  @override
  int get hashCode =>
      Object.hash(seed, growth, branches, width, height, paletteHash, branchOpenBucket);
}

/// Paints the living vine. Ripening is visual only: [fruitColor] is expected to
/// be ramped from green to gold by the caller as the journey grows. [bend] is a
/// horizontal shear (bottom pinned at the soil) so physical spring gestures and
/// the perpetual sway move the whole canopy without rebuilding the skeleton.
class VinePainter extends CustomPainter {
  final int seed;
  final double growth01;
  final int branches;
  final int fruitCount;
  final Color fruitColor;
  final double sway;
  final VinePalette palette;
  final bool showBlossoms;
  final double hydration;
  final double leafGlow;
  final double branchOpen;
  final double ripen;
  final double droop;
  final double blossomOpen;
  final double bend;
  final double lifeT;
  final double flutterAmt;
  final double dew;
  final double wilt;

  const VinePainter({
    required this.seed,
    required this.growth01,
    required this.branches,
    required this.fruitCount,
    required this.fruitColor,
    required this.palette,
    this.sway = 0,
    this.showBlossoms = false,
    this.hydration = 1,
    this.leafGlow = 1,
    this.branchOpen = 1,
    this.ripen = 0,
    this.droop = 0,
    this.blossomOpen = 1,
    this.bend = 0,
    this.lifeT = 0,
    this.flutterAmt = 1,
    this.dew = 0,
    this.wilt = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = buildVine(
      seed: seed,
      growth01: growth01,
      branches: branches,
      size: size,
    );

    final skeleton = _SkeletonCache.pictureFor(
      seed: seed,
      growth01: growth01,
      branches: branches,
      size: size,
      palette: palette,
      branchOpen: branchOpen,
    );

    final soilY = size.height * 0.9;
    canvas.save();
    canvas.translate(0, soilY);
    canvas.skew(bend, 0);
    canvas.translate(0, -soilY);
    canvas.drawPicture(skeleton);
    _paintLeaves(canvas, geometry.tips);
    if (showBlossoms) _paintBlossoms(canvas, geometry.tips);
    _paintFruits(canvas, geometry.tips);
    if (dew > 0.02) _paintDew(canvas, geometry.tips);
    canvas.restore();
  }

  void _paintLeaves(Canvas canvas, List<Offset> tips) {
    final tinted = Color.lerp(palette.leaf, const Color(0xFFD9F0A8), leafGlow * 0.4)!;
    final vivid = Color.lerp(palette.leaf, tinted, hydration * 0.5)!;
    final dulled =
        Color.lerp(vivid, Color.lerp(palette.leaf, const Color(0xFF7A6A50), 0.4)!, wilt)!;
    final paint = Paint()
      ..color = dulled.withValues(alpha: 0.9 - wilt * 0.2)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < tips.length; i++) {
      final tip = tips[i];
      final droopDir = i.isEven ? 1.0 : -1.0;
      final flutter = math.sin(lifeT * 6 + i * 1.7) * 0.10 * flutterAmt;
      final wiltAngle = wilt * 0.7 * droopDir;
      canvas.save();
      canvas.translate(tip.dx, tip.dy + 2);
      canvas.rotate(droop * droopDir + flutter + wiltAngle);
      final left = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-10, -8, -12, -16)
        ..quadraticBezierTo(-4, -12, 0, -8)
        ..close();
      final right = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(10, -8, 12, -16)
        ..quadraticBezierTo(4, -12, 0, -8)
        ..close();
      canvas.drawPath(left, paint);
      canvas.drawPath(right, paint);
      canvas.restore();
    }
  }

  void _paintBlossoms(Canvas canvas, List<Offset> tips) {
    final paint = Paint()..style = PaintingStyle.fill;
    final open = 0.3 + blossomOpen * 0.7;
    final half = tips.length ~/ 2;
    for (var i = 0; i < half; i++) {
      final c = tips[i];
      final sway = math.sin(lifeT * 5 + i * 2.1) * 0.5 * flutterAmt;
      paint.color = palette.blossom.withValues(alpha: 0.75);
      canvas.drawCircle(c + Offset(sway, -6), 3.2 * open, paint);
      paint.color = palette.blossom;
      canvas.drawCircle(c + Offset(sway, -6), 1.6 * open, paint);
    }
  }

  void _paintFruits(Canvas canvas, List<Offset> tips) {
    if (tips.isEmpty) return;
    final count = fruitCount.clamp(0, tips.length);
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < count; i++) {
      final c = tips[i];
      final radius = 5.5 * (0.8 + branchOpen * 0.4);
      final squash = 1 + 0.12 * math.sin(lifeT * 4 + i * 2.3);
      paint.color = fruitColor;
      canvas.drawOval(
        Rect.fromCenter(
          center: c + const Offset(0, -8),
          width: radius * 2 * squash,
          height: radius * 2 * (2 - squash),
        ),
        paint,
      );
      paint.color = fruitColor.withValues(alpha: 0.5);
      canvas.drawCircle(c + Offset(-1.5, -9.5), radius * 0.45, paint);
      if (ripen > 0.4) {
        paint.color = const Color(0xFFF8E26A).withValues(alpha: (ripen - 0.4) * 0.5);
        canvas.drawCircle(c + const Offset(0, -8), radius + 4, paint);
      }
    }
  }

  /// Dew sparkles on the leaves at dawn — little flashes of morning light.
  void _paintDew(Canvas canvas, List<Offset> tips) {
    final paint = Paint();
    for (var i = 0; i < tips.length; i++) {
      if (i % 3 != 0) continue;
      final twinkle = math.sin(lifeT * 5 + i * 1.3);
      if (twinkle < 0.4) continue;
      paint.color = const Color(0xFFFFFFFF).withValues(alpha: dew * (twinkle - 0.4) * 0.9);
      canvas.drawCircle(tips[i] + const Offset(2, -12), 1.6, paint);
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
        old.showBlossoms != showBlossoms ||
        old.hydration != hydration ||
        old.leafGlow != leafGlow ||
        old.branchOpen != branchOpen ||
        old.ripen != ripen ||
        old.droop != droop ||
        old.blossomOpen != blossomOpen ||
        old.bend != bend ||
        old.lifeT != lifeT ||
        old.flutterAmt != flutterAmt ||
        old.dew != dew ||
        old.wilt != wilt;
  }
}
