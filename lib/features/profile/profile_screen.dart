import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/models/user_profile.dart';
import '../../l10n/app_localizations.dart';

int _pillarMax(List<int> v) => v.fold(1, (a, b) => a > b ? a : b);

class _PillarCard {
  final IconData icon;
  final String label;
  final String detail;
  final int value;
  final String emptyMsg;
  const _PillarCard(this.icon, this.label, this.detail, this.value, this.emptyMsg);
}

final _phases = [
  ('Discipline','ሥርዓት'),
  ('Faith','እምነት'),
  ('Obedience','ታዛዥነት'),
  ('Impact','ተፅዕኖ'),
];
final _levels = ['Seed','Sprout','Branch','Tree','Fruitful'];
final _icons = [Icons.menu_book, Icons.code, Icons.people, Icons.home];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _expandedPillar = -1;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(l.profile, style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (p) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(          children: [
            _zone1(l, p),
            const SizedBox(height: 20),
            _zone2(l, p),
            const SizedBox(height: 20),
            _zone3(l, p),
            const SizedBox(height: 24),
            _zone4(l),
          ]),
        ),
      ),
    );
  }

  // ── ZONE 1: Identity header ──
  Widget _zone1(AppLocalizations l, UserProfile p) {
    final initial = p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?';
    final lvlIdx = p.level.clamp(0, 4);
    final levelLabel = _levels[lvlIdx];
    return Column(children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.gradientGold, boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 16)]),
        child: Center(child: Text(initial, style: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF0A0A0A)))),
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.eco, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('$levelLabel · ${l.levelLabel} ${lvlIdx + 1}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        _statTile(Icons.local_fire_department, '${p.currentStreak}', l.streak, AppColors.warning),
        _statTile(Icons.check_circle_outline, '${p.totalDaysActive}', l.daysShownUp, AppColors.success),
        _statTile(Icons.today, '${l.day} ${p.currentDay}', l.ofTotal('90'), AppColors.primary),
        _statTile(Icons.flag, '${l.phase} ${p.currentPhase}', _phases[p.currentPhase - 1].$1, _phases[p.currentPhase - 1].$1 == 'Discipline' ? const Color(0xFF4CAF50) : const Color(0xFF2196F3)),
      ]),
    ]);
  }

  Widget _statTile(IconData ic, String val, String lbl, Color c) {
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        Icon(ic, size: 16, color: c),
        const SizedBox(height: 2),
        Text(val, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: c)),
        Text(lbl, style: const TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textMuted)),
      ]),
    ));
  }

  // ── ZONE 2: Pillar summary ──
  Widget _zone2(AppLocalizations l, UserProfile p) {
    final vals = [p.pillars.spiritualDays, p.pillars.skillMinutes, p.pillars.fellowshipLogs, p.pillars.familyMinutes];
    final maxVal = _pillarMax(vals);
    final pillars = [
      _PillarCard(Icons.menu_book, l.spiritual, '${p.pillars.spiritualDays} ${l.daysRead}', p.pillars.spiritualDays, p.pillars.spiritualDays > 0 ? '' : l.firstReadingWaiting),
      _PillarCard(Icons.code, l.skills, '${p.pillars.skillMinutes} ${l.minutesAbbr}', p.pillars.skillMinutes, p.pillars.skillMinutes > 0 ? '' : l.firstSkillWaiting),
      _PillarCard(Icons.people, l.fellowship, '${p.pillars.fellowshipLogs} ${l.connections}', p.pillars.fellowshipLogs, p.pillars.fellowshipLogs > 0 ? '' : l.firstConnectionWaiting),
      _PillarCard(Icons.home, l.familyTime, '${p.pillars.familyMinutes} ${l.minutesAbbr}', p.pillars.familyMinutes, p.pillars.familyMinutes > 0 ? '' : l.firstFamilyWaiting),
    ];
    return Column(children: [
      Wrap(
        spacing: 8, runSpacing: 8,
        children: List.generate(4, (i) {
          final c = pillars[i];
          final size = (MediaQuery.of(context).size.width - 40) / 2;
          return SizedBox(
            width: size, height: 78,
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _expandedPillar = _expandedPillar == i ? -1 : i),
                child: Stack(children: [
                  Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(c.icon, size: 16, color: c.value > 0 ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Text(c.label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: c.value > 0 ? AppColors.textPrimary : AppColors.textMuted.withValues(alpha: 0.3))),
                    ]),
                    const SizedBox(height: 4),
                    if (c.value > 0)
                      Text(c.detail, style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textSecondary))
                    else
                      Text(c.emptyMsg, style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textMuted.withValues(alpha: 0.5))),
                    const Spacer(),
                    ClipRRect(borderRadius: BorderRadius.circular(1), child: Container(
                      height: 2,
                      color: AppColors.border,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: c.value > 0 ? (c.value / maxVal).clamp(0.05, 1.0) : 0,
                        child: Container(height: 2, color: AppColors.primary),
                      ),
                    )),
                  ])),
                  if (c.value > 0)
                    Positioned(right: 8, top: 8, child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Center(child: Text('${c.value}', style: const TextStyle(fontFamily: 'Inter', fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.primary))),
                    )),
                ]),
              ),
            ),
          );
        }),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox.shrink(),
        secondChild: _expandedPillar >= 0 ? _pillarDetail(_expandedPillar, l, p) : const SizedBox.shrink(),
        crossFadeState: _expandedPillar >= 0 ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    ]);
  }

  Widget _pillarDetail(int i, AppLocalizations l, UserProfile p) {
    final msgs = [
      p.currentStreak > 0
        ? (l.localeName == 'am' ? "በቃሉ ውስጥ ${p.totalDaysActive} ቀናት ታይተሃል። ይህ ታማኝነት ነው።" : "You've shown up ${p.totalDaysActive} days in the Word. That is faithfulness.")
        : (l.localeName == 'am' ? "የመጀመሪያ ንባብህ ከፍጹምነት ይበልጣል። ዛሬ ጀምር።" : "Your first reading matters more than perfection. Start today."),
      (l.localeName == 'am' ? "እያንዳንዱ ክፍለ ጊዜ ከዚህ በጋ በኋላ የሚቆይ ክህሎት ነው።" : "Every session is a skill that lasts beyond this summer."),
      (l.localeName == 'am' ? "ብረት ብረትን ያሳልላል። ${p.pillars.fellowshipLogs} ግንኙነቶች ተደርገዋል።" : "Iron sharpens iron. ${p.pillars.fellowshipLogs} connections made."),
      (l.localeName == 'am' ? "${p.pillars.familyMinutes} ደቂቃ የታሰበ ጊዜ። ይደመራል።" : "${p.pillars.familyMinutes} minutes of intentional time. It adds up."),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(_icons[i], size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msgs[i], style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary, height: 1.4))),
      ]),
    );
  }

  // ── ZONE 3: Journey snapshot ──
  Widget _zone3(AppLocalizations l, UserProfile p) {
    final daysSince = DateTime.now().difference(p.joinedAt).inDays;
    final readingHours = (p.totalDaysActive * 10 / 60).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.eco, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(l.spiritualGrowth, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const Spacer(),
          Text('${l.day} ${p.currentDay} · ${l.phase} ${p.currentPhase}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        Text(l.startedAgo(daysSince), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(l.showedUpTimes(p.totalDaysActive), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(l.hoursInWord(readingHours), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
          final isCurrent = p.currentPhase > i;
          final isActive = p.currentPhase == i + 1;
          return Expanded(child: Column(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent ? AppColors.primary : (isActive ? AppColors.card : AppColors.border.withValues(alpha: 0.2)),
                border: Border.all(color: isActive ? AppColors.primary : (isCurrent ? AppColors.primary : AppColors.border.withValues(alpha: 0.2)), width: isActive ? 2.5 : (isCurrent ? 1.5 : 1)),
              ),
              child: isCurrent ? const Icon(Icons.check, size: 14, color: Color(0xFF0A0A0A)) : (isActive ? const Icon(Icons.eco, size: 14, color: AppColors.primary) : null),
            ),
            const SizedBox(height: 4),
            Text(
              isCurrent ? '✓ ${l.doneLabel}' : (isActive ? l.inProgress : l.locked),
              style: TextStyle(fontFamily: 'Inter', fontSize: 8, color: isCurrent ? AppColors.primary : (isActive ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3))),
            ),
          ]));
        })),
        const SizedBox(height: 12),
        Row(children: [const Spacer(), Text('${p.xp} XP · ${l.keepGoing}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF444444)))]),
      ]),
    );
  }

  // ── ZONE 4: Settings menu ──
  Widget _zone4(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(children: [
        _tile(Icons.language, l.language, () => context.go('/settings?section=language')),
        const Divider(height: 1, color: AppColors.border),
        _tile(Icons.palette, l.appearance, () => context.go('/settings?section=appearance')),
        const Divider(height: 1, color: AppColors.border),
        _tile(Icons.notifications_outlined, l.reminders, () => context.go('/settings?section=reminders')),
        const Divider(height: 1, color: AppColors.border),
        _tile(Icons.info_outline, l.aboutApp, () => context.go('/settings?section=about')),
      ]),
    );
  }

  Widget _tile(IconData ic, String t, VoidCallback onTap) {
    return ListTile(
      leading: Icon(ic, color: AppColors.primary, size: 20),
      title: Text(t, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }

}
