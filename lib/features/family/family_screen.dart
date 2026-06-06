import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/family_provider.dart';

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});
  @override ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  double _hours = 1.0;
  final _noteCtrl = TextEditingController();
  bool _saved = false;

  @override void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayFamilyProvider);
    final weeklyHoursAsync = ref.watch(weeklyFamilyHoursProvider);
    final todayLog = todayAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: const Text('Time with Family')),
      body: RefreshIndicator(
        onRefresh: () async { ref.invalidate(todayFamilyProvider); ref.invalidate(weeklyFamilyHoursProvider); },
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(gradient: AppColors.gradientGoldSoft, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
            child: Column(children: [
              const Text('👨‍👩‍👧‍👧', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(todayLog != null ? '${todayLog.hours}h logged today' : 'Log family time', style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(todayLog != null ? 'Quality time matters. Keep it up!' : 'How much time did you spend with family today?',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Text(_hours.toStringAsFixed(1), style: AppTextStyles.displayLarge.copyWith(fontSize: 48, color: AppColors.primary)),
              Text('hours', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              Slider(
                value: _hours,
                min: 0.5,
                max: 8.0,
                divisions: 15,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                label: '${_hours.toStringAsFixed(1)}h',
                onChanged: (v) => setState(() { _hours = v; _saved = false; }),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('0.5h', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                Text('8h', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _noteCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'What did you do? (optional)',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                  filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() => _saved = false),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: todayLog != null ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(todayLog != null ? 'Already logged today' : (_saved ? 'Saved!' : 'Log Time')),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
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
                  Text('${weeklyHoursAsync.valueOrNull?.toStringAsFixed(1) ?? '0.0'}h total', style: AppTextStyles.displaySmall.copyWith(fontSize: 24)),
                ]),
              ),
            ]),
          ),
        ]),
      ),
      ),
    );
  }

  void _save() {
    ref.read(familyNotifierProvider.notifier).logTime(
      _hours,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Logged ${_hours.toStringAsFixed(1)}h with family!', style: AppTextStyles.bodyMedium),
      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
    ));
  }
}
