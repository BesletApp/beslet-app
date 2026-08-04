import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/growth_content.dart';
import '../../../core/services/widget_service.dart';
import 'vine_painter.dart';

/// The living Vineyard: a self-contained animated scene (sky, lamp glow, vine,
/// weather particles, tappable fruit). It asks for nothing and reports nothing —
/// the vine simply grows on the journey's own clock.
class VineyardScene extends StatefulWidget {
  final int seed;
  final double growth01;
  final int branches;
  final int fruitCount;
  final Color fruitColor;
  final int? mood;
  final bool showBlossoms;
  final void Function(int fruitIndex)? onFruitTap;

  const VineyardScene({
    super.key,
    required this.seed,
    required this.growth01,
    required this.branches,
    required this.fruitCount,
    required this.fruitColor,
    this.mood,
    this.showBlossoms = false,
    this.onFruitTap,
  });

  @override
  State<VineyardScene> createState() => _VineyardSceneState();
}

class _VineyardSceneState extends State<VineyardScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _sway;
  late final AnimationController _montage;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sway = AnimationController(vsync: this, duration: const Duration(seconds: 7));
    _montage = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant VineyardScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood || oldWidget.growth01 != widget.growth01) {
      _syncAnimation();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final wasPaused = _paused;
    _paused = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached;
    if (_paused != wasPaused) _syncAnimation();
  }

  void _syncAnimation() {
    final reduced = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduced || _paused) {
      _sway.stop();
      _montage.stop();
      return;
    }
    if (!_sway.isAnimating) _sway.repeat();
    if (!_montage.isAnimating && _montage.value < 1) _montage.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sway.dispose();
    _montage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.of(context).disableAnimations;
    final target = widget.growth01.clamp(0.0, 1.0);
    final displayed =
        reduced ? target : target * Curves.easeInOutCubic.transform(_montage.value);
    final sway = reduced ? 0.0 : math.sin(_sway.value * math.pi * 2);
    final light = WidgetService.lightStateFor(DateTime.now());
    final atmosphere = GrowthContent.atmosphereFor(widget.mood, light);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? VinePalette.dark : VinePalette.light;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final geometry = buildVine(
            seed: widget.seed,
            growth01: displayed,
            branches: widget.branches,
            size: size,
            sway: sway,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [atmosphere.skyTop, atmosphere.skyBottom],
                  ),
                ),
              ),
              _LampGlow(light: light, isDark: isDark, size: size),
              CustomPaint(
                painter: VinePainter(
                  seed: widget.seed,
                  growth01: displayed,
                  branches: widget.branches,
                  fruitCount: widget.fruitCount,
                  fruitColor: widget.fruitColor,
                  palette: palette,
                  sway: sway,
                  showBlossoms: widget.showBlossoms,
                ),
              ),
              CustomPaint(
                painter: _ParticlePainter(
                  seed: widget.seed,
                  t: _montage.value < 1 ? 0 : (_sway.value),
                  particle: atmosphere.particle,
                  isDark: isDark,
                ),
              ),
              if (widget.onFruitTap != null)
                _FruitTapLayer(
                  tips: geometry.tips,
                  fruitCount: widget.fruitCount,
                  onFruitTap: widget.onFruitTap!,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LampGlow extends StatelessWidget {
  final LampLight light;
  final bool isDark;
  final Size size;

  const _LampGlow({required this.light, required this.isDark, required this.size});

  @override
  Widget build(BuildContext context) {
    final base = switch (light) {
      LampLight.dawn => const Color(0xFFF2C879),
      LampLight.noon => const Color(0xFFFBE8B2),
      LampLight.dusk => const Color(0xFFF2A65A),
      LampLight.night => const Color(0xFF8FB0E8),
    };
    final glow = base.withValues(alpha: isDark ? 0.6 : 0.45);
    final d = size.width * 0.5;
    return Positioned(
      top: size.height * 0.04 - d * 0.28,
      left: size.width * 0.5 - d * 0.5,
      width: d,
      height: d,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [glow, glow.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _FruitTapLayer extends StatelessWidget {
  final List<Offset> tips;
  final int fruitCount;
  final void Function(int fruitIndex) onFruitTap;

  const _FruitTapLayer({required this.tips, required this.fruitCount, required this.onFruitTap});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final count = fruitCount.clamp(0, tips.length);
    for (var i = 0; i < count; i++) {
      final pos = tips[i];
      children.add(
        Positioned(
          left: pos.dx - 24,
          top: pos.dy - 32,
          width: 48,
          height: 48,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onFruitTap(i),
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }
    return Stack(fit: StackFit.expand, children: children);
  }
}

/// Minimal weather: golden dust motes, night fireflies, or rain. Generated
/// deterministically from [seed] so it never feels noisy or tracked.
class _ParticlePainter extends CustomPainter {
  final int seed;
  final double t;
  final VineParticle particle;
  final bool isDark;

  const _ParticlePainter({
    required this.seed,
    required this.t,
    required this.particle,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (particle == VineParticle.clear) return;
    final rng = math.Random(seed);
    const count = 34;
    for (var i = 0; i < count; i++) {
      final baseX = rng.nextDouble();
      final baseY = rng.nextDouble();
      final speed = 0.02 + rng.nextDouble() * 0.05;
      final x = baseX * size.width;
      final y = (baseY + t * speed) % 1.0 * size.height;
      switch (particle) {
        case VineParticle.rain:
          final paint = Paint()
            ..color = const Color(0xFFDCE6F2).withValues(alpha: 0.4)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(x, y), Offset(x - 4, y + 12), paint);
        case VineParticle.dust:
          final paint = Paint()
            ..color = const Color(0xFFE8C56A).withValues(alpha: 0.5 + rng.nextDouble() * 0.3);
          canvas.drawCircle(Offset(x, y), 1 + rng.nextDouble() * 1.4, paint);
        case VineParticle.fireflies:
          final flicker = (math.sin(t * math.pi * 6 + i * 1.7) + 1) / 2;
          final paint = Paint()
            ..color = const Color(0xFFB8E070).withValues(alpha: 0.2 + flicker * 0.7);
          canvas.drawCircle(Offset(x, y), 1.6, paint);
        case VineParticle.clear:
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) {
    return old.seed != seed || old.t != t || old.particle != particle || old.isDark != isDark;
  }
}
