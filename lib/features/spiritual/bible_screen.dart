import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/scripture_service.dart';
import '../../core/providers/bible_read_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../l10n/app_localizations.dart';

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});
  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  bool _showReflect = false;
  final _noteController = TextEditingController();
  static const int _totalDays = 90;
  static const int _phaseCount = 4;
  static const int _daysPerPhase = _totalDays ~/ _phaseCount;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final userAsync = ref.watch(userProvider);
    final todayRead = ref.watch(todayBibleReadProvider);
    final streak = ref.watch(bibleStreakProvider);
    final isRead = todayRead.valueOrNull != null;

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (user) {
        final planId = user.biblePlan;
        final plan = ScriptureService.getPlan(planId, days: _totalDays);
        final reading = ScriptureService.getTodaysReading(planId);
        final verse = ScriptureService.getDailyScripture();
        final day = reading.day;
        final phase = ScriptureService.getPhase(day);
        final phaseNames = isAm ? ScriptureService.phaseNamesAm : ScriptureService.phaseNamesEn;
        final theme = isAm
            ? ScriptureService.getTheme(reading.reference)
            : ScriptureService.getThemeEn(reading.reference);
        final currentPhaseDay = ((day - 1) % _daysPerPhase) + 1;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => context.pop(),
            ),
            title: Text(
              isAm ? 'መጽሐፍ ቅዱስ' : l.bible,
              style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.whatshot, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '$streak-${l.streak}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeroCard(context, ref, reading, isRead, phase, phaseNames, theme, isAm, planId),
              const SizedBox(height: 20),
              _buildVerseBlock(verse, isAm),
              const SizedBox(height: 20),
              _buildPhaseBar(day, phase, phaseNames, isRead, isAm, currentPhaseDay, plan),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    BiblePlanEntry reading,
    bool isRead,
    int phase,
    List<String> phaseNames,
    String theme,
    bool isAm,
    String planId,
  ) {
    final label = isAm ? 'ቀን ${reading.day} ከ$_totalDays' : 'Day ${reading.day} of $_totalDays';
    final phaseLabel = isAm
        ? '${phaseNames[phase]} · ክፍል ${phase + 1} ከ$_phaseCount'
        : '${phaseNames[phase]} · Phase ${phase + 1} of $_phaseCount';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientGoldSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _badge(label, AppColors.primary.withValues(alpha: 0.15), AppColors.primary),
              _badge(phaseLabel, AppColors.card.withValues(alpha: 0.5), AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            reading.reference,
            style: AppTextStyles.displayMedium
                .copyWith(fontSize: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
              ),
            ),
            child: Text(
              theme,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isRead
                      ? null
                      : () async {
                          await ref.read(bibleNotifierProvider.notifier)
                              .markAsRead(reading.reference,
                                  note: _noteController.text.isNotEmpty
                                      ? _noteController.text : null);
                        },
                  icon: Icon(isRead ? Icons.check_circle : Icons.check, size: 18),
                  label: Text(
                    isRead
                        ? '${isAm ? "ተነቧል" : "Done"} ✓'
                        : '${isAm ? "አንብቤያለሁ" : "Mark as read"} · +20 XP',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: isRead
                      ? ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success.withValues(alpha: 0.2),
                          foregroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        )
                      : ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF0A0A0A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showReflect = !_showReflect),
                  icon: Icon(_showReflect ? Icons.expand_less : Icons.edit_note, size: 18),
                  label: Text(isAm ? 'አስተንትን' : 'Reflect', style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _showReflect ? AppColors.primary : AppColors.textSecondary,
                    side: BorderSide(
                      color: _showReflect ? AppColors.primary : AppColors.primary.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          if (_showReflect) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13),
              decoration: InputDecoration(
                hintText: isAm ? 'ሐሳብህን ጻፍ...' : 'Write your thoughts...',
                hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.5), fontSize: 13),
                filled: true,
                fillColor: AppColors.card.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseBlock(Scripture verse, bool isAm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                isAm ? 'የቀኑ ቅዱስ ቃል' : 'Verse of the Day',
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800,
                    color: AppColors.primary, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (verse.textAm != null) ...[
            Text(
              '"${verse.textAm}"',
              style: AppTextStyles.amharicBody.copyWith(fontSize: 20, color: AppColors.textPrimary, height: 1.5),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '"${verse.text}"',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              color: verse.textAm != null ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: verse.textAm != null ? 13 : 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, width: 40, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            verse.reference,
            style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseBar(int day, int phaseIdx, List<String> phaseNames, bool isRead, bool isAm, int currentPhaseDay, List<BiblePlanEntry> plan) {
    final phaseColors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF6F00),
      const Color(0xFF9C27B0),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_view_week, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                isAm ? 'የ$_totalDays ቀን እቅድ' : '$_totalDays-Day Plan',
                style: const TextStyle(
                  fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.primary, letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_phaseCount, (i) {
              final active = i == phaseIdx;
              final done = i < phaseIdx;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < _phaseCount - 1 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: done ? phaseColors[i] : (active ? phaseColors[i].withValues(alpha: 0.6) : AppColors.border.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(_phaseCount, (i) {
              final active = i == phaseIdx;
              final start = i * _daysPerPhase + 1;
              final end = i == _phaseCount - 1 ? _totalDays : (i + 1) * _daysPerPhase;
              return Expanded(
                child: Text(
                  '${phaseNames[i]}\n${isAm ? "ቀን $start-$end" : "D$start-$end"}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 9,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: List.generate(_totalDays, (i) {
              final d = i + 1;
              final isCurrentDay = d == day;
              final isEarlierDay = d < day;
              final phaseForDay = ScriptureService.getPhase(d);
              return Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isEarlierDay ? phaseColors[phaseForDay].withValues(alpha: 0.3) : (isCurrentDay ? phaseColors[phaseIdx] : AppColors.border.withValues(alpha: 0.2)),
                  border: Border.all(
                    color: isCurrentDay ? phaseColors[phaseIdx] : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$d',
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isEarlierDay ? AppColors.textPrimary : (isCurrentDay ? Colors.white : AppColors.textMuted),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontFamily: 'Inter', fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
