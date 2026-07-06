import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/notification_service.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/todo_provider.dart';
import '../../core/providers/streak_provider.dart';
import 'widgets/streak_bar.dart';

class DailyTodoScreen extends ConsumerStatefulWidget {
  const DailyTodoScreen({super.key});
  @override ConsumerState<DailyTodoScreen> createState() => _DailyTodoScreenState();
}

class _DailyTodoScreenState extends ConsumerState<DailyTodoScreen> {
  final _addCtrl = TextEditingController();
  final _evalCtrl = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _suggestions = [];

  @override void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final s = await loadSuggestions();
    if (mounted) setState(() => _suggestions = s);
  }

  @override void dispose() {
    _addCtrl.dispose();
    _evalCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _timePeriod() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todayTodosProvider);
    final statsAsync = ref.watch(todayTodoStatsProvider);
    final period = _timePeriod();
    final isEvening = period == 'evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        title: Text(_appbarTitle(),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.flag, size: 18),
            label: const Text('Goals', style: TextStyle(fontSize: 13)),
            onPressed: () => context.go('/goals'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textMuted),
            tooltip: 'Edit Suggestions',
            onPressed: _showEditSuggestions,
          ),
        ],
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (todos) {
          final stats = statsAsync.valueOrNull ?? TodoStats(total: 0, completed: 0);
          final allDone = stats.total > 0 && stats.completed >= stats.total;

          return Column(children: [
            _buildGreeting(stats, isEvening, allDone),
            const SizedBox(height: 12),
            _buildStreakBar(),
            const SizedBox(height: 10),
            _buildProgressCard(stats, isEvening, allDone),
            const SizedBox(height: 16),
            Expanded(
              child: todos.isEmpty
                  ? _buildEmptyState(isEvening)
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        ...todos.map((t) => _buildTodoTile(t, allDone && isEvening)),
                        const SizedBox(height: 12),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _buildAddRow(),
            ),
            if (isEvening && todos.isNotEmpty) ...[
              _buildEveningReflection(),
              const SizedBox(height: 16),
            ],
          ]);
        },
      ),
    );
  }

  String _appbarTitle() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅 Plan Today';
    if (hour < 18) return '📋 My Tasks';
    return '🌙 Evening Review';
  }

  Widget _buildGreeting(TodoStats stats, bool isEvening, bool allDone) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        Text(isEvening ? '🌙' : '☀️', style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          isEvening
              ? 'Time to reflect'
              : (stats.total == 0 ? 'What will you do today?' : '${stats.completed}/${stats.total} done'),
          style: AppTextStyles.labelLarge),
        const Spacer(),
        if (stats.total > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: allDone ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('+${stats.completed * 5} XP',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.primary)),
          ),
      ]),
    );
  }

  Widget _buildProgressCard(TodoStats stats, bool isEvening, bool allDone) {
    final progress = stats.total > 0 ? stats.completed / stats.total : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stats.total == 0 ? null : AppColors.card,
        gradient: stats.total == 0 ? AppColors.gradientGoldSoft : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Column(children: [
        Row(children: [
          SizedBox(width: 48, height: 48,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(allDone ? AppColors.success : AppColors.primary),
              ),
              Text(stats.total > 0 ? '${stats.completed}' : '0',
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 16, color: allDone ? AppColors.success : AppColors.primary)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                stats.total == 0
                    ? (isEvening ? 'No tasks planned' : 'What will you do today?')
                    : (allDone ? 'All done! 🎉' : '${stats.total - stats.completed} remaining'),
                style: AppTextStyles.labelLarge),
              const SizedBox(height: 2),
              Text(
                stats.total == 0
                    ? (isEvening ? 'Plan tomorrow' : 'Tap + or a suggestion below')
                    : (allDone ? 'Great work today!' : 'Keep going'),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11)),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState(bool isEvening) {
    if (isEvening) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🌙', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('No tasks planned', style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text('Tap + below to plan tomorrow', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
        ),
      );
    }
    if (_suggestions.isEmpty) {
      return Center(
        child: Text('Tap + to add your first task', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      );
    }
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Quick add', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(spacing: 8, runSpacing: 8,
            children: _suggestions.map((s) => ActionChip(
              label: Text(s, style: AppTextStyles.bodySmall.copyWith(fontSize: 12)),
              onPressed: () => _addTask(s),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  // removed old layout widgets — replaced by _buildGreeting, _buildProgressCard, _buildEmptyState

  Widget _buildTodoTile(TodoItem todo, bool isReadOnly) {
    final isDone = todo.isCompleted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(todo.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) async {
          _delete(todo);
          return false;
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: GestureDetector(
          onLongPress: isReadOnly ? null : () => _showTaskActions(todo),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDone ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
            ),
            child: ListTile(
              leading: GestureDetector(
                onTap: isReadOnly ? null : () => _toggle(todo.id, todo.title, !isDone),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.success : Colors.transparent,
                    border: Border.all(
                      color: isDone ? AppColors.success : AppColors.textMuted,
                      width: isDone ? 0 : 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Color(0xFF0A0A0A))
                      : null,
                ),
              ),
              title: Text(todo.title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: isDone ? AppColors.textMuted : AppColors.textPrimary,
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _addCtrl,
            focusNode: _focusNode,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'What do you want to do?',
              hintStyle: TextStyle(color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onSubmitted: (_) => _addFromField(),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle, color: AppColors.primary, size: 28),
          onPressed: _addFromField,
        ),
      ]),
    );
  }

  Widget _buildEveningReflection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('How was your day?', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _evalCtrl,
            style: AppTextStyles.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a short reflection...',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAndFinishEvening,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Done for today'),
            ),
          ),
        ]),
      ),
    );
  }

  void _saveAndFinishEvening() {
    if (_evalCtrl.text.trim().isNotEmpty) {
      ref.read(todoNotifierProvider.notifier).saveReflection(_evalCtrl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Reflection saved! 🌙', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No reflection written — see you tomorrow!', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
      ));
    }
    NotificationService.cancelEveningReview();
    context.go('/home');
  }

  void _addTask(String title) {
    ref.read(todoNotifierProvider.notifier).addTodo(title);
  }

  void _addFromField() {
    final text = _addCtrl.text.trim();
    if (text.isEmpty) return;
    _addCtrl.clear();
    _focusNode.requestFocus();
    _addTask(text);
  }

  void _toggle(String id, String title, bool becomingDone) {
    ref.read(todoNotifierProvider.notifier).toggleTodo(id);
    if (becomingDone) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$title done! +5 XP', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () {
            ref.read(todoNotifierProvider.notifier).toggleTodo(id);
          },
        ),
      ));
    }
  }

  void _carry(TodoItem todo) {
    ref.read(todoNotifierProvider.notifier).carryToTomorrow(todo.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Moved "${todo.title}" to tomorrow', style: AppTextStyles.bodyMedium),
      backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
    ));
  }

  void _delete(TodoItem todo) {
    ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
  }

  void _showTaskActions(TodoItem todo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.today, color: AppColors.primary),
              title: const Text('Move to tomorrow'),
              onTap: () { Navigator.pop(ctx); _carry(todo); },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStreakBar() {
    final s = ref.watch(streakStateProvider).valueOrNull;
    if (s == null) return const SizedBox(height: 56);
    return StreakBar(
      currentStreak: s.currentStreak,
      freezeTokens: s.freezeTokens,
      weekDays: s.weekDays,
      isAtRisk: s.isAtRisk,
      isBroken: s.isBroken,
    );
  }

  void _showEditSuggestions() {
    final ctrl = TextEditingController(text: _suggestions.join('\n'));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Edit Quick Add', style: AppTextStyles.labelLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: ctrl,
            style: AppTextStyles.bodyMedium,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'One suggestion per line',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            final lines = ctrl.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
            saveSuggestions(lines);
            setState(() => _suggestions = lines);
            Navigator.pop(ctx);
          }, child: const Text('Save')),
        ],
      ),
    );
  }
}
