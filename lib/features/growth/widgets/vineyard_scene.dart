import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/services/growth_content.dart';
import '../../../core/services/scene_event_bus.dart';
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
  final double hydration;
  final double leafGlow;
  final double branchOpen;
  final double ripen;
  final SceneEventBus? eventSource;
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
    this.hydration = 1,
    this.leafGlow = 1,
    this.branchOpen = 1,
    this.ripen = 0,
    this.eventSource,
    this.onFruitTap,
  });

  @override
  State<VineyardScene> createState() => _VineyardSceneState();
}

class _VineyardSceneState extends State<VineyardScene>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _sway;
  late final AnimationController _montage;
  late final AnimationController _burst;
  SceneEventType? _activeType;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sway = AnimationController(vsync: this, duration: const Duration(seconds: 7));
    _montage = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _sway.addListener(_onTicker);
    _montage.addListener(_onTicker);
    widget.eventSource?.addListener(_onSceneEvent);
  }

  void _onTicker() {
    if (mounted) setState(() {});
  }

  void _onSceneEvent() {
    final event = widget.eventSource?.value;
    if (event == null) return;
    _activeType = event.type;
    widget.eventSource?.markRecappedThrough(event.id);
    _burst.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant VineyardScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventSource != widget.eventSource) {
      oldWidget.eventSource?.removeListener(_onSceneEvent);
      widget.eventSource?.addListener(_onSceneEvent);
    }
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
    _sway.removeListener(_onTicker);
    _montage.removeListener(_onTicker);
    widget.eventSource?.removeListener(_onSceneEvent);
    _sway.dispose();
    _montage.dispose();
    _burst.dispose();
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
    final mood = widget.mood;
    final droop = mood != null && mood <= 2 ? 0.4 : 0.0;
    final blossomOpen = mood != null && mood >= 4 ? 1.0 : 0.7;
    final burst01 = reduced ? 0.0 : _burst.value;
    final burstType = _activeType;

    return RepaintBoundary(
      child: ClipRRect(
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
            return _TweenedVitals(
              hydration: widget.hydration,
              leafGlow: widget.leafGlow,
              branchOpen: widget.branchOpen,
              ripen: widget.ripen,
              builder: (context, hydration, leafGlow, branchOpen, ripen) {
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
                    _LampGlow(light: light, isDark: isDark, size: size, boost: leafGlow),
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
                        hydration: hydration,
                        leafGlow: leafGlow,
                        branchOpen: branchOpen,
                        ripen: ripen,
                        droop: droop,
                        blossomOpen: blossomOpen,
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
                    if (burst01 > 0 && burstType != null)
                      CustomPaint(
                        painter: _BurstPainter(
                          t: burst01,
                          type: burstType,
                          isDark: isDark,
                          color: palette.leaf,
                          soilY: size.height * 0.9,
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
            );
          },
        ),
      ),
    );
  }
}

/// Tweens the four vitality channels so a discipline visibly *arrives* — the
/// soil darkens, the lamp warms, the arms open, the fruit swells — instead of
/// snapping between sub-threshold values. Resting states stay discrete.
class _TweenedVitals extends StatefulWidget {
  final double hydration;
  final double leafGlow;
  final double branchOpen;
  final double ripen;
  final Widget Function(
    BuildContext context,
    double hydration,
    double leafGlow,
    double branchOpen,
    double ripen,
  ) builder;

  const _TweenedVitals({
    required this.hydration,
    required this.leafGlow,
    required this.branchOpen,
    required this.ripen,
    required this.builder,
  });

  @override
  State<_TweenedVitals> createState() => _TweenedVitalsState();
}

class _TweenedVitalsState extends State<_TweenedVitals>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _hydration;
  late Animation<double> _leafGlow;
  late Animation<double> _branchOpen;
  late Animation<double> _ripen;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _apply(
      widget.hydration,
      widget.leafGlow,
      widget.branchOpen,
      widget.ripen,
    );
  }

  @override
  void didUpdateWidget(_TweenedVitals oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hydration != widget.hydration ||
        oldWidget.leafGlow != widget.leafGlow ||
        oldWidget.branchOpen != widget.branchOpen ||
        oldWidget.ripen != widget.ripen) {
      _apply(
        oldWidget.hydration,
        oldWidget.leafGlow,
        oldWidget.branchOpen,
        oldWidget.ripen,
      );
      _controller.forward(from: 0);
    }
  }

  void _apply(double fromH, double fromG, double fromB, double fromR) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _hydration = Tween<double>(begin: fromH, end: widget.hydration).animate(curved);
    _leafGlow = Tween<double>(begin: fromG, end: widget.leafGlow).animate(curved);
    _branchOpen = Tween<double>(begin: fromB, end: widget.branchOpen).animate(curved);
    _ripen = Tween<double>(begin: fromR, end: widget.ripen).animate(curved);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => widget.builder(
        context,
        _hydration.value,
        _leafGlow.value,
        _branchOpen.value,
        _ripen.value,
      ),
    );
  }
}

class _LampGlow extends StatelessWidget {
  final LampLight light;
  final bool isDark;
  final Size size;
  final double boost;

  const _LampGlow({required this.light, required this.isDark, required this.size, this.boost = 0});

  @override
  Widget build(BuildContext context) {
    final base = switch (light) {
      LampLight.dawn => const Color(0xFFF2C879),
      LampLight.noon => const Color(0xFFFBE8B2),
      LampLight.dusk => const Color(0xFFF2A65A),
      LampLight.night => const Color(0xFF8FB0E8),
    };
    final glow = base.withValues(
      alpha: ((isDark ? 0.6 : 0.45) + boost * 0.35).clamp(0.0, 1.0),
    );
    final d = size.width * (0.5 + boost * 0.18);
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

/// A short, gentle gesture drawn over the vine when a discipline is logged:
/// water falling to the soil, a light pulse, a spreading bloom, or a glow ring.
class _BurstPainter extends CustomPainter {
  final double t;
  final SceneEventType type;
  final bool isDark;
  final Color color;
  final double soilY;

  const _BurstPainter({
    required this.t,
    required this.type,
    required this.isDark,
    required this.color,
    required this.soilY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ease = Curves.easeOutCubic.transform(t);
    final fade = 1.0 - t;

    switch (type) {
      case SceneEventType.water:
        final paint = Paint()
          ..color = const Color(0xFFB8E0F2).withValues(alpha: 0.5 * fade)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 3; i++) {
          final dx = (i - 1) * 14.0;
          final topY = 20.0 + i * 6.0;
          final drop = t * (size.height * 0.6);
          canvas.drawLine(
            Offset(center.dx + dx, topY + drop),
            Offset(center.dx + dx, topY + drop + 12),
            paint,
          );
        }
        final ring = Paint()
          ..color = const Color(0xFFB8E0F2).withValues(alpha: 0.5 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, soilY),
            width: 40 + ease * 140,
            height: 12 + ease * 30,
          ),
          ring,
        );
      case SceneEventType.leafLight:
        final paint = Paint()
          ..color = const Color(0xFFD9F0A8).withValues(alpha: 0.7 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        final pulse = Curves.easeOutQuad.transform(t);
        canvas.drawLine(
          Offset(center.dx, soilY),
          Offset(center.dx, size.height * (0.9 - 0.55 * pulse)),
          paint,
        );
      case SceneEventType.branchGrow:
        final paint = Paint()
          ..color = color.withValues(alpha: 0.8 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        final spread = Curves.easeOutBack.transform(t);
        canvas.drawLine(
          Offset(center.dx, size.height * 0.6),
          Offset(center.dx + 90 * spread, size.height * (0.6 - 0.12 * spread)),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, size.height * 0.6),
          Offset(center.dx - 90 * spread, size.height * (0.6 - 0.12 * spread)),
          paint,
        );
      case SceneEventType.fruitPop:
        final r = (4 + ease * 8) * (1 - 0.3 * fade);
        final paint = Paint()
          ..color = const Color(0xFFE8C53A).withValues(alpha: 0.8 * fade)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, r, paint);
      case SceneEventType.bloom:
        final ray = Paint()
          ..color = const Color(0xFFF8E26A).withValues(alpha: 0.6 * fade)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        final len = 20 + ease * 90;
        for (var i = 0; i < 8; i++) {
          final angle = (i / 8) * math.pi * 2 + t * 0.4;
          canvas.drawLine(
            center,
            center + Offset(math.cos(angle), math.sin(angle)) * len,
            ray,
          );
        }
      case SceneEventType.milestone:
        final ring = Paint()
          ..color = const Color(0xFFF8E26A).withValues(alpha: 0.7 * fade)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(center, 16 + ease * 90, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) {
    return old.t != t ||
        old.type != type ||
        old.isDark != isDark ||
        old.color != color ||
        old.soilY != soilY;
  }
}
