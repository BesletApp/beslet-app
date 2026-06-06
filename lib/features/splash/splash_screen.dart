import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/user_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final onboarded = await ref.read(isOnboardedProvider.future);
    if (!mounted) return;
    context.go(onboarded ? '/home' : '/onboarding');
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0A0A0A), Color(0xFF1A1508), Color(0xFF0A0A0A)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Opacity(
            opacity: _fadeAnim.value,
            child: Transform.scale(
              scale: _scaleAnim.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 30)]),
                    child: const Center(child: Text('ብ', style: TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.primary))),
                  ),
                  const SizedBox(height: 32),
                  const Text('ብስለት', style: AppTextStyles.amharicDisplay),
                  const SizedBox(height: 8),
                  Text('Maturity', style: AppTextStyles.displayMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(20)),
                    child: const Text('AMU Christian Fellowship', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primary, letterSpacing: 2)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
