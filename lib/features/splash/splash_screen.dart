import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/providers/user_provider.dart';

class _Particle {
  double x, y;
  final double speed;
  final double size;
  final double phase;
  double opacity = 0;
  _Particle({required this.x, required this.y, required this.speed, required this.size, required this.phase});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final Color color;
  _ParticlePainter(this.particles, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (final p in particles) {
      if (p.opacity < 0.01) continue;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint
          ..color = color.withValues(alpha: p.opacity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.4),
      );
    }
  }
  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  late AnimationController _bgController;
  late Ticker _particleTicker;
  final _particleRepaint = ValueNotifier<int>(0);
  bool _reduceMotion = false;
  bool _started = false;

  late Animation<double> _bgFade;
  late Animation<double> _markScale;
  late Animation<double> _markFade;
  late Animation<double> _ring;
  late Animation<double> _glowPulse;
  late Animation<double> _bgDrift;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _badgeFade;
  late Animation<Offset> _badgeSlide;

  final List<_Particle> _particles = [];
  final _rng = Random(42);
  bool _particlesActive = true;

  void _initParticles() {
    _particles.clear();
    final count = _reduceMotion ? 0 : 18;
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.0003 + _rng.nextDouble() * 0.0006,
        size: 1.0 + _rng.nextDouble() * 2.2,
        phase: _rng.nextDouble() * pi * 2,
      ));
    }
  }

  void _onParticleTick(Duration elapsed) {
    if (!_particlesActive || _reduceMotion) return;
    final elapsedMs = elapsed.inMicroseconds / 1000;
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.y -= p.speed;
      if (p.y < -0.05) {
        p.y = 1.05;
        p.x = _rng.nextDouble();
      }
      p.opacity = (sin(elapsedMs * 0.003 + p.phase) + 1) * 0.25 + 0.1;
    }
    _particleRepaint.value++;
  }

  @override
  void initState() {
    super.initState();
    _initParticles();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _particleTicker = createTicker(_onParticleTick);

    _bgFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );

    _markFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.5, curve: Curves.easeIn)),
    );

    _markScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.1, 0.5, curve: Curves.elasticOut)),
    );

    _ring = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.35, 1.0, curve: Curves.easeOutQuart)),
    );

    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOutSine),
    );

    _bgDrift = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOutSine),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.72, curve: Curves.easeIn)),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.4, 0.72, curve: Curves.easeOutCubic)),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.6, 0.88, curve: Curves.easeIn)),
    );

    _badgeFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.78, 1.0, curve: Curves.easeIn)),
    );

    _badgeSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.78, 1.0, curve: Curves.easeOutCubic)),
    );

    _route();
  }

  void _begin() {
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      _particlesActive = false;
      return;
    }
    _mainController.forward();
    _glowController.repeat(reverse: true);
    _bgController.repeat(reverse: true);
    _particleTicker.start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce != _reduceMotion) {
      _reduceMotion = reduce;
      _initParticles();
    }
    _begin();
  }

  // Awaites minimal real boot state plus a min dwell, capped at 3s, so the
  // seed-to-light bloom plays fully but never traps the user.
  Future<void> _route() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final minDwell = Future<void>.delayed(reduce ? const Duration(milliseconds: 400) : const Duration(milliseconds: 1500));
    final booted = await ref.read(isOnboardedProvider.future).timeout(
          const Duration(seconds: 3),
          onTimeout: () => false,
        );
    await minDwell;
    if (!mounted) return;
    _particlesActive = false;
    _particleTicker.stop();
    if (!mounted) return;
    context.go(booted ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _bgController.dispose();
    _particleTicker.dispose();
    _particleRepaint.dispose();
    super.dispose();
  }

  Widget _buildStatic(BuildContext context, ThemePalette c, Color primary) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: c.background,
              gradient: RadialGradient(
                colors: [
                  primary.withValues(alpha: 0.12),
                  primary.withValues(alpha: 0.03),
                  Colors.transparent,
                  c.background,
                ],
                radius: 0.9,
                center: Alignment.center,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  BrandMark(size: 84, color: primary),
                  const SizedBox(height: 20),
                  Text('ብስለት', style: AppTextStyles.amharicDisplay),
                  const SizedBox(height: 8),
                  Text('Maturity', style: AppTextStyles.displayMedium.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: primary.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('AMU Christian Fellowship', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primary, letterSpacing: 2)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final primary = c.primary;
    if (_reduceMotion) return _buildStatic(context, c, primary);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _bgFade,
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (_, __) {
                final drift = _bgDrift.value;
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: c.background,
                    gradient: RadialGradient(
                      colors: [
                        primary.withValues(alpha: 0.12),
                        primary.withValues(alpha: 0.03),
                        Colors.transparent,
                        c.background,
                      ],
                      radius: 0.9,
                      center: Alignment(0.06 * drift, -0.04 * drift),
                    ),
                  ),
                );
              },
            ),
          ),

          if (!_reduceMotion)
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: _particleRepaint,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(_particles, primary),
                  size: Size.infinite,
                ),
              ),
            ),

          Center(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: MediaQuery.of(context).padding.bottom + 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_mainController, _glowController]),
                    builder: (_, __) {
                      final glow = _glowPulse.value;
                      return RepaintBoundary(
                        child: Transform.scale(
                          scale: _markScale.value,
                          child: SizedBox(
                            width: 160,
                            height: 160,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Transform.scale(
                                  scale: 1 + _ring.value * 2.6,
                                  child: Opacity(
                                    opacity: 0.8 * (1 - _ring.value),
                                    child: Container(
                                      width: 92,
                                      height: 92,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: primary.withValues(alpha: 0.6), width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedBuilder(
                                  animation: _mainController,
                                  builder: (_, __) => FadeTransition(
                                    opacity: _markFade,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: primary.withValues(alpha: 0.6), width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: primary.withValues(alpha: 0.3 * glow),
                                            blurRadius: 20 + 15 * glow,
                                            spreadRadius: 2 * glow,
                                          ),
                                        ],
                                      ),
                                      child: BrandMark(size: 84, color: primary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: Text('ብስለት', style: AppTextStyles.amharicDisplay),
                    ),
                  ),

                  const SizedBox(height: 8),

                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Maturity',
                      style: AppTextStyles.displayMedium.copyWith(color: c.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _badgeSlide,
              child: FadeTransition(
                opacity: _badgeFade,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: primary.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AMU Christian Fellowship',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primary, letterSpacing: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}