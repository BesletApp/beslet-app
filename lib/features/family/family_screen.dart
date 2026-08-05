import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/family_provider.dart';
import '../../l10n/app_localizations.dart';

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
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: Text(l.familyTime)),
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
              Text(todayLog != null ? l.familyHoursLogged(todayLog.hours.toStringAsFixed(1)) : l.logFamilyTime, style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
              const SizedBox(height: 4),
              Text(todayLog != null ? l.qualityTimeMatters : l.howMuchFamilyTime,
                  style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
            ]),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Column(children: [
              Text(_hours.toStringAsFixed(1), style: AppTextStyles.displayLarge.copyWith(fontSize: 48, color: AppColors.primary)),
              Text(l.hours, style: AppTextStyles.bodyMedium.copyWith(color: c.textMuted)),
              const SizedBox(height: 16),
              Slider(
                value: _hours,
                min: 0.5,
                max: 8.0,
                divisions: 15,
                activeColor: AppColors.primary,
                inactiveColor: c.border,
                label: '${_hours.toStringAsFixed(1)}h',
                onChanged: (v) => setState(() { _hours = v; _saved = false; }),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('0.5h', style: AppTextStyles.bodySmall.copyWith(color: c.textMuted)),
                Text('8h', style: AppTextStyles.bodySmall.copyWith(color: c.textMuted)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: _noteCtrl,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: l.whatDidYouDo,
                  hintStyle: TextStyle(color: c.textMuted),
                  filled: true, fillColor: c.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() => _saved = false),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: todayLog != null ? null : _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(todayLog != null ? l.alreadyLogged : (_saved ? l.saved : l.logTime)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.border)),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.2), border: Border.all(color: AppColors.primary.withValues(alpha: 0.5))),
                child: const Center(child: Text('📅', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.thisWeek, style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 4),
                  Text(l.hoursTotal(weeklyHoursAsync.valueOrNull?.toStringAsFixed(1) ?? '0.0'), style: AppTextStyles.displaySmall.copyWith(fontSize: 24)),
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
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(l.loggedFamilyHours(_hours.toStringAsFixed(1)), style: AppTextStyles.bodyMedium),
      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
    ));
  }
}
