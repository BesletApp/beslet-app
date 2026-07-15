import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/tracking_provider.dart';

class ReflectionScreen extends ConsumerStatefulWidget {
  const ReflectionScreen({super.key});
  @override ConsumerState<ReflectionScreen> createState() => _ReflectionScreenState();
}

class _ReflectionScreenState extends ConsumerState<ReflectionScreen> {
  final _grewCtrl = TextEditingController();
  final _slippedCtrl = TextEditingController();
  final _focusCtrl = TextEditingController();
  bool _saved = false;

  @override void didChangeDependencies() {
    super.didChangeDependencies();
    final reflection = ref.read(reflectionProvider).valueOrNull;
    if (reflection != null && !_saved) {
      _grewCtrl.text = reflection.grew ?? '';
      _slippedCtrl.text = reflection.slipped ?? '';
      _focusCtrl.text = reflection.nextFocus ?? '';
    }
  }

  @override void dispose() {
    _grewCtrl.dispose();
    _slippedCtrl.dispose();
    _focusCtrl.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final reflectionAsync = ref.watch(reflectionProvider);
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/home')), title: const Text('Weekly Reflection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.gradientGoldSoft, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
            child: Column(children: [
              Text('🤔', style: const TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Weekly Check-in', style: AppTextStyles.displaySmall),
              const SizedBox(height: 4),
              Text('Take a moment to reflect on your week', style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
            ]),
          ),
          const SizedBox(height: 24),
          _buildQuestion('What helped you grow this week?', '🙌', _grewCtrl, c),
          const SizedBox(height: 20),
          _buildQuestion('Where did you slip or struggle?', '💪', _slippedCtrl, c),
          const SizedBox(height: 20),
          _buildQuestion('What will you focus on next week?', '🎯', _focusCtrl, c),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saved ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(_saved ? 'Saved ✓' : 'Save Reflection'),
            ),
          ),
          if (reflectionAsync.valueOrNull != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  const SizedBox(width: 8),
                  Text('Reflection complete for this week', style: AppTextStyles.bodySmall.copyWith(color: AppColors.success)),
                ]),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _buildQuestion(String question, String emoji, TextEditingController ctrl, ThemePalette c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(child: Text(question, style: AppTextStyles.labelLarge)),
      ]),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        maxLines: 3,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Write your thoughts...',
          hintStyle: TextStyle(color: c.textMuted),
          filled: true, fillColor: c.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
        onChanged: (_) => setState(() => _saved = false),
      ),
    ]);
  }

  void _save() {
    ref.read(reflectionNotifierProvider.notifier).saveReflection(
      grew: _grewCtrl.text.trim().isEmpty ? null : _grewCtrl.text.trim(),
      slipped: _slippedCtrl.text.trim().isEmpty ? null : _slippedCtrl.text.trim(),
      nextFocus: _focusCtrl.text.trim().isEmpty ? null : _focusCtrl.text.trim(),
    );
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Reflection saved!', style: AppTextStyles.bodyMedium),
      backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating,
    ));
  }
}
