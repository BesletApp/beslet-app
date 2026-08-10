import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/audio_player_provider.dart';
import '../../../core/providers/identity_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import 'choose_word_sheet.dart';

/// The Lamp — the one Word the user carries. When empty it glows dimly and
/// holds a quiet invitation; when kept, the Word rests here to be listened to.
class LampCard extends ConsumerWidget {
  const LampCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final identity = ref.watch(identityProvider).valueOrNull;

    final keptWord = identity?.keptWord;
    final keptRef = identity?.keptWordRef;
    final hasWord = keptWord != null && keptWord.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWord
              ? AppColors.primary.withValues(alpha: 0.25)
              : c.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _lampGlyph(hasWord),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  l.profileLampTitle,
                  style: t.labelLarge.copyWith(color: c.primary),
                ),
              ),
              if (hasWord)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 18, color: c.textMuted),
                  tooltip: l.profileLampChange,
                  onPressed: () => _openChooseWord(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (hasWord) ...[
            Text(
              keptWord,
              style: t.bodyLarge.copyWith(
                fontFamily: 'CormorantGaramond',
                fontSize: 18,
                height: 1.5,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              keptRef ?? '',
              style: t.labelSmall.copyWith(color: c.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (Localizations.localeOf(context).languageCode != 'am')
                  _softAction(
                    context: context,
                    icon: Icons.headphones_outlined,
                    label: l.profileLampListen,
                    onTap: () {
                      final isAm =
                          Localizations.localeOf(context).languageCode == 'am';
                      ref.read(audioPlayerProvider.notifier).speakVerse(
                            keptWord,
                            isAmharic: isAm,
                          );
                    },
                  ),
                if (Localizations.localeOf(context).languageCode != 'am')
                  const SizedBox(width: AppSpacing.sm),
                _softAction(
                  context: context,
                  icon: Icons.close,
                  label: l.profileLampRemove,
                  onTap: () => ref
                      .read(identityNotifierProvider.notifier)
                      .setKeptWord(text: null, reference: null),
                ),
              ],
            ),
          ] else ...[
            Text(
              l.profileLampEmpty,
              style: t.bodyMedium.copyWith(color: c.textSecondary, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            _softAction(
              context: context,
              icon: Icons.add,
              label: l.profileLampChoose,
              onTap: () => _openChooseWord(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lampGlyph(bool hasWord) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: hasWord
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8E26A), Color(0xFFE89B2E)],
              )
            : null,
        color: hasWord ? null : AppColors.primary.withValues(alpha: 0.08),
        boxShadow: hasWord
            ? [
                BoxShadow(
                  color: const Color(0xFFE89B2E).withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 2),
                ),
              ]
            : const [],
      ),
      child: Icon(
        Icons.lightbulb_outline,
        size: 20,
        color: hasWord ? const Color(0xFF4A1D08) : AppColors.primary,
      ),
    );
  }

  Widget _softAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontFamily: 'Inter')),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _openChooseWord(BuildContext context, WidgetRef ref) {
    showChooseWordSheet(context, ref);
  }
}
