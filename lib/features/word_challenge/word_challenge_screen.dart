import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/verse_content_provider.dart';
import '../../core/providers/word_challenge_provider.dart';
import '../../core/services/scripture_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import 'verse_builder_loop.dart';

/// A focused shell for reviewing one verse from the Memory Garden. It is the
/// same gentle practice loop — the first completed pass records the spaced
/// review, then the moment returns home.
class WordChallengeScreen extends ConsumerStatefulWidget {
  final String? reviewId;

  const WordChallengeScreen({super.key, this.reviewId});

  @override
  ConsumerState<WordChallengeScreen> createState() => _WordChallengeScreenState();
}

class _WordChallengeScreenState extends ConsumerState<WordChallengeScreen> {
  Future<void> _reviewed() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.reviewDone),
        backgroundColor: AppColors.of(context).success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);

    final AsyncValue<VerseChallengeData> challenge;
    if (widget.reviewId != null) {
      final all = ref.watch(allWordChallengesProvider);
      final existing = all.valueOrNull;
      if (existing == null) {
        challenge = all.hasError
            ? AsyncError<VerseChallengeData>(all.error!, all.stackTrace ?? StackTrace.current)
            : const AsyncLoading<VerseChallengeData>();
      } else {
        final todayVerse = ref.watch(todayDailyVerseProvider).valueOrNull;
        challenge = AsyncData(
          existing.isEmpty
              ? VerseChallengeData.fromScripture(
                  todayVerse ?? ScriptureService.threadVerseFor(DateTime.now()))
              : existing.firstWhere((x) => x.id == widget.reviewId, orElse: () => existing.first),
        );
      }
    } else {
      challenge = ref.watch(todayWordChallengeProvider);
    }

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l.review),
      ),
      body: SafeArea(
        child: challenge.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l.somethingWentWrong)),
          data: (v) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  v.reference,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.of(context).labelSmall.copyWith(
                        color: c.primary,
                        letterSpacing: 0.5,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                VersePracticeLoop(
                  verse: v,
                  reviewId: v.id,
                  onReviewed: _reviewed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
