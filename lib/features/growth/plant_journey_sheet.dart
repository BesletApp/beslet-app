import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/growth_provider.dart';
import '../../../core/services/growth_content.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

/// Opens the sheet where the user plants their own journey: an intention and a
/// timeframe of their choosing. Nothing is tracked — the soil is theirs.
Future<bool> showPlantJourneySheet(BuildContext context) async {
  final planted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _PlantJourneySheet(),
  );
  return planted ?? false;
}

class _PlantJourneySheet extends ConsumerStatefulWidget {
  const _PlantJourneySheet();

  @override
  ConsumerState<_PlantJourneySheet> createState() => _PlantJourneySheetState();
}

class _PlantJourneySheetState extends ConsumerState<_PlantJourneySheet> {
  JourneyIntention? _intention;
  JourneyTimeframe _timeframe = JourneyTimeframe.month;
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _plant() async {
    final intention = _intention;
    if (intention == null || _submitting) return;
    setState(() => _submitting = true);
    await ref.read(journeyNotifierProvider.notifier).plantJourney(
          intention,
          GrowthContent.daysFor(_timeframe),
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final l = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(l.enterTheVineyard, style: t.displaySmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l.soilYoursGrowingHis,
                  style: t.bodyMedium.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(c, t, l.yourIntention),
                const SizedBox(height: AppSpacing.sm),
                ...GrowthContent.intentions.map((i) => _intentionTile(c, t, i)),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(c, t, l.howLong),
                const SizedBox(height: AppSpacing.sm),
                ...GrowthContent.timeframes.map((tf) => _timeframeTile(c, t, tf)),
                const SizedBox(height: AppSpacing.lg),
                _sectionTitle(c, t, l.vineWordOptional),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  maxLength: 120,
                  decoration: InputDecoration(
                    hintText: l.vineWordHint,
                    filled: true,
                    fillColor: c.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: (_intention == null || _submitting) ? null : _plant,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.of(context).primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l.plantIt, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemePalette c, AppTextTheme t, String text) {
    return Text(text, style: t.labelLarge.copyWith(color: c.textSecondary));
  }

  Widget _intentionTile(ThemePalette c, AppTextTheme t, JourneyIntention intention) {
    final selected = _intention == intention;
    final label = GrowthContent.intentionLabel(intention);
    final commitment = GrowthContent.intentionCommitment(intention);
    final isAm = AppLocalizations.of(context)?.localeName == 'am';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _intention = intention),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected ? c.primary.withValues(alpha: 0.1) : c.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.5 : 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: selected ? c.primary : c.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isAm ? label.am : label.en, style: t.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        isAm ? commitment.am : commitment.en,
                        style: t.bodySmall.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeframeTile(ThemePalette c, AppTextTheme t, JourneyTimeframe timeframe) {
    final selected = _timeframe == timeframe;
    final label = GrowthContent.timeframeLabel(timeframe);
    final isAm = AppLocalizations.of(context)?.localeName == 'am';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _timeframe = timeframe),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? c.primary.withValues(alpha: 0.1) : c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.5 : 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked : Icons.radio_button_off,
                  size: 18,
                  color: selected ? c.primary : c.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isAm ? label.am : label.en,
                  style: t.bodyMedium.copyWith(color: selected ? c.primary : c.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
