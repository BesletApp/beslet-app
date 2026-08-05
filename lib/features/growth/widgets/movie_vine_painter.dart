import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'vine_painter.dart' show buildVine, VineGeometry, VinePalette;

/// Pixar-style renderer for the Growth Zone vine: tapered curvy branches with
/// toon shading, a layered cel-shaded canopy, detailed leaves, glossy fruits,
/// and five-petal blossoms. Light comes from the top-left, coherent with the
/// backdrop. Reuses [buildVine] geometry so fruit taps stay aligned.
class MovieVinePainter extends CustomPainter {
  final int seed;
  final double growth01;
  final int branches;
  final int fruitCount;
  final Color fruitColor;
  final VinePalette palette;
  final double sway;
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
  final double fullness;

  const MovieVinePainter({
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
    this.fullness = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final geometry = buildVine(
      seed: seed,
      growth01: growth01,
      branches: branches,
      size: size,
      fullness: fullness,
    );
    final soilY = size.height * 0.9;
    canvas.save();
    canvas.translate(0, soilY);
    canvas.skew(bend, 0);
    canvas.translate(0, -soilY);

    _paintSoilWet(canvas, size, soilY);
    final canopy = _canopyPoints(geometry, size);
    _paintCanopyBack(canvas, canopy, size);
    _paintBranches(canvas, geometry);
    _paintCanopyMid(canvas, canopy, size);
    _paintFrontLeaves(canvas, geometry.tips);
    if (showBlossoms) _paintBlossoms(canvas, geometry.tips);
    _paintFruits(canvas, geometry.tips);
    if (dew > 0.02) _paintDew(canvas, geometry.tips);
    canvas.restore();
  }

  Color _leafBase() {
    final vivid = Color.lerp(palette.leaf, const Color(0xFFD9F0A8), leafGlow * 0.25)!;
    final dulled = Color.lerp(
      vivid,
      Color.lerp(palette.leaf, const Color(0xFF7A6A50), 0.5)!,
      wilt,
    )!;
    return dulled;
  }

  List<Offset> _canopyPoints(VineGeometry geometry, Size size) {
    final pts = <Offset>[];
    for (final seg in geometry.segments) {
      if (seg.depth >= 1) {
        pts.add(Offset.lerp(seg.from, seg.to, 0.35)!);
        pts.add(Offset.lerp(seg.from, seg.to, 0.65)!);
      }
    }
    pts.addAll(geometry.tips);
    return pts;
  }

  // ─── Branches: tapered, curvy, toon-shaded ──────────────────────────────

  void _paintBranches(Canvas canvas, VineGeometry geometry) {
    final lightDir = const Offset(-0.7, -0.7);
    for (final seg in geometry.segments) {
      final t = (seg.depth / 4).clamp(0.0, 1.0);
      final base = Color.lerp(
        Color.lerp(palette.trunk, const Color(0xFF8A5A1E), 0.55)!,
        Color.lerp(palette.branch, const Color(0xFFB77407), 0.35)!,
        t,
      )!;
      final w0 = seg.width * (0.92 + branchOpen * 0.16);
      final w1 = w0 * 0.5;
      final dir = seg.to - seg.from;
      final len = dir.distance;
      if (len < 0.5) continue;
      final n = Offset(-dir.dy / len, dir.dx / len);
      final toward = lightDir.dx * n.dx + lightDir.dy * n.dy;
      final lit = toward >= 0 ? n : Offset(-n.dx, -n.dy);
      final a = seg.from;
      final b = seg.to;

      final path = Path()
        ..moveTo(a.dx + lit.dx * w0 / 2, a.dy + lit.dy * w0 / 2)
        ..lineTo(b.dx + lit.dx * w1 / 2, b.dy + lit.dy * w1 / 2)
        ..quadraticBezierTo(
            b.dx + lit.dx * w1 * 0.4, b.dy + lit.dy * w1 * 0.4, b.dx, b.dy)
        ..quadraticBezierTo(
            b.dx - lit.dx * w1 * 0.4, b.dy - lit.dy * w1 * 0.4,
            b.dx - lit.dx * w1 / 2, b.dy - lit.dy * w1 / 2)
        ..lineTo(a.dx - lit.dx * w0 / 2, a.dy - lit.dy * w0 / 2)
        ..quadraticBezierTo(
            a.dx - lit.dx * w0 * 0.25, a.dy - lit.dy * w0 * 0.25,
            a.dx + lit.dx * w0 * 0.12, a.dy + lit.dy * w0 * 0.12)
        ..close();

      canvas.drawPath(path, Paint()..color = base);

      // Shade crescent on the unlit side.
      final shade = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(base, const Color(0xFF3E2608), 0.35)!.withValues(alpha: 0.5)
        ..strokeWidth = w0 * 0.7;
      canvas.drawLine(a - lit * (w0 * 0.1), b - lit * (w1 * 0.1), shade);

      // Rim light on the lit side.
      final rim = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(base, const Color(0xFFD99A3C), 0.6)!.withValues(alpha: 0.7)
        ..strokeWidth = w0 * 0.32;
      canvas.drawLine(a + lit * (w0 * 0.05), b + lit * (w1 * 0.05), rim);
    }
  }

  // ─── Canopy: layered cel-shaded foliage clusters ────────────────────────

  void _drawBlob(Canvas canvas, Offset c, double r, Color color, double alpha) {
    final paint = Paint()..color = color.withValues(alpha: alpha);
    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(c + Offset(-r * 0.55, r * 0.22), r * 0.78, paint);
    canvas.drawCircle(c + Offset(r * 0.55, r * 0.22), r * 0.78, paint);
    canvas.drawCircle(c + Offset(0, -r * 0.42), r * 0.6, paint);
    canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.15), r * 0.5, paint);
    canvas.drawCircle(c + Offset(r * 0.3, -r * 0.15), r * 0.5, paint);
  }

  Color _greenAt(double v, {required double shadow, required double light}) {
    final base = _leafBase();
    return Color.lerp(
      Color.lerp(base, const Color(0xFF1E4A20), shadow)!,
      Color.lerp(base, const Color(0xFFE8D66A), light)!,
      v,
    )!;
  }

  void _paintCanopyBack(Canvas canvas, List<Offset> pts, Size size) {
    if (pts.isEmpty) return;
    final rng = math.Random(seed + 7);
    final r0 = size.height * 0.075 * (0.55 + growth01 * 0.5);
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final r = r0 * (0.8 + rng.nextDouble() * 0.5);
      final fl = _flutter(i, r);
      final c = p + Offset(r * 0.14 + fl.dx, r * 0.2 + fl.dy);
      final base = _greenAt(rng.nextDouble(), shadow: 0.42 + rng.nextDouble() * 0.1, light: 0.02);
      _drawBlob(canvas, c, r, base, 0.95);
    }
  }

  void _paintCanopyMid(Canvas canvas, List<Offset> pts, Size size) {
    if (pts.isEmpty) return;
    final rng = math.Random(seed + 9);
    final r0 = size.height * 0.075 * (0.55 + growth01 * 0.5);
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      final r = r0 * (0.7 + rng.nextDouble() * 0.4);
      final fl = _flutter(i, r);
      final c = p + Offset(-r * 0.08 + fl.dx, -r * 0.1 + fl.dy);
      final base = _greenAt(rng.nextDouble(), shadow: 0.18 + rng.nextDouble() * 0.14, light: 0.1 + rng.nextDouble() * 0.1);
      _drawBlob(canvas, c, r, base, 0.98);
      // Lit highlight on the upper-left of the cluster.
      final hl = Paint()
        ..color = Color.lerp(base, Colors.white, 0.35)!.withValues(alpha: 0.5);
      canvas.drawCircle(c + Offset(-r * 0.3, -r * 0.34), r * 0.34, hl);
      // Golden sun-dapple on the lit side, stronger when the Word is bright.
      if (leafGlow > 0.3 && rng.nextDouble() < 0.35 * leafGlow) {
        final gold = Paint()
          ..color = const Color(0xFFF3D66A).withValues(alpha: 0.55);
        canvas.drawCircle(
          c + Offset(-r * (0.15 + rng.nextDouble() * 0.25), -r * (0.15 + rng.nextDouble() * 0.25)),
          r * (0.12 + rng.nextDouble() * 0.12),
          gold,
        );
      }
    }
  }

  Offset _flutter(int i, double r) {
    final amt = r * 0.06 * flutterAmt;
    return Offset(
      math.sin(lifeT * 2 + i * 1.3) * amt,
      math.cos(lifeT * 1.7 + i * 0.9) * amt * 0.7,
    );
  }

  void _paintFrontLeaves(Canvas canvas, List<Offset> tips) {
    final goldTint = 0.25 + leafGlow * 0.25;
    final base = Color.lerp(_leafBase(), const Color(0xFFE8E26A), goldTint)!;
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < tips.length; i++) {
      final tip = tips[i];
      final droopDir = i.isEven ? 1.0 : -1.0;
      final flutter = math.sin(lifeT * 6 + i * 1.7) * 0.12 * flutterAmt;
      final wiltAngle = wilt * 0.6 * droopDir;
      canvas.save();
      canvas.translate(tip.dx, tip.dy + 2);
      canvas.rotate(droop * droopDir + flutter + wiltAngle);
      paint.color = base.withValues(alpha: 0.95 - wilt * 0.15);
      final leaf = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(-8, -6, 0, -15)
        ..quadraticBezierTo(8, -6, 0, 0)
        ..close();
      canvas.drawPath(leaf, paint);
      // vein
      final vein = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = Color.lerp(base, Colors.white, 0.5)!.withValues(alpha: 0.5)
        ..strokeWidth = 0.8;
      canvas.drawLine(Offset(0, -2), Offset(0, -11), vein);
      canvas.restore();
    }
  }

  void _paintBlossoms(Canvas canvas, List<Offset> tips) {
    final petal = Paint()..style = PaintingStyle.fill;
    final center = Paint()..color = const Color(0xFFF4C73A);
    final half = tips.length ~/ 2;
    for (var i = 0; i < half; i++) {
      final c = tips[i];
      final sway2 = math.sin(lifeT * 5 + i * 2.1) * 0.5 * flutterAmt;
      final pos = c + Offset(sway2, -6);
      final open = 0.3 + blossomOpen * 0.7;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      petal.color = palette.blossom.withValues(alpha: 0.85);
      for (var k = 0; k < 5; k++) {
        canvas.rotate(math.pi * 2 / 5);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, -3.2 * open), width: 4.4 * open, height: 3.4 * open), petal);
      }
      canvas.drawCircle(Offset.zero, 1.4 * open, center);
      canvas.restore();
    }
  }

  void _paintFruits(Canvas canvas, List<Offset> tips) {
    if (tips.isEmpty) return;
    final count = fruitCount.clamp(0, tips.length);
    final ripeAmt = (ripen - 0.4).clamp(0.0, 1.0);
    for (var i = 0; i < count; i++) {
      final c = tips[i];
      final radius = 5.5 * (0.8 + branchOpen * 0.4) * (1 + ripeAmt * 0.18);
      final squash = 1 + 0.12 * math.sin(lifeT * 4 + i * 2.3);
      final pos = c + const Offset(0, -8);

      // soft contact shadow
      final shadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5);
      canvas.drawOval(
        Rect.fromCenter(center: pos + Offset(0, radius), width: radius * 2, height: radius * 0.8),
        shadow,
      );

      // glossy body — green→gold ramp, warmer as it ripens.
      final body = Color.lerp(fruitColor, const Color(0xFFF5C132), ripeAmt * 0.6)!;
      final shader = ui.Gradient.radial(
        pos + Offset(-radius * 0.4, -radius * 0.45),
        radius * 1.5,
        [
          Color.lerp(body, Colors.white, 0.55)!,
          body,
          Color.lerp(body, const Color(0xFF9A5A10), 0.55)!,
        ],
        [0, 0.45, 1],
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: pos,
          width: radius * 2 * squash,
          height: radius * 2 * (2 - squash),
        ),
        Paint()..shader = shader,
      );

      // specular
      final spec = Paint()..color = Colors.white.withValues(alpha: 0.85);
      canvas.drawCircle(pos + Offset(-radius * 0.35, -radius * 0.4), radius * 0.22, spec);

      // stem
      final stem = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7A5C38)
        ..strokeWidth = 1.2;
      canvas.drawLine(pos + Offset(0, -radius * 0.4), pos + Offset(1, -radius * 0.9), stem);

      if (ripeAmt > 0) {
        final halo = Paint()
          ..color = const Color(0xFFF8E26A).withValues(alpha: ripeAmt * 0.45);
        canvas.drawCircle(pos, radius + 4 + ripeAmt * 3, halo);
      }
    }
  }

  void _paintDew(Canvas canvas, List<Offset> tips) {
    final glint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.9;
    for (var i = 0; i < tips.length; i++) {
      if (i % 3 != 0) continue;
      final twinkle = math.sin(lifeT * 5 + i * 1.3);
      if (twinkle < 0.4) continue;
      final alpha = dew * (twinkle - 0.4) * 1.1;
      final pos = tips[i] + const Offset(2, -12);
      glint.color = const Color(0xFFFFFFFF).withValues(alpha: alpha.clamp(0.0, 0.9));
      canvas.drawLine(pos + const Offset(-3, 0), pos + const Offset(3, 0), glint);
      canvas.drawLine(pos + const Offset(0, -3), pos + const Offset(0, 3), glint);
    }
  }

  void _paintSoilWet(Canvas canvas, Size size, double soilY) {
    final wet = (hydration - 0.6).clamp(0.0, 1.0);
    if (wet <= 0.15) return;
    final cx = size.width / 2;
    final w = size.width * 0.72;
    final dark = Paint()
      ..color = const Color(0xFF2E4A22).withValues(alpha: wet * 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, soilY - 2), width: w * 0.55, height: w * 0.09),
      dark,
    );
    if (wet > 0.5) {
      final drops = Paint()
        ..color = const Color(0xFFBFE8F7).withValues(alpha: (wet - 0.5) * 0.85);
      const n = 5;
      for (var i = 0; i < n; i++) {
        final dx = cx - w * 0.2 + (w * 0.4) * i / (n - 1) + math.sin(i * 3.7) * 5;
        final dy = soilY - 5 - ((i % 2) * 7);
        canvas.drawOval(Rect.fromCenter(center: Offset(dx, dy), width: 6, height: 3.5), drops);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MovieVinePainter old) {
    return old.seed != seed ||
        old.growth01 != growth01 ||
        old.branches != branches ||
        old.fruitCount != fruitCount ||
        old.fruitColor != fruitColor ||
        old.palette != palette ||
        old.sway != sway ||
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
        old.wilt != wilt ||
        old.fullness != fullness;
  }
}
