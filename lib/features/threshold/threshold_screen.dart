import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/services/audio_bible_service.dart';
import '../../core/services/scripture_service.dart';
import '../../core/services/widget_service.dart';
import '../../core/providers/audio_player_provider.dart';
import '../../core/providers/reading_preferences_provider.dart';

/// The Threshold — Read (Gaze) → Pray (Respire) → Reflect (Echo).
/// One continuous surface, no steps, no Complete, nothing tracked.
/// Leaving is simply lowering the veil (back / the down affordance).
class ThresholdScreen extends ConsumerStatefulWidget {
  const ThresholdScreen({super.key});

  @override
  ConsumerState<ThresholdScreen> createState() => _ThresholdScreenState();
}

class _ThresholdScreenState extends ConsumerState<ThresholdScreen> {
  final _echoController = TextEditingController();
  String? _echoId;
  bool _echoLoaded = false;
  bool _echoSaved = false;

  @override
  void initState() {
    super.initState();
    _echoId = 'thread_${ScriptureService.threadVerseFor(DateTime.now()).reference}';
    _loadEcho();
  }

  @override
  void dispose() {
    _echoController.dispose();
    super.dispose();
  }

  Future<void> _loadEcho() async {
    final saved = await ReadingPreferences.loadJournalText(_echoId!);
    if (saved != null && mounted && !_echoLoaded) {
      _echoLoaded = true;
      _echoController.text = saved;
    }
  }

  Future<void> _saveEcho() async {
    await ReadingPreferences.saveJournalText(_echoId!, _echoController.text);
    if (mounted) setState(() => _echoSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final verse = ScriptureService.threadVerseFor(DateTime.now());
    final light = WidgetService.lightStateFor(DateTime.now());
    final playerState = ref.watch(audioPlayerProvider);
    final threadPlaying =
        playerState.state == AudioState.playing && playerState.chapter == null;
    final lightTint = switch (light) {
      LampLight.dawn => const Color(0x14C8A96E),
      LampLight.noon => const Color(0x149FD0F0),
      LampLight.dusk => const Color(0x14E8965C),
      LampLight.night => const Color(0x148F8FD0),
    };

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: AppSpacing.sm, right: AppSpacing.sm),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.arrow_downward_rounded, size: 14, color: c.textMuted),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          isAm ? 'መሸፈኛውን ዝቅ አድርግ' : 'lower the veil',
                          style: t.bodySmall.copyWith(fontSize: 11, color: c.textMuted),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _movementLabel(isAm ? 'መመልከት' : 'Gaze', t, c),
                    SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: lightTint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '“${verse.textAm ?? verse.text}”',
                            style: t.amharicDisplay.copyWith(fontSize: 26, height: 1.7, color: c.textPrimary),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            verse.reference,
                            style: t.bodySmall.copyWith(
                              color: c.primary.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: AppSpacing.md),
                          if (!isAm)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    final notifier =
                                        ref.read(audioPlayerProvider.notifier);
                                    if (threadPlaying) {
                                      notifier.stop();
                                    } else {
                                      notifier.speakVerse(
                                        isAm
                                            ? (verse.textAm ?? verse.text)
                                            : verse.text,
                                        isAmharic: isAm,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    threadPlaying
                                        ? Icons.pause_circle_filled
                                        : Icons.play_circle_filled,
                                    size: 34,
                                    color: c.audioBlue,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  threadPlaying
                                      ? (isAm ? 'ማቆም' : 'stop')
                                      : (isAm ? 'አዳምጥ' : 'hear it'),
                                  style: t.bodySmall.copyWith(
                                      fontSize: 11, color: c.textMuted),
                                ),
                              ],
                            ),
                          if (verse.textAm != null) ...[
                            SizedBox(height: AppSpacing.md),
                            Text(
                              verse.text,
                              style: t.displaySmall.copyWith(
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                                fontSize: 18,
                                color: c.textSecondary.withValues(alpha: 0.85),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Divider(height: 1, thickness: 0.5, color: c.border.withValues(alpha: 0.15)),
                    SizedBox(height: AppSpacing.lg),
                    _movementLabel(isAm ? 'መተንፈስ' : 'Respire', t, c),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      '“${isAm ? 'ፀጥ በሉ እኔ አምላክ መሆኔን እወቁ' : 'Be still, and know that I am God.'}”',
                      style: t.displayMedium.copyWith(
                        fontStyle: FontStyle.italic,
                        fontSize: 24,
                        height: 1.6,
                        color: c.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      isAm ? 'መዝሙር 46:10' : 'Psalm 46:10',
                      style: t.bodySmall.copyWith(color: c.textMuted, letterSpacing: 0.5),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      isAm ? 'አንድ ትንፋሽ ውሰድ። ምንም አትከፈልም።' : 'Take one breath. There is nothing to finish.',
                      style: t.bodyMedium.copyWith(color: c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    Divider(height: 1, thickness: 0.5, color: c.border.withValues(alpha: 0.15)),
                    SizedBox(height: AppSpacing.lg),
                    _movementLabel(isAm ? 'ማስተጋባት' : 'Echo', t, c),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      isAm ? 'አንድ ሐሳብ፣ ከፈለግክ' : 'A thought, if you want one.',
                      style: t.bodyMedium.copyWith(color: c.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border.withValues(alpha: 0.3)),
                      ),
                      child: TextField(
                        controller: _echoController,
                        maxLines: null,
                        minLines: 3,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          hintText: '…',
                          hintStyle: t.bodyMedium.copyWith(color: c.textMuted),
                        ),
                        style: t.bodyMedium.copyWith(height: 1.7),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      isAm ? 'ባዶ መተው ትችላለህ።' : 'You may leave it empty.',
                      style: t.bodySmall.copyWith(fontSize: 11, color: c.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: _echoSaved ? null : _saveEcho,
                      icon: Icon(_echoSaved ? Icons.check : Icons.save_outlined, size: 18),
                      label: Text(_echoSaved ? (isAm ? 'ተቀምጧል' : 'Saved') : (isAm ? 'አስቀምጥ' : 'Save')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _movementLabel(String text, AppTextTheme t, ThemePalette c) {
    return Text(
      text,
      style: t.labelSmall.copyWith(
        color: c.primary.withValues(alpha: 0.8),
        letterSpacing: 3,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
