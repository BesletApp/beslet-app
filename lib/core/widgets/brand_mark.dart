import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The app's signature maturity mark: a golden, ripened round fruit on a
/// short growing branch with leaves, rooted in a soil line. It represents the
/// end of the growth arc — seed → maturity (ብስለት) → fruit. Used by the splash,
/// onboarding and the home header so the language stays consistent from first
/// launch onward. Colors resolve from the active palette unless [color] is
/// given.
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
      child: CustomPaint(painter: _FruitPainter(c), child: const SizedBox()),
    );
  }
}

class _FruitPainter extends CustomPainter {
  final Color color;
  _FruitPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100; // scales the mark to the widget size
    final cx = size.width / 2;
    final cy = size.height / 2;

    Color alpha(double a) => color.withValues(alpha: a);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ground branch rising from the soil line to the fruit.
    stroke.strokeWidth = 2.4 * s;
    final branch = Path();
    branch.moveTo(cx, cy + 24 * s);
    branch.quadraticBezierTo(cx - 3 * s, cy + 16 * s, cx - 2 * s, cy + 12 * s);
    canvas.drawPath(branch, stroke..color = alpha(0.6));

    // The golden round fruit (hero element).
    final fc = Offset(cx, cy - 5 * s);
    final r = 11 * s;

    final fill = Paint()..style = PaintingStyle.fill;
    fill.shader = RadialGradient(
      center: const Alignment(-0.35, -0.4),
      radius: 1.0,
      colors: [alpha(0.06), alpha(0.20)],
    ).createShader(Rect.fromCircle(center: fc, radius: r));
    canvas.drawCircle(fc, r, fill);

    // Rim + specular sheen so the fruit reads ripened.
    stroke.strokeWidth = 1.8 * s;
    canvas.drawCircle(fc, r, stroke..color = alpha(0.5));
    fill.shader = null;
    canvas.drawCircle(Offset(fc.dx - r * 0.34, fc.dy - r * 0.4), r * 0.2, fill..color = alpha(0.18));

    // Crown (calyx) + stalk at the top of the fruit.
    final ct = Offset(fc.dx, fc.dy - r);
    stroke.strokeWidth = 1.6 * s;
    canvas.drawLine(ct, Offset(fc.dx, fc.dy - r - 3.5 * s), stroke..color = alpha(0.55));
    final cp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * s
      ..strokeCap = StrokeCap.round
      ..color = alpha(0.5);
    canvas.drawLine(ct, Offset(ct.dx - 2.2 * s, ct.dy - 1.4 * s), cp);
    canvas.drawLine(ct, Offset(ct.dx + 2.2 * s, ct.dy - 1.4 * s), cp);
    canvas.drawLine(ct, Offset(ct.dx, ct.dy - 2.8 * s), cp);

    // Subtle seed hint near the fruit's base.
    canvas.drawCircle(Offset(fc.dx - 2.6 * s, fc.dy + r - 1.2 * s), 0.8 * s, fill..color = alpha(0.4));
    canvas.drawCircle(Offset(fc.dx + 2.4 * s, fc.dy + r - 1.0 * s), 0.7 * s, fill..color = alpha(0.35));

    // Leaves along the branch.
    final leftLeaf = Path();
    leftLeaf.moveTo(cx - 2 * s, cy + 12 * s);
    leftLeaf.quadraticBezierTo(cx - 11 * s, cy + 7 * s, cx - 14 * s, cy - 3 * s);
    leftLeaf.quadraticBezierTo(cx - 5 * s, cy - 1 * s, cx, cy + 9 * s);
    leftLeaf.close();
    canvas.drawPath(leftLeaf, fill..color = alpha(0.3));

    final rightLeaf = Path();
    rightLeaf.moveTo(cx + 2 * s, cy + 12 * s);
    rightLeaf.quadraticBezierTo(cx + 11 * s, cy + 7 * s, cx + 16 * s, cy - 1 * s);
    rightLeaf.quadraticBezierTo(cx + 6 * s, cy + 1 * s, cx + 3 * s, cy + 9 * s);
    rightLeaf.close();
    canvas.drawPath(rightLeaf, fill..color = alpha(0.45));

    // Leaf veins.
    stroke.strokeWidth = 1.2 * s;
    canvas.drawLine(Offset(cx - 3 * s, cy + 10 * s), Offset(cx - 8 * s, cy + 2 * s), stroke..color = alpha(0.3));
    canvas.drawLine(Offset(cx + 3 * s, cy + 10 * s), Offset(cx + 8 * s, cy + 2 * s), stroke..color = alpha(0.3));

    // Soil line + specks.
    stroke.strokeWidth = 2 * s;
    canvas.drawLine(Offset(cx - 18 * s, cy + 24 * s), Offset(cx + 18 * s, cy + 24 * s), stroke..color = alpha(0.4));
    fill.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx - 8 * s, cy + 28 * s), 1.5 * s, fill..color = alpha(0.25));
    canvas.drawCircle(Offset(cx + 6 * s, cy + 29 * s), 1.0 * s, fill..color = alpha(0.25));
    canvas.drawCircle(Offset(cx, cy + 27 * s), 1.2 * s, fill..color = alpha(0.25));
  }

  @override
  bool shouldRepaint(covariant _FruitPainter oldDelegate) => oldDelegate.color != color;
}