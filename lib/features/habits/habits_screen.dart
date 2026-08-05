import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/habits_provider.dart';
import '../../core/providers/tracking_provider.dart';
import '../../core/services/scene_event_bus.dart';
import '../../l10n/app_localizations.dart';
import '../growth/widgets/mini_vine.dart';

final _habitCategories = [
  {'name': 'Spiritual', 'icon': '🙏'},
  {'name': 'Health', 'icon': '💪'},
  {'name': 'Study', 'icon': '📚'},
  {'name': 'Productivity', 'icon': '⚡'},
];

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsWithCompletionsProvider);
    final trackingAsync = ref.watch(trackingDataProvider);
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: Text(l.dailyHabits), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddDialog(context, ref)),
      ]),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('📋', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(l.noHabitsYet, style: AppTextStyles.displaySmall),
                  const SizedBox(height: 8),
                  Text(l.addFirstHabit, style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: Text(l.addHabit),
                    onPressed: () => _showAddDialog(context, ref),
                  ),
                ]),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(habitsWithCompletionsProvider); ref.invalidate(trackingDataProvider); },
            child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: habits.length + 2,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return MiniVine(
                  seed: 904,
                  emphasis: MiniVineEmphasis.diligence,
                  eventSource: ref.read(sceneEventBusProvider),
                );
              }
              if (index == 1) {
                return _buildStreakHeader(trackingAsync, c, l);
              }
              final item = habits[index - 2];
              final habit = item['habit'] as Habit;
              final completed = item['completed'] as bool;
              return _buildHabitTile(context, ref, habit, completed);
            },
          )); },
      ),
    );
  }

  Widget _buildStreakHeader(AsyncValue<TrackingData> trackingAsync, ThemePalette c, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: AppColors.gradientGoldSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
      child: trackingAsync.when(
        data: (data) => Row(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withValues(alpha: 0.2), border: Border.all(color: AppColors.primary)),
            child: Center(child: Text('${data.streak}', style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary))),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.dayStreak(data.streak), style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(l.xpAndLevel(data.totalXp, data.level + 1), style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: data.levelProgress, backgroundColor: c.border, valueColor: AlwaysStoppedAnimation(AppColors.primary), minHeight: 4),
            ),
          ])),
          const SizedBox(width: 8),
          Text('${data.habitsDone}', style: AppTextStyles.displayMedium.copyWith(color: AppColors.primary)),
        ]),
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const SizedBox(height: 60),
      ),
    );
  }

  Widget _buildHabitTile(BuildContext context, WidgetRef ref, Habit habit, bool completed) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    final emojiIcon = habit.icon.isNotEmpty ? habit.icon : '✅';
    return Container(
      decoration: BoxDecoration(color: c.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: completed ? AppColors.primary.withValues(alpha: 0.5) : c.border)),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? AppColors.primary.withValues(alpha: 0.2) : c.border,
          ),
          child: Center(child: Text(emojiIcon, style: const TextStyle(fontSize: 20))),
        ),
        title: Text(habit.name, style: AppTextStyles.bodyMedium.copyWith(decoration: completed ? TextDecoration.lineThrough : null)),
        subtitle: Text(_habitCategoryLabel(habit.category, l), style: AppTextStyles.bodySmall.copyWith(color: c.textMuted)),
        trailing: GestureDetector(
          onTap: () {
            ref.read(habitsNotifierProvider.notifier).toggleCompletion(habit.id);
            ref.read(sceneEventBusProvider).emit(SceneEventType.fruitPop);
          },
          child: Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? AppColors.success : Colors.transparent,
              border: Border.all(color: completed ? AppColors.success : c.textMuted, width: 2),
            ),
            child: completed ? const Icon(Icons.check, size: 16, color: Color(0xFF0A0A0A)) : null,
          ),
        ),
        onLongPress: () => _confirmDelete(context, ref, habit),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Habit habit) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      title: Text(l.deleteHabitTitle(habit.name), style: AppTextStyles.labelLarge),
      content: Text(l.deleteHabitBody, style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        TextButton(onPressed: () { Navigator.pop(ctx); ref.read(habitsNotifierProvider.notifier).deleteHabit(habit.id); }, child: Text(l.delete, style: TextStyle(color: AppColors.error))),
      ],
    ));
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    String selectedCategory = 'Spiritual';
    String selectedIcon = '🙏';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: c.card,
        title: Text(l.newHabit, style: AppTextStyles.labelLarge),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: l.habitName,
              hintStyle: TextStyle(color: c.textMuted),
              filled: true, fillColor: c.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.category, style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _habitCategories.map((cat) {
            final isSelected = selectedCategory == cat['name'];
            return GestureDetector(
              onTap: () => setState(() { selectedCategory = cat['name'] as String; selectedIcon = cat['icon'] as String; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : c.border),
                ),
                child: Text('${cat['icon']} ${_habitCategoryLabel(cat['name'] as String, l)}', style: AppTextStyles.bodySmall.copyWith(color: isSelected ? AppColors.primary : c.textSecondary)),
              ),
            );
          }).toList()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            ref.read(habitsNotifierProvider.notifier).addHabit(nameCtrl.text.trim(), selectedCategory, selectedIcon);
            Navigator.pop(ctx);
          }, child: Text(l.add)),
        ],
      ),
    ));
  }

  String _habitCategoryLabel(String name, AppLocalizations l) {
    switch (name) {
      case 'Spiritual': return l.habitCategorySpiritual;
      case 'Health': return l.habitCategoryHealth;
      case 'Study': return l.habitCategoryStudy;
      case 'Productivity': return l.habitCategoryProductivity;
      default: return name;
    }
  }
}
