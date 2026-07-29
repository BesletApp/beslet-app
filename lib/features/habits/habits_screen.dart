import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/habits_provider.dart';
import '../../core/providers/tracking_provider.dart';

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

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: const Text('Daily Habits'), actions: [
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
                  Text('No habits yet', style: AppTextStyles.displaySmall),
                  const SizedBox(height: 8),
                  Text('Add your first habit to start tracking!', style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Habit'),
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
            itemCount: habits.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStreakHeader(trackingAsync, c);
              }
              final item = habits[index - 1];
              final habit = item['habit'] as Habit;
              final completed = item['completed'] as bool;
              return _buildHabitTile(context, ref, habit, completed);
            },
          )); },
      ),
    );
  }

  Widget _buildStreakHeader(AsyncValue<TrackingData> trackingAsync, ThemePalette c) {
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
            Text('Day ${data.streak} Streak', style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text('${data.totalXp} XP · Level ${data.level + 1}', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
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
        subtitle: Text(habit.category, style: AppTextStyles.bodySmall.copyWith(color: c.textMuted)),
        trailing: GestureDetector(
          onTap: () => ref.read(habitsNotifierProvider.notifier).toggleCompletion(habit.id),
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
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      title: Text('Delete ${habit.name}?', style: AppTextStyles.labelLarge),
      content: Text('This will remove the habit and all its completion history.', style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(ctx); ref.read(habitsNotifierProvider.notifier).deleteHabit(habit.id); }, child: Text('Delete', style: TextStyle(color: AppColors.error))),
      ],
    ));
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final nameCtrl = TextEditingController();
    String selectedCategory = 'Spiritual';
    String selectedIcon = '🙏';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: c.card,
        title: Text('New Habit', style: AppTextStyles.labelLarge),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Habit name',
              hintStyle: TextStyle(color: c.textMuted),
              filled: true, fillColor: c.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Text('Category', style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary)),
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
                child: Text('${cat['icon']} ${cat['name']}', style: AppTextStyles.bodySmall.copyWith(color: isSelected ? AppColors.primary : c.textSecondary)),
              ),
            );
          }).toList()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            ref.read(habitsNotifierProvider.notifier).addHabit(nameCtrl.text.trim(), selectedCategory, selectedIcon);
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    ));
  }
}
