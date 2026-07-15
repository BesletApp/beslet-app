import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/download_provider.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/database_provider.dart';
import '../../core/models/user_profile.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/skeleton_card.dart';

int _pillarMax(List<int> v) => v.fold(1, (a, b) => a > b ? a : b);

class _PillarCard {
  final IconData icon;
  final String label;
  final String detail;
  final int value;
  final String emptyMsg;
  const _PillarCard(this.icon, this.label, this.detail, this.value, this.emptyMsg);
}

final _phases = ['Discipline', 'Faith', 'Obedience', 'Impact'];
final _levels = ['Seed', 'Sprout', 'Branch', 'Tree', 'Fruitful'];
final _icons = [Icons.menu_book, Icons.code, Icons.people, Icons.checklist];

const _avatarColors = {
  'gold': Color(0xFFC8942E),
  'green': Color(0xFF4CAF50),
  'purple': Color(0xFF9C27B0),
  'blue': Color(0xFF2196F3),
  'orange': Color(0xFFFF9800),
  'teal': Color(0xFF009688),
};

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _expandedPillar = -1;
  String _avatarColor = 'gold';

  @override
  void initState() {
    super.initState();
    _loadAvatarColor();
  }

  Future<void> _loadAvatarColor() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _avatarColor = prefs.getString('avatarColor') ?? 'gold');
  }

  Future<void> _setAvatarColor(String color) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('avatarColor', color);
    if (mounted) setState(() => _avatarColor = color);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(profileProvider);
    final dailyXpAsync = ref.watch(dailyXpProvider);
    final bg = AppColors.of(context).background;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        title: Text(l.profile, style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.of(context).card,
        onRefresh: () async {
          ref.invalidate(profileProvider);
          ref.invalidate(downloadListProvider);
          ref.invalidate(dailyXpProvider);
          await Future.wait([
            ref.read(profileProvider.future),
            ref.read(downloadListProvider.notifier).refresh(),
          ]);
        },
        child: profileAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: const [
              SkeletonCard(height: 120, hasCircle: true, lineCount: 2),
              SizedBox(height: 16),
              SkeletonCard(height: 100, lineCount: 3),
              SizedBox(height: 16),
              SkeletonCard(height: 80, lineCount: 2),
              SizedBox(height: 16),
              SkeletonCard(height: 80, lineCount: 2),
            ],
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [ErrorCard(message: l.localeName == 'am' ? 'መገለጫ መጫን አልተቻለም' : 'Could not load profile')],
          ),
          data: (p) {
            final dailyXp = dailyXpAsync.valueOrNull ?? List.filled(7, 0.0);
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _zone1(l, p),
                const SizedBox(height: 16),
                _buildBadgeStrip(p),
                const SizedBox(height: 16),
                _zone2(l, p),
                const SizedBox(height: 16),
                _zone3(l, p, dailyXp),
                const SizedBox(height: 24),
                _zone4(l),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── ZONE 1: Identity header ──
  Widget _zone1(AppLocalizations l, UserProfile p) {
    final initial = p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?';
    final lvlIdx = p.level.clamp(0, 4);
    final levelLabel = _levels[lvlIdx];
    final color = _avatarColors[_avatarColor] ?? AppColors.primary;

    return Column(children: [
      GestureDetector(
        onTap: () => _showEditProfile(l, p),
        child: Stack(
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _avatarColor == 'gold' ? AppColors.gradientGold : null,
                color: _avatarColor != 'gold' ? color : null,
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 2))],
              ),
              child: Center(child: Text(initial, style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 30, fontWeight: FontWeight.w700, color: _avatarColor == 'gold' ? const Color(0xFF0A0A0A) : Colors.white))),
            ),
            Positioned(bottom: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: AppColors.of(context).card, shape: BoxShape.circle, border: Border.all(color: AppColors.of(context).background, width: 2)),
                child: const Icon(Icons.edit, size: 14, color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(p.displayName, style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.of(context).textPrimary)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_levelIcon(lvlIdx), size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text('$levelLabel · ${l.levelLabel} ${lvlIdx + 1}', style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
      ),
      const SizedBox(height: 18),
      Row(children: [
        _statTile(Icons.local_fire_department, '${p.currentStreak}', l.streak, AppColors.warning),
        _statTile(Icons.check_circle_outline, '${p.totalDaysActive}', l.daysShownUp, AppColors.success),
        _statTile(Icons.pin, '${l.day} ${p.currentDay}', l.ofTotal('90'), AppColors.primary),
        _statTile(Icons.flag, '${l.phase} ${p.currentPhase}', _phases[p.currentPhase - 1], AppColors.spiritualPurple),
      ]),
    ]);
  }

  IconData _levelIcon(int idx) {
    const icons = [Icons.eco, Icons.spa, Icons.forest, Icons.park, Icons.star];
    return icons[idx.clamp(0, 4)];
  }

  Widget _statTile(IconData ic, String val, String lbl, Color c) {
    return Expanded(child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.of(context).border, width: 0.5),
      ),
      child: Column(children: [
        Icon(ic, size: 16, color: c),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: c)),
        Text(lbl, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.of(context).textMuted)),
      ]),
    ));
  }

  // ── Edit Profile Sheet ──
  void _showEditProfile(AppLocalizations l, UserProfile p) {
    final nameCtl = TextEditingController(text: p.displayName);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: StatefulBuilder(builder: (ctx, setSheetState) {
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.of(context).border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(l.editProfile, style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.of(context).textPrimary)),
              const SizedBox(height: 20),
              Text(l.displayName, style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.of(context).textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtl,
                style: TextStyle(fontFamily: 'Inter', fontSize: 15, color: AppColors.of(context).textPrimary),
                decoration: InputDecoration(
                  hintText: l.localeName == 'am' ? 'ስምህን አስገባ' : 'Enter your name',
                  filled: true,
                  fillColor: AppColors.of(context).background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(l.localeName == 'am' ? 'የአዶ ቀለም' : 'Avatar Color', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.of(context).textSecondary)),
              const SizedBox(height: 8),
              Row(children: _avatarColors.entries.map((e) {
                final isSelected = _avatarColor == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _setAvatarColor(e.key);
                      setSheetState(() {});
                    },
                    child: Container(
                      height: 38,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.of(context).textPrimary : Colors.transparent, width: 2),
                      ),
                      child: isSelected ? const Center(child: Icon(Icons.check, size: 18, color: Colors.white)) : null,
                    ),
                  ),
                );
              }).toList()),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF0A0A0A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final newName = nameCtl.text.trim();
                    if (newName.isNotEmpty && newName != p.displayName) {
                      final db = ref.read(databaseProvider);
                      final user = await ref.read(userProvider.future);
                      await db.update(db.users).replace(user.copyWith(name: newName));
                      ref.invalidate(userProvider);
                      ref.invalidate(profileProvider);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(l.profileSaved, style: const TextStyle(fontFamily: 'Inter')),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  },
                  child: Text(l.save, style: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
            ]);
          }),
        );
      },
    );
  }

  // ── Badge Strip ──
  Widget _buildBadgeStrip(UserProfile p) {
    const allBadges = [
      ('first_step', Icons.flag),
      ('week_streak', Icons.local_fire_department),
      ('month_streak', Icons.workspace_premium),
      ('prayer_warrior', Icons.water_drop),
      ('bible_week', Icons.menu_book),
      ('hardcore', Icons.shield),
      ('mature', Icons.emoji_events),
    ];

    if (p.badges.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.of(context).border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.emoji_events, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text('Badges', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.of(context).textSecondary)),
          const Spacer(),
          Text('${p.badges.length}/${allBadges.length}', style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.of(context).textMuted)),
        ]),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: allBadges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final b = allBadges[i];
              final earned = p.badges.any((b2) => b2['id'] == b.$1);
              return Tooltip(
                message: b.$1,
                child: Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: earned ? AppColors.primary.withValues(alpha: 0.1) : AppColors.of(context).border.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: earned ? AppColors.primary.withValues(alpha: 0.2) : AppColors.of(context).border.withValues(alpha: 0.1)),
                  ),
                  child: Icon(b.$2, size: 20, color: earned ? AppColors.primary : AppColors.of(context).textMuted.withValues(alpha: 0.3)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  // ── ZONE 2: Pillar summary ──
  Widget _zone2(AppLocalizations l, UserProfile p) {
    final vals = [p.pillars.spiritualDays, p.pillars.skillMinutes, p.pillars.fellowshipLogs, p.pillars.todosCompleted];
    final maxVal = _pillarMax(vals);
    final pillars = [
      _PillarCard(Icons.menu_book, l.spiritual, '${p.pillars.spiritualDays} ${l.daysRead}', p.pillars.spiritualDays, p.pillars.spiritualDays > 0 ? '' : l.firstReadingWaiting),
      _PillarCard(Icons.code, l.skills, '${p.pillars.skillMinutes} ${l.minutesAbbr}', p.pillars.skillMinutes, p.pillars.skillMinutes > 0 ? '' : l.firstSkillWaiting),
      _PillarCard(Icons.people, l.fellowship, '${p.pillars.fellowshipLogs} ${l.connections}', p.pillars.fellowshipLogs, p.pillars.fellowshipLogs > 0 ? '' : l.firstConnectionWaiting),
      _PillarCard(Icons.checklist, 'Tasks', '${p.pillars.todosCompleted} done', p.pillars.todosCompleted, p.pillars.todosCompleted > 0 ? '' : l.firstTaskWaiting),
    ];
    return Column(children: [
      Wrap(
        spacing: 8, runSpacing: 8,
        children: List.generate(4, (i) {
          final c = pillars[i];
          final size = (MediaQuery.of(context).size.width - 48) / 2;
          return SizedBox(
            width: size, height: 82,
            child: Material(
              color: AppColors.of(context).card,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _expandedPillar = _expandedPillar == i ? -1 : i),
                child: Stack(children: [
                  Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(c.icon, size: 16, color: c.value > 0 ? AppColors.primary : AppColors.of(context).textMuted.withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Text(c.label, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: c.value > 0 ? AppColors.of(context).textPrimary : AppColors.of(context).textMuted.withValues(alpha: 0.3))),
                    ]),
                    const SizedBox(height: 6),
                    if (c.value > 0)
                      Text(c.detail, style: TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.of(context).textSecondary))
                    else
                      Text(c.emptyMsg, style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.of(context).textMuted.withValues(alpha: 0.5))),
                    const Spacer(),
                    ClipRRect(borderRadius: BorderRadius.circular(1), child: Container(
                      height: 2,
                      color: AppColors.of(context).border,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: c.value > 0 ? (c.value / maxVal).clamp(0.05, 1.0) : 0,
                        child: Container(height: 2, color: AppColors.primary),
                      ),
                    )),
                  ])),
                  if (c.value > 0)
                    Positioned(right: 8, top: 8, child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Center(child: Text('${c.value}', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary))),
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
      (l.localeName == 'am' ? "${p.pillars.todosCompleted} ተግባራት ተከናውነዋል። ቀጥልበት!" : "${p.pillars.todosCompleted} tasks completed. Keep going!"),
    ];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 8)],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(_icons[i], size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(msgs[i], style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.of(context).textSecondary, height: 1.4))),
      ]),
    );
  }

  // ── ZONE 3: Journey snapshot ──
  Widget _zone3(AppLocalizations l, UserProfile p, List<double> dailyXp) {
    final daysSince = DateTime.now().difference(p.joinedAt).inDays;
    final readingHours = (p.totalDaysActive * 10 / 60).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).border, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.timeline, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(l.spiritualGrowth, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.of(context).textPrimary)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('${l.phase} ${p.currentPhase}/4', style: const TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        _buildPhasePill(p.currentPhase),
        const SizedBox(height: 14),
        Row(children: [
          _journeyStat(Icons.calendar_today, l.startedAgo(daysSince), null),
          const SizedBox(width: 16),
          _journeyStat(Icons.check_circle, l.showedUpTimes(p.totalDaysActive), null),
        ]),
        const SizedBox(height: 4),
        _journeyStat(Icons.access_time, l.hoursInWord(readingHours), null),
        const SizedBox(height: 14),
        if (dailyXp.any((v) => v > 0))
          _buildSparkline(dailyXp),
        const SizedBox(height: 12),
        Row(children: [
          const Spacer(),
          Text('${p.xp} XP · ${l.keepGoing}', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.of(context).textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildPhasePill(int currentPhase) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) {
      final isPast = i < currentPhase;
      final isActive = i + 1 == currentPhase;
      return Expanded(
        child: Column(children: [
          Row(children: [
            if (i > 0)
              Expanded(child: Container(height: 2, color: i <= currentPhase ? AppColors.primary : AppColors.of(context).border.withValues(alpha: 0.3))),
            Container(
              width: isActive ? 24 : 18, height: isActive ? 24 : 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPast ? AppColors.primary : (isActive ? AppColors.of(context).card : AppColors.of(context).border.withValues(alpha: 0.15)),
                border: Border.all(
                  color: isActive ? AppColors.primary : (isPast ? AppColors.primary : AppColors.of(context).border.withValues(alpha: 0.3)),
                  width: isActive ? 2.5 : 1.5,
                ),
              ),
              child: isPast ? const Icon(Icons.check, size: 10, color: Color(0xFF0A0A0A)) : (isActive ? const Icon(Icons.eco, size: 12, color: AppColors.primary) : null),
            ),
            if (i < 3)
              Expanded(child: Container(height: 2, color: i < currentPhase ? AppColors.primary : AppColors.of(context).border.withValues(alpha: 0.3))),
          ]),
          const SizedBox(height: 4),
          Text(_phases[i], style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, color: isActive ? AppColors.primary : AppColors.of(context).textMuted)),
        ]),
      );
    }));
  }

  Widget _journeyStat(IconData ic, String text, String? sub) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ic, size: 13, color: AppColors.of(context).textMuted),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.of(context).textSecondary)),
    ]);
  }

  Widget _buildSparkline(List<double> dailyXp) {
    final maxVal = dailyXp.reduce((a, b) => a > b ? a : b);
    final ceiling = maxVal > 0 ? (maxVal / 10).ceil() * 10.0 : 50.0;
    final spots = dailyXp.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Weekly XP trend', style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.of(context).textMuted)),
      const SizedBox(height: 6),
      SizedBox(
        height: 50,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: ceiling,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: AppColors.primary,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, data, index) {
                    return FlDotCirclePainter(
                      radius: 2.5,
                      color: AppColors.primary,
                      strokeWidth: 0,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.primary.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 200),
        ),
      ),
    ]);
  }

  // ── ZONE 4: Settings menu ──
  Widget _zone4(AppLocalizations l) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.of(context).card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.of(context).border, width: 0.5),
      ),
      child: Column(children: [
        _tile(Icons.language, l.language, () => context.go('/settings?section=language')),
        Divider(height: 1, color: AppColors.of(context).border),
        _tile(Icons.palette, l.appearance, () => context.go('/settings?section=appearance')),
        Divider(height: 1, color: AppColors.of(context).border),
        _tile(Icons.notifications_outlined, l.reminders, () => context.go('/settings?section=reminders')),
        Divider(height: 1, color: AppColors.of(context).border),
        _tile(Icons.info_outline, l.aboutApp, () => context.go('/settings?section=about')),
      ]),
    );
  }

  Widget _tile(IconData ic, String t, VoidCallback onTap) {
    return ListTile(
      leading: Icon(ic, color: AppColors.primary, size: 20),
      title: Text(t, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: AppColors.of(context).textPrimary)),
      trailing: Icon(Icons.chevron_right, color: AppColors.of(context).textMuted, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      dense: true,
    );
  }
}
