import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/journal_provider.dart';
import '../../core/providers/voice_journal_provider.dart';
import 'widgets/voice_journal_sheet.dart';

class DailyJournalScreen extends ConsumerStatefulWidget {
  const DailyJournalScreen({super.key});
  @override ConsumerState<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends ConsumerState<DailyJournalScreen> {
  final _ctrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(journalNotifierProvider.notifier).saveEntry(_ctrl.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          isAm ? 'ማስታወሻ ተቀምጧል' : 'Journal saved',
          style: AppTextStyles.bodyMedium,
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  bool get isAm => Localizations.localeOf(context).languageCode == 'am';

  String _formatDate(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (iso == today) return isAm ? 'ዛሬ' : 'Today';
    return DateFormat('MMM d, yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final historyAsync = ref.watch(journalHistoryProvider);
    final savedToday = ref.watch(voiceJournalSavedTodayProvider).valueOrNull ?? false;
    final todayIso = DateTime.now().toIso8601String().substring(0, 10);
    ref.listen(journalEntryProvider, (prev, next) {
      final entry = next.valueOrNull;
      if (entry != null && !_loaded && _ctrl.text.isEmpty) {
        _loaded = true;
        _ctrl.text = entry.content ?? '';
      }
    });

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textPrimary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          isAm ? 'የቀን ማስታወሻ' : 'Daily Journal',
          style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.gradientGoldSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isAm ? '✍️' : '✍️', style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(
                isAm ? 'ዛሬ ምን አደረግህ?' : 'What did God do today?',
                style: AppTextStyles.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                isAm ? 'እግዚአብሔር ያደረገልህን ጻፍ' : 'Write what He did in your life',
                style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                maxLines: 6,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: isAm ? 'ማሰላሰያህን ጻፍ...' : 'Write your thoughts...',
                  hintStyle: TextStyle(color: c.textMuted),
                  filled: true,
                  fillColor: c.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: Text(isAm ? 'አስቀምጥ' : 'Save Entry'),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: () => showVoiceJournalSheet(context),
                  icon: Icon(Icons.mic, size: 18, color: AppColors.primary),
                  label: Text(
                    isAm ? '🎤 የድምጽ ማስታወሻ' : '🎤 Voice Journal',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          Text(
            isAm ? 'ታሪክ' : 'History',
            style: AppTextStyles.labelLarge.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e', style: TextStyle(color: c.textSecondary))),
            data: (entries) {
              if (entries.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Text(
                    isAm ? 'ገና ምንም ማስታወሻ የለም' : 'No entries yet',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary),
                  ),
                );
              }
              return Column(
                children: entries.map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                          child: Text(
                            _formatDate(e.date),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        if (savedToday && e.date == todayIso)
                          Icon(Icons.mic, size: 14, color: AppColors.primary),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        e.content ?? '',
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, height: 1.5),
                      ),
                    ]),
                  );
                }).toList(),
              );
            },
          ),
        ]),
      ),
    );
  }
}
