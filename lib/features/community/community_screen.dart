import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🌍', style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 24),
            Text('Community Coming Soon', style: AppTextStyles.displaySmall),
            const SizedBox(height: 12),
            Text(
              'We are building a space where you can connect, share goals, and grow together with others on the same journey.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.2)),
                  child: const Center(child: Text('🔔', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Get notified', style: AppTextStyles.labelLarge),
                  Text('We\'ll let you know when it\'s ready', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
