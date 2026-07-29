import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/ai_provider.dart';
import '../../l10n/app_localizations.dart';

class ApiKeyScreen extends ConsumerStatefulWidget {
  const ApiKeyScreen({super.key});
  @override
  ConsumerState<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends ConsumerState<ApiKeyScreen> {
  final _controller = TextEditingController();
  bool _obscured = true;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final hasKeyAsync = ref.watch(hasApiKeyProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: Text(isAm ? 'የAI ቁልፍ' : 'AI API Key'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAm ? 'የGoogle AI ቁልፍ' : 'Google AI API Key',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAm
                        ? 'ይህ መተግበሪያ የAI ባህሪያትን ለማግኘት የግል የGoogle AI ቁልፍ ይፈልጋል። ቁልፍህ በራስህ መሣሪያ ላይ ብቻ ይቀመጣል።'
                        : 'This app uses your personal Google AI API key for AI features. Your key is stored only on your device.',
                    style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    obscureText: _obscured,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: isAm ? 'AI ቁልፍህን አስገባ' : 'Enter your API key',
                      filled: true,
                      fillColor: c.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: c.border),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(_obscured ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscured = !_obscured),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isAm ? 'አስቀምጥ' : 'Save'),
                    ),
                  ),
                  if (hasKeyAsync.valueOrNull == true) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: _clearKey,
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        label: Text(
                          isAm ? 'ቁልፍ አስወግድ' : 'Remove API Key',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAm ? 'ቁልፍ እንዴት ማግኘት ይቻላል?' : 'How to get a key',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAm
                        ? '1. ጎብኝ፦ ai.google.dev \n2. "Get API key" ን ጠቅ አድርግ\n3. አዲስ ቁልፍ ፍጠር (ወይም ያለውን ተጠቀም)\n4. ቁልፉን ቅዳ እና ከላይ ባለው ሳጥን ውስጥ ለጥፍ'
                        : '1. Visit ai.google.dev\n2. Click "Get API key"\n3. Create a new key or use an existing one\n4. Copy the key and paste it above',
                    style: AppTextStyles.bodySmall.copyWith(color: c.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => launchUrl(
                        Uri.parse('https://aistudio.google.com/apikey'),
                        mode: LaunchMode.externalApplication,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(isAm ? 'ወደ Google AI Studio ይሂዱ' : 'Go to Google AI Studio'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveKey() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(aiServiceProvider).setApiKey(key);
      ref.invalidate(hasApiKeyProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.settings),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearKey() async {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAm ? 'ቁልፉን ማስወገድ' : 'Remove API Key'),
        content: Text(isAm ? 'እርግጠኛ ነህ? የAI ባህሪያት አይሰሩም።' : 'Are you sure? AI features will stop working.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isAm ? 'ተው' : 'Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isAm ? 'አስወግድ' : 'Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(aiServiceProvider).clearApiKey();
      ref.invalidate(hasApiKeyProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isAm ? 'ቁልፍ ተወግዷል' : 'API key removed'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
