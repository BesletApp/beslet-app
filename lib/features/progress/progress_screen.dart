import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/progress_service.dart';
import '../../core/services/summer_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _sessionService = ReadingSessionService();
  List<ReadingSession> _sessions = [];
  bool _loading = true;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await _sessionService.loadSessions();
    if (mounted) setState(() { _sessions = sessions; _loading = false; });
  }

  int get _totalDays => ProgressService.getTotalCompletedDays(_sessions);
  int get _streak => ProgressService.getStreak(_sessions);
  int get _daysThisWeek => ProgressService.getDaysThisWeek(_sessions);
  int get _currentPhaseIdx => _totalDays < 31 ? 0 : (_totalDays < 61 ? 1 : (_totalDays < 91 ? 2 : 3));

  static const _phaseData = [
    {
      'id': 'discipleship',
      'nameAm': 'የግል ደቀ መዝሙርነት',
      'nameEn': 'Personal Discipleship',
      'icon': Icons.eco,
      'color': Color(0xFF4CAF50),
      'rangeAm': 'ቀን 1–30',
      'rangeEn': 'Days 1–30',
      'descAm': 'የራስህን ወጥ የማንበብ ልማድ መገንባት። የግል እድገት፣ ከእግዚአብሔር ጋር ዕለታዊ ምት።',
      'descEn': 'Building your own consistent reading habit. Individual growth, daily rhythm with God.',
      'stages': ['Discipline', 'Faith'],
      'stageIcons': [Icons.eco, Icons.park],
    },
    {
      'id': 'mentorship',
      'nameAm': 'የአጋዥነት ጅምር',
      'nameEn': 'Mentorship Launch',
      'icon': Icons.people,
      'color': Color(0xFF2196F3),
      'rangeAm': 'ቀን 31–60',
      'rangeEn': 'Days 31–60',
      'descAm': 'አድገሃል። አሁን ጓደኛህን ለመርዳት እርዳ። የራስህን ንባብ ቀጥል አብረህ ሌላውን በ30 ቀን ጉዟቸው እየመራህ።',
      'descEn': "You've grown. Now help a friend grow. Continue your reading while guiding someone through their 30-day journey.",
      'stages': ['Faith', 'Obedience'],
      'stageIcons': [Icons.park, Icons.forest],
    },
    {
      'id': 'community',
      'nameAm': 'ማህበረሰብ ገንቢ',
      'nameEn': 'Community Builder',
      'icon': Icons.public,
      'color': Color(0xFFFF6F00),
      'rangeAm': 'ቀን 61–90',
      'rangeEn': 'Days 61–90',
      'descAm': 'ከአጋዥ ወደ መሪ። አሁን ትንሽ ቡድን እየመራህ ደቀ መዝሙርነትን በማህበረሰብህ ውስጥ ታበዛለህ።',
      'descEn': 'From mentor to leader. You\'re now leading a small group, multiplying discipleship across your network.',
      'stages': ['Obedience', 'Impact'],
      'stageIcons': [Icons.forest, Icons.nature_people],
    },
  ];

  static const _treeStages = [
    {'icon': Icons.eco, 'labelAm': 'ዲሲፕሊን', 'labelEn': 'Discipline'},
    {'icon': Icons.park, 'labelAm': 'እምነት', 'labelEn': 'Faith'},
    {'icon': Icons.forest, 'labelAm': 'ታዛዥነት', 'labelEn': 'Obedience'},
    {'icon': Icons.nature_people, 'labelAm': 'ተፅዕኖ', 'labelEn': 'Impact'},
  ];

  int get _treeStage {
    if (_totalDays <= 7) return 0;
    if (_totalDays <= 30) return 1;
    if (_totalDays <= 60) return 2;
    if (_totalDays <= 90) return 3;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    if (!SummerService.isInSummer) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          title: Text(isAm ? 'እድገት' : 'Progress', style: AppTextStyles.displaySmall.copyWith(fontSize: 20)),
        ),
        body: Center(child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.wb_sunny_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(SummerService.outsideMessage, style: AppTextStyles.displaySmall, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(isAm ? 'በመከር ወቅት ይመለሱ!' : 'Come back when summer begins!',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ]),
        )),
      );
    }
    final totalHours = TimeService.getTotalHoursFormatted(_sessions, isAm);
    final lastSession = _sessions.isNotEmpty ? _sessions.last : null;
    final msg = EncouragementService.getMessage(_streak, lastSession, isAm);
    final verse = EncouragementService.getVerse(_totalDays, isAm);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(
          isAm ? 'እድገት' : 'Progress',
          style: AppTextStyles.displaySmall.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildTreeEvolution(isAm),
          const SizedBox(height: 20),
          ...List.generate(_phaseData.length, (i) {
            final current = i == _currentPhaseIdx;
            final completed = i < _currentPhaseIdx;
            final data = _phaseData[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPhaseCard(i, current, completed, data, isAm),
            );
          }),
          if (_totalDays >= 91) _buildTransitionCard(isAm),
          const SizedBox(height: 12),
          _buildMetricsCard(totalHours, msg, verse, isAm),
        ],
      ),
    );
  }

  Widget _buildTreeEvolution(bool isAm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_treeStages.length, (i) {
          final active = i <= _treeStage;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _treeStages[i]['icon'] as IconData,
                  size: 28,
                  color: active ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  isAm ? _treeStages[i]['labelAm'] as String : _treeStages[i]['labelEn'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter', fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.textPrimary : AppColors.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPhaseCard(int idx, bool current, bool completed, Map data, bool isAm) {
    final color = data['color'] as Color;
    final icon = data['icon'] as IconData;
    final name = isAm ? data['nameAm'] as String : data['nameEn'] as String;
    final range = isAm ? data['rangeAm'] as String : data['rangeEn'] as String;
    final desc = isAm ? data['descAm'] as String : data['descEn'] as String;
    final stages = data['stages'] as List;
    final stageIcons = data['stageIcons'] as List;

    return GestureDetector(
      onTap: current ? null : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: current ? AppColors.card : AppColors.card.withValues(alpha: completed ? 0.8 : 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: color, width: current ? 4 : 2),
            top: BorderSide(color: AppColors.border.withValues(alpha: completed ? 0.3 : 0.15)),
            right: BorderSide(color: AppColors.border.withValues(alpha: completed ? 0.3 : 0.15)),
            bottom: BorderSide(color: AppColors.border.withValues(alpha: completed ? 0.3 : 0.15)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: completed || current ? 0.15 : 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: completed || current ? color : color.withValues(alpha: 0.3)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(
                        fontFamily: 'Inter', fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: completed || current ? AppColors.textPrimary : AppColors.textMuted,
                      )),
                      Text(range, style: TextStyle(
                        fontFamily: 'Inter', fontSize: 11,
                        color: completed || current ? color : color.withValues(alpha: 0.3),
                      )),
                    ],
                  ),
                ),
                if (completed)
                  const Icon(Icons.check_circle, size: 20, color: Color(0xFF4CAF50)),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(desc, style: const TextStyle(
                      fontFamily: 'Inter', fontSize: 12,
                      color: AppColors.textSecondary, height: 1.4,
                    )),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int s = 0; s < stages.length; s++) ...[
                          Column(
                            children: [
                              Icon(stageIcons[s] as IconData, size: 24, color: color),
                              const SizedBox(height: 2),
                              Text(stages[s] as String, style: TextStyle(
                                fontFamily: 'Inter', fontSize: 10,
                                fontWeight: FontWeight.w600, color: AppColors.textSecondary,
                              )),
                            ],
                          ),
                          if (s < stages.length - 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(Icons.arrow_forward, size: 14, color: AppColors.textMuted),
                            ),
                        ],
                      ],
                    ),
                    if (current && _totalDays > 0) ...[
                      const SizedBox(height: 12),
                      _buildCurrentMetrics(color),
                    ],
                  ],
                ),
              ),
              crossFadeState: current ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentMetrics(Color phaseColor) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              _currentPhaseIdx == 0
                  ? (_totalDays <= 7 ? 'Building discipline...' : 'Growing in faith...')
                  : _currentPhaseIdx == 1
                      ? 'Walking in obedience...'
                      : 'Making an impact...',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (i) {
            final now = DateTime.now();
            final weekday = now.weekday;
            final weekStart = now.subtract(Duration(days: weekday - 1));
            final date = weekStart.add(Duration(days: i));
            final done = _sessions.any((s) =>
                s.dateCompleted.year == date.year &&
                s.dateCompleted.month == date.month &&
                s.dateCompleted.day == date.day);
            final isToday = i == weekday - 1;
            return Container(
              width: 10,
              height: 10,
              margin: EdgeInsets.only(right: i < 6 ? 3 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? phaseColor : AppColors.border.withValues(alpha: 0.3),
                border: isToday && !done ? Border.all(color: phaseColor, width: 1.5) : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '$_daysThisWeek/7 ${_daysThisWeek == 0 ? "— start today" : "this week"}',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 10, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _showHistory = !_showHistory),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_showHistory ? Icons.expand_less : Icons.expand_more, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                _showHistory ? (Localizations.localeOf(context).languageCode == 'am' ? 'ዝጋ' : 'Hide') : (Localizations.localeOf(context).languageCode == 'am' ? 'ታሪክ አሳይ' : 'Show 28-day history'),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        AnimatedOpacity(
          opacity: _showHistory ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: _showHistory ? _buildHistoryGrid(phaseColor) : const SizedBox(height: 0),
        ),
      ],
    );
  }

  Widget _buildHistoryGrid(Color phaseColor) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 3,
        runSpacing: 3,
        alignment: WrapAlignment.center,
        children: List.generate(28, (i) {
          final date = now.subtract(Duration(days: 27 - i));
          final done = _sessions.any((s) =>
              s.dateCompleted.year == date.year &&
              s.dateCompleted.month == date.month &&
              s.dateCompleted.day == date.day);
          final isToday = i == 27;
          return Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? phaseColor : AppColors.border.withValues(alpha: 0.2),
              border: isToday && !done ? Border.all(color: phaseColor, width: 1.5) : null,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTransitionCard(bool isAm) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: const BorderSide(color: Color(0xFF9C27B0), width: 4),
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          right: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.autorenew, size: 20, color: Color(0xFF9C27B0)),
              ),
              const SizedBox(width: 10),
              Text(
                isAm ? 'የሽግግር አማራጮች' : 'Transition Options',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _featureRow(Icons.auto_stories, isAm ? 'ወደ ማህበረሰብ ተመለስ' : 'Back to fellowship', isAm ? 'የበጋውን ወቅት የገነባኸውን ማህበረሰብ ይዘህ ወደ ቤተክርስቲያን ተመለስ' : 'Return to church, bring your mentees into the community you built during summer'),
          const SizedBox(height: 8),
          _featureRow(Icons.loop, isAm ? 'አዲስ ዑደት ጀምር' : 'Start a new cycle', isAm ? 'አዲስ የ30 ቀን እቅድ ጀምር፣ ቡድንህን አስፋ' : 'Begin a second 30-day plan with fresh Scripture, expand your group'),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(desc, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsCard(String totalHours, String msg, String verse, bool isAm) {
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
              const Icon(Icons.menu_book, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                '$totalHours ${isAm ? "በቃሉ ውስጥ" : "in God\'s Word"}',
                style: const TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            msg,
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 13, fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500, color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            verse,
            style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _miniStat(Icons.local_fire_department, '$_streak', isAm ? 'ተከታታይ' : 'streak', _streak > 0 ? AppColors.warning : AppColors.textMuted),
              const SizedBox(width: 8),
              _miniStat(Icons.check_circle_outline, '$_totalDays', isAm ? 'ቀናት' : 'days', _totalDays > 0 ? AppColors.success : AppColors.textMuted),
              const SizedBox(width: 8),
              _miniStat(Icons.today, '$_daysThisWeek', isAm ? 'ሳምንት' : 'week', AppColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
