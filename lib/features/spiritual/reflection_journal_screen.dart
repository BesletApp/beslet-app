import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/providers/bible_session_provider.dart';

class ReflectionJournalScreen extends ConsumerWidget {
  const ReflectionJournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final sessionsAsync = ref.watch(recentSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/bible'),
        ),
        title: Text(
          isAm ? 'ማስታወሻ ደብተር' : 'Reflection Journal',
          style: AppTextStyles.displaySmall.copyWith(fontSize: 18),
        ),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (sessions) {
          final withReflections = sessions.where((s) => s.reflection?.isNotEmpty == true).toList();
          if (withReflections.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    isAm ? 'ገና ማስታወሻ የለም' : 'No reflections yet',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAm ? 'መጽሐፍ ቅዱስ ስታነብ ሐሳብህን ጻፍ' : 'Write your thoughts when you read Scripture',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: withReflections.length,
            itemBuilder: (ctx, i) {
              final s = withReflections[i];
              final bookName = ScriptureService.bookMap[s.bookId]?.nameEn ?? s.bookId;
              final chapterRange = s.chapterStart == s.chapterEnd
                  ? 'ch.${s.chapterStart}'
                  : 'ch.${s.chapterStart}-${s.chapterEnd}';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.menu_book, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text('$bookName $chapterRange',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11,
                          )),
                      const Spacer(),
                      Text(s.date,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                    ]),
                    const SizedBox(height: 8),
                    Text(s.reflection!,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: AppColors.textPrimary)),
                    if (s.durationMinutes > 0) ...[
                      const SizedBox(height: 6),
                      Text('${s.durationMinutes} min',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 10)),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
