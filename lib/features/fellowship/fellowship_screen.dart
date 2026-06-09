import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/fellowship_provider.dart';

class FellowshipScreen extends ConsumerWidget {
  const FellowshipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayFellowshipProvider);
    final weeklyCountAsync = ref.watch(weeklyFellowshipCountProvider);
    final todayLog = todayAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: const Text('Fellowship')),
      body: RefreshIndicator(
        onRefresh: () async { ref.invalidate(todayFellowshipProvider); ref.invalidate(weeklyFellowshipCountProvider); },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.gradientGoldSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
            child: Column(children: [
              Text(todayLog != null ? '👥' : '🤝', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(todayLog != null ? 'Connected!' : 'Reach out to someone today', style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
              const SizedBox(height: 8),
              Text(todayLog != null ? 'You reached out today. Keep building!' : 'A text, a call, or time together — make the first move.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 20),
              if (todayLog != null)
                Column(children: [
                  if (todayLog.contactName != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Connected with ${todayLog.contactName}', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.undo, size: 16),
                    label: const Text('Undo'),
                    onPressed: () => ref.read(fellowshipNotifierProvider.notifier).removeToday(),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withValues(alpha: 0.5))),
                  ),
                ])
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('I reached out to someone'),
                  onPressed: () => _showConnectDialog(context, ref),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)),
                ),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.2), border: Border.all(color: AppColors.primary.withValues(alpha: 0.5))),
                child: const Center(child: Text('📅', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('This Week', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${weeklyCountAsync.valueOrNull ?? 0} days', style: AppTextStyles.displaySmall.copyWith(fontSize: 24)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
      ),
    );
  }

  void _showConnectDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Who did you connect with?', style: AppTextStyles.labelLarge),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Optional — you can skip this', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Name (optional)',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Skip', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(fellowshipNotifierProvider.notifier).logConnection(
                contactName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              );
            },
            child: const Text('Log Connection'),
          ),
        ],
      ),
    );
  }
}
