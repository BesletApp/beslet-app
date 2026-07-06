import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
  _ParticlePainter(this.particles);
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.opacity < 0.01) continue;
      final paint = Paint()
        ..color = AppColors.primary.withValues(alpha: p.opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, p.size * 0.4);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.size, paint);
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

  late Animation<double> _bgFade;
  late Animation<double> _iconScale;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _badgeFade;
  late Animation<Offset> _badgeSlide;
  late Animation<double> _glowPulse;
  late Animation<double> _bgDrift;

  final List<_Particle> _particles = [];
  final _rng = Random(42);
  bool _particlesActive = true;

  void _initParticles() {
    _particles.clear();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        speed: 0.0003 + _rng.nextDouble() * 0.0006,
        size: 1.0 + _rng.nextDouble() * 2.5,
        phase: _rng.nextDouble() * pi * 2,
      ));
    }
  }

  void _onParticleTick(Duration elapsed) {
    if (!_particlesActive) return;
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
      duration: const Duration(milliseconds: 2800),
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
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _iconScale = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.7, 0.95, curve: Curves.easeIn),
      ),
    );

    _badgeFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeIn),
      ),
    );

    _badgeSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _glowController,
        curve: Curves.easeInOutSine,
      ),
    );

    _bgDrift = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _bgController,
        curve: Curves.easeInOutSine,
      ),
    );

    _mainController.forward();
    _glowController.repeat(reverse: true);
    _bgController.repeat(reverse: true);
    _particleTicker.start();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 3));
    _particlesActive = false;
    _particleTicker.stop();
    if (!mounted) return;
    final onboarded = await ref.read(isOnboardedProvider.future);
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    _bgController.dispose();
    _particleTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07090E),
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
                    color: AppColors.background,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.primary.withValues(alpha: 0.03),
                        Colors.transparent,
                        AppColors.background,
                      ],
                      radius: 0.9,
                      center: Alignment(0.06 * drift, -0.04 * drift),
                    ),
                  ),
                );
              },
            ),
          ),

          AnimatedBuilder(
            animation: _particleRepaint,
            builder: (_, __) => CustomPaint(
              painter: _ParticlePainter(_particles),
              size: Size.infinite,
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
                      return Transform.scale(
                        scale: _iconScale.value,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.3 * _glowPulse.value,
                                ),
                                blurRadius: 20 + 15 * _glowPulse.value,
                                spreadRadius: 2 * _glowPulse.value,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.eco, size: 40, color: AppColors.primary),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  SlideTransition(
                    position: _titleSlide,
                    child: FadeTransition(
                      opacity: _titleFade,
                      child: const Text(
                        'ብስለት',
                        style: AppTextStyles.amharicDisplay,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  FadeTransition(
                    opacity: _subtitleFade,
                    child: Text(
                      'Maturity',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
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
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'AMU Christian Fellowship',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
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
