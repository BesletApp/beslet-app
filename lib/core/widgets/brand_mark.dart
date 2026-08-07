import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The app's signature seed-to-maturity mark: a gold seedling sprouting
/// from a soil line. Used by the splash, onboarding and the home header so
/// the "seed → growth (ብስለት)" language stays consistent from first launch
/// onward. Colors resolve from the active palette unless [color] is given.
class BrandMark extends StatelessWidget {
  final double size;
  final Color? color;
  const BrandMark({super.key, this.size = 100, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.of(context).primary;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SeedlingPainter(c), child: const SizedBox()),
    );
  }
}

class _SeedlingPainter extends CustomPainter {
  final Color color;
  _SeedlingPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100; // scales the mark to the widget size
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * s
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final stem = Path();
    stem.moveTo(cx, cy + 24 * s);
    stem.cubicTo(cx - 2 * s, cy + 8 * s, cx + 3 * s, cy - 2 * s, cx, cy - 16 * s);
    canvas.drawPath(stem, paint);

    paint.style = PaintingStyle.fill;
    final leftLeaf = Path();
    leftLeaf.moveTo(cx, cy - 8 * s);
    leftLeaf.quadraticBezierTo(cx - 14 * s, cy - 10 * s, cx - 16 * s, cy - 22 * s);
    leftLeaf.quadraticBezierTo(cx - 8 * s, cy - 20 * s, cx, cy - 12 * s);
    leftLeaf.close();
    canvas.drawPath(leftLeaf, paint..color = color.withValues(alpha: 0.35));

    final rightLeaf = Path();
    rightLeaf.moveTo(cx, cy - 6 * s);
    rightLeaf.quadraticBezierTo(cx + 14 * s, cy - 12 * s, cx + 18 * s, cy - 24 * s);
    rightLeaf.quadraticBezierTo(cx + 10 * s, cy - 20 * s, cx, cy - 10 * s);
    rightLeaf.close();
    canvas.drawPath(rightLeaf, paint..color = color.withValues(alpha: 0.5));

    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2 * s;
    final ground = paint..color = color.withValues(alpha: 0.4);
    canvas.drawLine(
      Offset(cx - 18 * s, cy + 24 * s),
      Offset(cx + 18 * s, cy + 24 * s),
      ground,
    );

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 8 * s, cy + 28 * s), 1.5 * s, paint..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(Offset(cx + 6 * s, cy + 29 * s), 1.0 * s, paint..color = color.withValues(alpha: 0.25));
    canvas.drawCircle(Offset(cx, cy + 27 * s), 1.2 * s, paint..color = color.withValues(alpha: 0.25));
  }

  @override
  bool shouldRepaint(covariant _SeedlingPainter oldDelegate) => oldDelegate.color != color;
}