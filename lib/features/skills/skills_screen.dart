import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/database/app_database.dart';
import '../../core/providers/skills_provider.dart';

class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});
  @override ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> with WidgetsBindingObserver {
  DateTime? _startTime;
  Timer? _timer;
  bool _isRunning = false;
  String? _activeSkillId;

  @override void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override void dispose() { WidgetsBinding.instance.removeObserver(this); _timer?.cancel(); WakelockPlus.disable(); super.dispose(); }

  @override void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _isRunning) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed && _isRunning && _startTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
    }
  }

  int get _elapsedSeconds => _startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0;

  void _startTimer(String skillId) {
    setState(() { _activeSkillId = skillId; _isRunning = true; _startTime = DateTime.now(); });
    WakelockPlus.enable();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (mounted) setState(() {}); });
  }

  void _stopTimer() {
    _timer?.cancel();
    WakelockPlus.disable();
    if (_activeSkillId != null && _isRunning) {
      final minutes = (_elapsedSeconds / 60).ceil().clamp(1, 999);
      ref.read(skillsNotifierProvider.notifier).logSession(_activeSkillId!, minutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Logged $minutes minutes!', style: AppTextStyles.bodyMedium),
          backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
        ));
      }
    }
    setState(() { _startTime = null; _isRunning = false; _activeSkillId = null; });
  }

  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: const Text('Skills'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _showAddDialog),
      ]),
      body: ref.watch(allSkillsProvider).when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (skills) {
          if (skills.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🎯', style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text('No skills yet', style: AppTextStyles.displaySmall),
                  const SizedBox(height: 8),
                  Text('Track skills you want to develop!', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Add Skill'), onPressed: _showAddDialog),
                ]),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async { ref.invalidate(allSkillsProvider); },
            child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: skills.length,
            itemBuilder: (_, i) => _buildSkillCard(skills[i]),
          ));
        },
      ),
    );
  }

  Widget _buildSkillCard(Skill skill) {
    final isActive = _activeSkillId == skill.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.border),
          child: Center(child: Text(skill.icon.isNotEmpty ? skill.icon : '📚', style: const TextStyle(fontSize: 24))),
        ),
        title: Text(skill.name, style: AppTextStyles.bodyMedium),
        subtitle: Text('${skill.category} · ${skill.targetMinutes} min goal', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        trailing: isActive
            ? GestureDetector(
                onTap: _stopTimer,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.stop, color: AppColors.error, size: 16),
                    const SizedBox(width: 4),
                    Text(_formatTime(_elapsedSeconds), style: AppTextStyles.labelLarge.copyWith(color: AppColors.error, fontSize: 12)),
                  ]),
                ),
              )
            : GestureDetector(
                onTap: () => _startTimer(skill.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary.withValues(alpha: 0.5))),
                  child: Text('Start', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontSize: 12)),
                ),
              ),
        onLongPress: () => _confirmDelete(skill.id, skill.name),
      ),
    );
  }

  void _confirmDelete(String skillId, String skillName) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text('Delete $skillName?', style: AppTextStyles.labelLarge),
      content: Text('This will remove the skill and all session logs.', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        TextButton(onPressed: () { Navigator.pop(ctx); ref.read(skillsNotifierProvider.notifier).deleteSkill(skillId); }, child: Text('Delete', style: TextStyle(color: AppColors.error))),
      ],
    ));
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    String category = 'Creative';
    String icon = '🎯';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('New Skill', style: AppTextStyles.labelLarge),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Skill name',
              hintStyle: TextStyle(color: AppColors.textMuted),
              filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Text('Category & Icon', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ['Creative', '🎵'], ['Writing', '✍️'], ['Tech', '💻'], ['Language', '🗣️'], ['Wellness', '🧘'], ['Art', '🎨'],
          ].map((c) {
            final isSelected = category == c[0];
            return GestureDetector(
              onTap: () => setState(() { category = c[0]; icon = c[1]; }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                ),
                child: Text('${c[1]} ${c[0]}', style: AppTextStyles.bodySmall.copyWith(color: isSelected ? AppColors.primary : AppColors.textSecondary)),
              ),
            );
          }).toList()),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            if (nameCtrl.text.trim().isEmpty) return;
            ref.read(skillsNotifierProvider.notifier).addSkill(nameCtrl.text.trim(), category, icon);
            Navigator.pop(ctx);
          }, child: const Text('Add')),
        ],
      ),
    ));
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
