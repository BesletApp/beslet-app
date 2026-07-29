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
  bool _isAm = false;
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
    _isAm = Localizations.localeOf(context).languageCode == 'am';
    final isAm = _isAm;

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: AppColors.of(context).background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')),
        title: Text(_appbarTitle(isAm),
            style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.of(context).textPrimary)),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.flag, size: 18),
            label: Text(isAm ? 'ግቦች' : 'Goals', style: const TextStyle(fontSize: 13)),
            onPressed: () => context.go('/goals'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          ),
          IconButton(
            icon: Icon(Icons.tune, color: AppColors.of(context).textMuted),
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
            _buildGreeting(stats, isEvening, allDone, isAm),
            const SizedBox(height: 12),
            _buildStreakBar(),
            const SizedBox(height: 10),
            _buildProgressCard(stats, isEvening, allDone, isAm),
            const SizedBox(height: 16),
            Expanded(
              child: todos.isEmpty
                  ? _buildEmptyState(isEvening, isAm)
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
              child: _buildAddRow(isAm),
            ),
            if (isEvening && todos.isNotEmpty) ...[
              _buildEveningReflection(isAm),
              const SizedBox(height: 16),
            ],
          ]);
        },
      ),
    );
  }

  String _appbarTitle(bool isAm) {
    final hour = DateTime.now().hour;
    if (hour < 12) return isAm ? '🌅 ዛሬን እቅድ' : '🌅 Plan Today';
    if (hour < 18) return isAm ? '📋 ሥራዬ' : '📋 My Tasks';
    return isAm ? '🌙 የማታ ግምገማ' : '🌙 Evening Review';
  }

  Widget _buildGreeting(TodoStats stats, bool isEvening, bool allDone, bool isAm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(children: [
        Text(isEvening ? '🌙' : '☀️', style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text(
          isEvening
              ? (isAm ? 'ለማሰላሰል ጊዜ' : 'Time to reflect')
              : (stats.total == 0 ? (isAm ? 'ዛሬ ምን ታደርጋለህ?' : 'What will you do today?') : '${stats.completed}/${stats.total} ${isAm ? 'ተከናውኗል' : 'done'}'),
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

  Widget _buildProgressCard(TodoStats stats, bool isEvening, bool allDone, bool isAm) {
    final progress = stats.total > 0 ? stats.completed / stats.total : 0.0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stats.total == 0 ? null : AppColors.of(context).card,
        gradient: stats.total == 0 ? AppColors.gradientGoldSoft : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: allDone ? AppColors.success.withValues(alpha: 0.3) : AppColors.of(context).border,
        ),
      ),
      child: Column(children: [
        Row(children: [
          SizedBox(width: 48, height: 48,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 3,
                backgroundColor: AppColors.of(context).border,
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
                    ? (isEvening ? (isAm ? 'ምንም ሥራ አልታቀደም' : 'No tasks planned') : (isAm ? 'ዛሬ ምን ታደርጋለህ?' : 'What will you do today?'))
                    : (allDone ? (isAm ? 'ሁሉም ተከናውኗል! 🎉' : 'All done! 🎉') : '${stats.total - stats.completed} ${isAm ? 'ቀርቷል' : 'remaining'}'),
                style: AppTextStyles.labelLarge),
              const SizedBox(height: 2),
              Text(
                stats.total == 0
                    ? (isEvening ? (isAm ? 'ነገ እቅድ' : 'Plan tomorrow') : (isAm ? "+ ወይም ሀሳብ ምረጥ" : 'Tap + or a suggestion below'))
                    : (allDone ? (isAm ? 'ጥሩ ሥራ!' : 'Great work today!') : (isAm ? 'ቀጥል' : 'Keep going')),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textSecondary, fontSize: 11)),
            ]),
          ),
        ]),
      ]),
    );
  }

  Widget _buildEmptyState(bool isEvening, bool isAm) {
    if (isEvening) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🌙', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(isAm ? 'ምንም ሥራ አልታቀደም' : 'No tasks planned', style: AppTextStyles.displaySmall.copyWith(fontSize: 18)),
            const SizedBox(height: 4),
            Text(isAm ? 'ነገ ለማቀድ + ን መታ ያድርጉ' : 'Tap + below to plan tomorrow', style: AppTextStyles.bodySmall.copyWith(color: AppColors.of(context).textSecondary)),
          ]),
        ),
      );
    }
    if (_suggestions.isEmpty) {
      return Center(
        child: Text(isAm ? 'የመጀመሪያ ሥራዎን ለመጨመር + ን ይጫኑ' : 'Tap + to add your first task', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.of(context).textSecondary)),
      );
    }
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(isAm ? 'ፈጣን መጨመር' : 'Quick add', style: AppTextStyles.labelSmall.copyWith(color: AppColors.of(context).textMuted, fontSize: 10)),
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
              color: AppColors.of(context).card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDone ? AppColors.primary.withValues(alpha: 0.4) : AppColors.of(context).border),
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
                      color: isDone ? AppColors.success : AppColors.of(context).textMuted,
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
                    color: isDone ? AppColors.of(context).textMuted : AppColors.of(context).textPrimary,
                  )),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddRow(bool isAm) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).border),
      ),
      child: Row(children: [
        Expanded(
          child: TextField(
            controller: _addCtrl,
            focusNode: _focusNode,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: isAm ? 'ምን መሥራት ትፈልጋለህ?' : 'What do you want to do?',
              hintStyle: TextStyle(color: AppColors.of(context).textMuted),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildEveningReflection(bool isAm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.of(context).card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.of(context).border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isAm ? 'ቀንህ እንዴት አለፈ?' : 'How was your day?', style: AppTextStyles.labelLarge.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: _evalCtrl,
            style: AppTextStyles.bodyMedium,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isAm ? 'አጭር ማሰላሰያ ጻፍ...' : 'Write a short reflection...',
              hintStyle: TextStyle(color: AppColors.of(context).textMuted),
              filled: true, fillColor: AppColors.of(context).surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAndFinishEvening,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(isAm ? 'ለዛሬ በቃ' : 'Done for today'),
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
        content: Text(_isAm ? 'ማሰላሰያ ተቀምጧል! 🌙' : 'Reflection saved! 🌙', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isAm ? 'ምንም ማሰላሰያ አልተጻፈም — ነገ እንገናኛለን!' : 'No reflection written — see you tomorrow!', style: AppTextStyles.bodyMedium),
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
        content: Text('$title ${_isAm ? 'ተከናውኗል! +5 XP' : 'done! +5 XP'}', style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: _isAm ? 'ቀልብስ' : 'Undo',
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
      content: Text(_isAm ? '"${todo.title}" ወደ ነገ ተዛወረ' : 'Moved "${todo.title}" to tomorrow', style: AppTextStyles.bodyMedium),
      backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating,
    ));
  }

  void _delete(TodoItem todo) {
    ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
  }

  void _showTaskActions(TodoItem todo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.today, color: AppColors.primary),
              title: Text(_isAm ? 'ወደ ነገ አንቀሳቅስ' : 'Move to tomorrow'),
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
    );
  }

  void _showEditSuggestions() {
    final ctrl = TextEditingController(text: _suggestions.join('\n'));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.of(context).card,
        title: Text(_isAm ? 'ፈጣን መጨመር አርትዕ' : 'Edit Quick Add', style: AppTextStyles.labelLarge),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: ctrl,
            style: AppTextStyles.bodyMedium,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: _isAm ? 'በአንድ መስመር አንድ ሀሳብ' : 'One suggestion per line',
              hintStyle: TextStyle(color: AppColors.of(context).textMuted),
              filled: true, fillColor: AppColors.of(context).surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(_isAm ? 'ተው' : 'Cancel')),
          ElevatedButton(onPressed: () {
            final lines = ctrl.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
            saveSuggestions(lines);
            setState(() => _suggestions = lines);
            Navigator.pop(ctx);
          }, child: Text(_isAm ? 'አስቀምጥ' : 'Save')),
        ],
      ),
    );
  }
}
