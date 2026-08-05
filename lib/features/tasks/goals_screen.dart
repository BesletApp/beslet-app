import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' hide Column;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/goal_provider.dart';
import '../../l10n/app_localizations.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});
  @override ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedType = 'weekly';
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(currentPeriodGoalsProvider(_selectedType));
    final pastPeriodsAsync = ref.watch(pastPeriodStartsProvider(_selectedType));
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/daily-todo')),
        title: Text('🎯 ${l.myGoals}', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: c.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(_showPast ? Icons.today : Icons.history, color: c.textMuted),
            tooltip: _showPast ? l.currentGoals : l.pastGoals,
            onPressed: () => setState(() => _showPast = !_showPast),
          ),
        ],
      ),
      floatingActionButton: _showPast ? null : FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF0A0A0A),
        onPressed: _showAddGoal,
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            _buildTypeChip('weekly', l.weeklyType),
            const SizedBox(width: 8),
            _buildTypeChip('monthly', l.monthlyType),
            const SizedBox(width: 8),
            _buildTypeChip('yearly', l.yearlyType),
          ]),
        ),
        Expanded(
          child: _showPast ? _buildPastView(pastPeriodsAsync, c, l) : _buildCurrentView(goalsAsync, c, l),
        ),
      ]),
    );
  }

  Widget _buildTypeChip(String type, String label) {
    final c = AppColors.of(context);
    final selected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.2) : c.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : c.border),
        ),
        child: Text(label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? AppColors.primary : c.textSecondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            )),
      ),
    );
  }

  Widget _buildCurrentView(AsyncValue<List<Goal>> goalsAsync, ThemePalette c, AppLocalizations l) {
    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (goals) {
        final active = goals.where((g) => !g.isAchieved).toList();
        final achieved = goals.where((g) => g.isAchieved).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
          children: [
            if (active.isEmpty && achieved.isEmpty) ...[
              const SizedBox(height: 80),
              const Center(child: Text('🎯', style: TextStyle(fontSize: 48))),
              const SizedBox(height: 16),
              Center(child: Text(l.noGoalsOfType(_typeLabel(_selectedType, l)), style: AppTextStyles.displaySmall.copyWith(fontSize: 18))),
              const SizedBox(height: 8),
              Center(child: Text(l.addFirstGoal, style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary))),
            ],
            if (active.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l.active, style: AppTextStyles.labelSmall.copyWith(color: c.textMuted, fontSize: 10, letterSpacing: 1.2)),
              ),
              ...active.map((g) => _buildGoalTile(g, false, c)),
            ],
            if (achieved.isNotEmpty) ...[
              if (active.isNotEmpty) const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(l.achieved, style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontSize: 10, letterSpacing: 1.2)),
              ),
              ...achieved.map((g) => _buildGoalTile(g, true, c)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPastView(AsyncValue<List<String>> periodsAsync, ThemePalette c, AppLocalizations l) {
    return periodsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (periods) {
        if (periods.isEmpty) {
          return Center(child: Text(l.noPastGoals, style: TextStyle(color: c.textSecondary)));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: periods.map((period) {
            return _buildPastPeriod(period, c, l);
          }).toList(),
        );
      },
    );
  }

  Widget _buildPastPeriod(String periodStart, ThemePalette c, AppLocalizations l) {
    final goalsAsync = ref.watch(goalsForPeriodProvider((type: _selectedType, periodStart: periodStart)));
    return goalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (goals) {
        final label = _periodLabel(periodStart, l);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: AppTextStyles.labelSmall.copyWith(color: c.textSecondary, fontSize: 11)),
              const SizedBox(height: 8),
              ...goals.map((g) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Icon(g.isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18, color: g.isAchieved ? AppColors.success : c.textMuted),
                  const SizedBox(width: 8),
                  Expanded(child: Text(g.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        decoration: g.isAchieved ? TextDecoration.lineThrough : null,
                        color: g.isAchieved ? c.textMuted : c.textPrimary,
                      ))),
                ]),
              )),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildGoalTile(Goal goal, bool achieved, ThemePalette c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => ref.read(goalNotifierProvider.notifier).toggleAchieved(goal.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: achieved ? AppColors.primary.withValues(alpha: 0.3) : c.border,
            ),
          ),
          child: Row(children: [
            Icon(
              achieved ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 22,
              color: achieved ? AppColors.success : AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(goal.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    decoration: achieved ? TextDecoration.lineThrough : null,
                    color: achieved ? c.textMuted : c.textPrimary,
                  )),
            ),
            GestureDetector(
              onTap: () => _confirmDelete(goal),
              child: Icon(Icons.close, size: 16, color: c.textMuted.withValues(alpha: 0.5)),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDelete(Goal goal) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: Text(l.deleteGoalTitle, style: AppTextStyles.labelLarge),
        content: Text(l.deleteGoalBody(goal.title), style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(
            onPressed: () { Navigator.pop(ctx); ref.read(goalNotifierProvider.notifier).deleteGoal(goal.id); },
            child: Text(l.delete, style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  String _periodLabel(String periodStart, AppLocalizations l) {
    final parts = periodStart.split('-');
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    switch (_selectedType) {
      case 'weekly':
        final end = DateTime(int.parse(year), month, day).add(const Duration(days: 6));
        return l.weekOf('$month/$day', '${end.month}/${end.day}');
      case 'monthly':
        return '${months[month]} $year';
      case 'yearly':
        return year;
      default:
        return periodStart;
    }
  }

  void _showAddGoal() {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    String selectedType = _selectedType;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: c.card,
          title: Text(l.addTypeGoal(_typeLabel(_selectedType, l)), style: AppTextStyles.labelLarge),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: ctrl,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: l.goalHint,
                hintStyle: TextStyle(color: c.textMuted),
                filled: true, fillColor: c.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, children: ['weekly', 'monthly', 'yearly'].map((t) {
              final isSelected = selectedType == t;
              return GestureDetector(
                onTap: () => setState(() => selectedType = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppColors.primary : c.border),
                  ),
                  child: Text(_typeLabel(t, l),
                      style: AppTextStyles.bodySmall.copyWith(color: isSelected ? AppColors.primary : c.textSecondary)),
                ),
              );
            }).toList()),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              ref.read(goalNotifierProvider.notifier).addGoal(ctrl.text.trim(), selectedType);
              Navigator.pop(ctx);
            }, child: Text(l.add)),
          ],
        ),
      ),
    );
  }

  String _typeLabel(String type, AppLocalizations l) {
    switch (type) {
      case 'weekly': return l.weeklyType;
      case 'monthly': return l.monthlyType;
      case 'yearly': return l.yearlyType;
      default: return type;
    }
  }
}

final goalsForPeriodProvider = FutureProvider.family<List<Goal>, ({String type, String periodStart})>((ref, params) async {
  final db = ref.watch(databaseProvider);
  final all = await (db.select(db.goals)
    ..orderBy([(t) => OrderingTerm(expression: t.createdAt)])
  ).get();
  return all.where((g) => g.type == params.type && g.periodStart == params.periodStart).toList();
});
