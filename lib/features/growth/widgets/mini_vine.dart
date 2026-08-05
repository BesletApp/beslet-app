import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/vine_life_provider.dart';
import '../../../core/services/growth_content.dart';
import '../../../core/services/scene_event_bus.dart';
import '../../../core/services/widget_service.dart';
import 'life_clock.dart';
import 'vine_painter.dart';

/// Which reservoir of the day this window leans toward.
enum MiniVineEmphasis { water, light, warmth, diligence }

/// A small window into the living garden, shown on the discipline screens so
/// the vine is never far from the day's actions. Each discipline fills its own
/// reservoir; logging one on this very screen nudges the vine with a physical
/// spring, so the causality is felt exactly where it happens.
class MiniVine extends ConsumerStatefulWidget {
  final int seed;
  final MiniVineEmphasis emphasis;
  final SceneEventBus eventSource;
  final double height;

  const MiniVine({
    super.key,
    required this.seed,
    required this.emphasis,
    required this.eventSource,
    this.height = 96,
  });

  @override
  ConsumerState<MiniVine> createState() => _MiniVineState();
}

class _MiniVineState extends ConsumerState<MiniVine>
    with TickerProviderStateMixin {
  late final LifeClock _life;
  late final AnimationController _pulse;
  final VineSpring _spring = VineSpring();

  @override
  void initState() {
    super.initState();
    _life = LifeClock(vsync: this, onTick: (_) {
      if (mounted) setState(() {});
    });
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _pulse.addListener(() {
      if (mounted) setState(() {});
    });
    widget.eventSource.addListener(_onEvent);
  }

  @override
  void dispose() {
    widget.eventSource.removeListener(_onEvent);
    _life.dispose();
    _pulse.dispose();
    super.dispose();
  }

  /// How strongly this screen's reservoir cares about the gesture.
  double _affinity(SceneEventType type) => switch (widget.emphasis) {
        MiniVineEmphasis.water => type == SceneEventType.water ? 1.0 : 0.3,
        MiniVineEmphasis.light => type == SceneEventType.leafLight ? 1.0 : 0.3,
        MiniVineEmphasis.warmth => type == SceneEventType.branchGrow ? 1.0 : 0.3,
        MiniVineEmphasis.diligence => type == SceneEventType.fruitPop ? 1.0 : 0.3,
      };

  void _onEvent() {
    final event = widget.eventSource.value;
    if (event == null) return;
    final force = switch (event.type) {
      SceneEventType.water => 22.0,
      SceneEventType.leafLight => 30.0,
      SceneEventType.branchGrow => 48.0,
      SceneEventType.fruitPop => 60.0,
      SceneEventType.bloom => 90.0,
      SceneEventType.milestone => 70.0,
    };
    _spring.impulse(force * _affinity(event.type));
    _pulse.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vineLifeProvider).valueOrNull;
    final reduced = MediaQuery.of(context).disableAnimations;
    final lifeT = _life.t;
    final sway = reduced ? 0.0 : _life.swayPhase();
    final bend = reduced ? 0.0 : (sway * 0.006 + _spring.value * 0.0035);
    final pulse01 = reduced ? 0.0 : _pulse.value;

    final emphasisValue = switch (widget.emphasis) {
      MiniVineEmphasis.water => state?.water ?? 0,
      MiniVineEmphasis.light => state?.light ?? 0,
      MiniVineEmphasis.warmth => state?.warmth ?? 0,
      MiniVineEmphasis.diligence => state?.diligence ?? 0,
    };
    // A young vine that visibly grows as the day tends its reservoir.
    final growth01 = (0.18 + emphasisValue * 0.30).clamp(0.0, 1.0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? VinePalette.dark : VinePalette.light;
    final light = WidgetService.lightStateFor(DateTime.now());
    final atmosphere = GrowthContent.atmosphereFor(state?.mood, light);

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [atmosphere.skyTop, atmosphere.skyBottom],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _MiniLampGlow(light: light, isDark: isDark),
              CustomPaint(
                painter: VinePainter(
                  seed: widget.seed,
                  growth01: growth01,
                  branches: 2,
                  fruitCount: 0,
                  fruitColor: const Color(0xFFE8C53A),
                  palette: palette,
                  sway: sway,
                  hydration: state?.water ?? 0.6,
                  leafGlow: state?.light ?? 0.6,
                  branchOpen: state?.warmth ?? 0.6,
                  ripen: state?.diligence ?? 0,
                  droop: 0,
                  blossomOpen: 0.7,
                  bend: bend,
                  lifeT: lifeT,
                  flutterAmt: reduced ? 0 : 1,
                  dew: 0,
                ),
              ),
              CustomPaint(
                painter: _MiniPulsePainter(
                  t: pulse01,
                  color: palette.leaf,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniLampGlow extends StatelessWidget {
  final LampLight light;
  final bool isDark;

  const _MiniLampGlow({required this.light, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = switch (light) {
      LampLight.dawn => const Color(0xFFF2C879),
      LampLight.noon => const Color(0xFFFBE8B2),
      LampLight.dusk => const Color(0xFFF2A65A),
      LampLight.night => const Color(0xFF8FB0E8),
    };
    final glow = base.withValues(alpha: isDark ? 0.5 : 0.35);
    return Positioned(
      top: -30,
      right: -30,
      width: 110,
      height: 110,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [glow, glow.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// A soft ring that pulses when this screen's discipline lands.
class _MiniPulsePainter extends CustomPainter {
  final double t;
  final Color color;

  const _MiniPulsePainter({required this.t, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final center = Offset(size.width / 2, size.height * 0.6);
    final ease = Curves.easeOutCubic.transform(t);
    final fade = 1.0 - t;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45 * fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 10 + ease * size.height * 0.45, paint);
    canvas.drawCircle(center, 10 + ease * size.height * 0.3, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniPulsePainter old) => old.t != t || old.color != color;
}
