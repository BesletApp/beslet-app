import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/services/widget_service.dart' show LampLight;

/// Static movie-grade backdrop for the Growth Zone: multi-stop sky, sun or
/// moon glow, night stars, layered haze hills, a graded ground mound with the
/// vine's soft contact shadow, and a cinematic vignette. Fully deterministic
/// and cached as a [ui.Picture] so per-frame cost stays near zero.
class MovieBackdropPainter extends CustomPainter {
  final Color skyTop;
  final Color skyBottom;
  final LampLight light;
  final bool isDark;
  final Color soil;
  final int seed;

  const MovieBackdropPainter({
    required this.skyTop,
    required this.skyBottom,
    required this.light,
    required this.isDark,
    required this.soil,
    required this.seed,
  });

  static final Map<_BackdropKey, ui.Picture> _cache = {};
  static const int _max = 12;

  static ui.Picture pictureFor({
    required Color skyTop,
    required Color skyBottom,
    required LampLight light,
    required bool isDark,
    required Color soil,
    required int seed,
    required Size size,
  }) {
    final key = _BackdropKey(
      skyTop: skyTop,
      skyBottom: skyBottom,
      light: light,
      isDark: isDark,
      soil: soil,
      seed: seed,
      w: size.width,
      h: size.height,
    );
    final cached = _cache[key];
    if (cached != null) return cached;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    MovieBackdropPainter(
      skyTop: skyTop,
      skyBottom: skyBottom,
      light: light,
      isDark: isDark,
      soil: soil,
      seed: seed,
    )._paint(canvas, size);
    final picture = recorder.endRecording();
    _cache[key] = picture;
    if (_cache.length > _max) _cache.remove(_cache.keys.first);
    return picture;
  }

  @override
  void paint(Canvas canvas, Size size) => _paint(canvas, size);

  void _paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = _skyStops(w, h);

    // Sky: deep → teal → warm horizon.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, h),
          sky.stops,
          sky.positions,
        ),
    );

    // Painterly sky bands.
    final band = Paint()
      ..color = Color.lerp(skyBottom, Colors.white, 0.3)!.withValues(alpha: 0.10);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.42, w, h * 0.05), band);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.08), band);

    // Sun or moon + glow.
    final (x: sx, y: sy, disc: discColor, glow: glowColor, r: discR) =
        _lightBody(w, h);
    canvas.drawCircle(
      Offset(sx, sy),
      discR * 5.5,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(sx, sy),
          discR * 5.5,
          [glowColor.withValues(alpha: 0.55), glowColor.withValues(alpha: 0)],
        ),
    );
    canvas.drawCircle(Offset(sx, sy), discR, Paint()..color = discColor);

    if (light == LampLight.night) _paintStars(canvas, size);

    // Far hill + haze.
    final far = Color.lerp(skyBottom, skyTop, 0.32)!.withValues(alpha: 0.55);
    _hill(canvas, w, h, h * 0.62, far, h * 0.24, w * 0.18);
    final haze = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.66),
        Offset(0, h * 0.8),
        [Color.lerp(skyBottom, Colors.white, 0.4)!.withValues(alpha: 0.0), skyBottom.withValues(alpha: 0.55)],
      );
    canvas.drawRect(Rect.fromLTWH(0, h * 0.66, w, h * 0.16), haze);

    // Near hill (warm, closer).
    final near = Color.lerp(skyBottom, soil, 0.55)!;
    _hill(canvas, w, h, h * 0.74, near, h * 0.18, w * 0.34);

    // Deep-green undergrowth band (reference: dark forest base).
    final under = Color.lerp(near, const Color(0xFF173919), 0.5)!;
    _hill(canvas, w, h, h * 0.78, under, h * 0.14, w * 0.62);

    // Ground mound.
    final soilY = h * 0.9;
    final ground = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, soilY),
        Offset(0, h),
        [Color.lerp(soil, Colors.white, 0.18)!, Color.lerp(soil, Colors.black, 0.25)!],
      );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, soilY + h * 0.03), width: w * 0.82, height: h * 0.26),
      ground,
    );

    // Soft contact shadow under the vine.
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, soilY + 4), width: w * 0.3, height: w * 0.035),
      shadow,
    );

    // Golden light wash (sun-through-the-scene warmth).
    if (light != LampLight.night) {
      final (x: gx, y: gy, disc: _, glow: _, r: gr) = _lightBody(w, h);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(gx, gy),
            gr * 6.5,
            [
              const Color(0xFFF7D66A).withValues(alpha: 0.16),
              const Color(0xFFF7D66A).withValues(alpha: 0),
            ],
          ),
      );
    }

    // Cinematic vignette.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(w / 2, h * 0.42),
          math.max(w, h) * 0.75,
          [Colors.transparent, Colors.black.withValues(alpha: 0.16)],
          const [0.72, 1],
        ),
    );
  }

  ({List<Color> stops, List<double> positions}) _skyStops(double w, double h) {
    final mid = Color.lerp(skyTop, skyBottom, 0.55)!;
    switch (light) {
      case LampLight.night:
        return (stops: [skyTop, mid, skyBottom], positions: const [0, 0.55, 1]);
      case LampLight.noon:
        return (
          stops: [
            const Color(0xFF2B9FE0),
            const Color(0xFF7BBEE4),
            const Color(0xFFEAF3F2),
          ],
          positions: const [0, 0.55, 1],
        );
      case LampLight.dawn:
        return (
          stops: [
            const Color(0xFF3FA4E0),
            const Color(0xFFA8CEE8),
            const Color(0xFFF9E3B8),
          ],
          positions: const [0, 0.55, 1],
        );
      case LampLight.dusk:
        return (
          stops: [
            const Color(0xFF4A8FD0),
            const Color(0xFF9FB7E0),
            const Color(0xFFF0A05A),
          ],
          positions: const [0, 0.55, 1],
        );
    }
  }

  ({double x, double y, Color disc, Color glow, double r}) _lightBody(double w, double h) {
    switch (light) {
      case LampLight.dawn:
        return (
          x: w * 0.24,
          y: h * 0.5,
          disc: const Color(0xFFF8D97A),
          glow: const Color(0xFFF2C879),
          r: w * 0.085,
        );
      case LampLight.noon:
        return (
          x: w * 0.5,
          y: h * 0.12,
          disc: const Color(0xFFF7C948),
          glow: const Color(0xFFF7B733),
          r: w * 0.08,
        );
      case LampLight.dusk:
        return (
          x: w * 0.76,
          y: h * 0.46,
          disc: const Color(0xFFF2A65A),
          glow: const Color(0xFFE88A3C),
          r: w * 0.085,
        );
      case LampLight.night:
        return (
          x: w * 0.78,
          y: h * 0.14,
          disc: const Color(0xFFE8F0FA),
          glow: const Color(0xFFB8CEE8),
          r: w * 0.055,
        );
    }
  }

  void _paintStars(Canvas canvas, Size size) {
    final rng = math.Random(seed + 55);
    final paint = Paint();
    for (var i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.5;
      final a = 0.2 + rng.nextDouble() * 0.6;
      paint.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 0.7 + rng.nextDouble() * 0.8, paint);
    }
  }

  void _hill(Canvas canvas, double w, double h, double baseY, Color color, double peak, double spread) {
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, baseY)
      ..quadraticBezierTo(w * 0.5, baseY - peak, w, baseY)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant MovieBackdropPainter old) {
    return old.skyTop != skyTop ||
        old.skyBottom != skyBottom ||
        old.light != light ||
        old.isDark != isDark ||
        old.soil != soil ||
        old.seed != seed;
  }
}

class _BackdropKey {
  final Color skyTop;
  final Color skyBottom;
  final LampLight light;
  final bool isDark;
  final Color soil;
  final int seed;
  final double w;
  final double h;

  const _BackdropKey({
    required this.skyTop,
    required this.skyBottom,
    required this.light,
    required this.isDark,
    required this.soil,
    required this.seed,
    required this.w,
    required this.h,
  });

  @override
  bool operator ==(Object other) =>
      other is _BackdropKey &&
      other.skyTop == skyTop &&
      other.skyBottom == skyBottom &&
      other.light == light &&
      other.isDark == isDark &&
      other.soil == soil &&
      other.seed == seed &&
      other.w == w &&
      other.h == h;

  @override
  int get hashCode =>
      Object.hash(skyTop, skyBottom, light, isDark, soil, seed, w, h);
}
