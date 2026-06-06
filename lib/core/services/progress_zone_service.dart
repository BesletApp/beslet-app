import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ReadingSession {
  final DateTime startTime;
  final int durationMinutes;
  final DateTime dateCompleted;
  ReadingSession({
    required this.startTime,
    required this.durationMinutes,
    required this.dateCompleted,
  });
  factory ReadingSession.fromJson(Map<String, dynamic> j) => ReadingSession(
    startTime: DateTime.parse(j['startTime']),
    durationMinutes: j['durationMinutes'],
    dateCompleted: DateTime.parse(j['dateCompleted']),
  );
  Map<String, dynamic> toJson() => {
    'startTime': startTime.toIso8601String(),
    'durationMinutes': durationMinutes,
    'dateCompleted': dateCompleted.toIso8601String(),
  };
}

class Phase {
  final String id;
  final String name;
  final int startDay;
  final int endDay;
  final String iconName;
  final int colorHex;
  const Phase({
    required this.id, required this.name,
    required this.startDay, required this.endDay,
    required this.iconName, required this.colorHex,
  });
}

class ReadingPlan {
  final DateTime startDate;
  final List<Phase> phases;
  final List<ReadingSession> sessions;
  ReadingPlan({required this.startDate, required this.phases, required this.sessions});
}

class ProgressZoneService {
  static final ProgressZoneService _instance = ProgressZoneService._();
  factory ProgressZoneService() => _instance;
  ProgressZoneService._();

  static const _kSessions = 'pz_sessions';
  static const _kStartDate = 'pz_start_date';

  Future<List<ReadingSession>> getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSessions) ?? [];
    return raw.map((s) => ReadingSession.fromJson(jsonDecode(s))).toList();
  }

  Future<DateTime?> getStartDate() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kStartDate);
    return s != null ? DateTime.tryParse(s) : null;
  }

  Future<void> addSession(ReadingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSessions) ?? [];
    raw.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_kSessions, raw);
    final start = prefs.getString(_kStartDate);
    if (start == null) {
      await prefs.setString(_kStartDate, _dateStr(session.dateCompleted));
    }
  }

  Future<int> getPlanDay() async {
    final start = await getStartDate();
    if (start == null) return 1;
    final sessions = await getSessions();
    if (sessions.isEmpty) return 1;
    return sessions.first.dateCompleted.difference(start).inDays + 1;
  }

  static int calcWeek(int planDay) => ((planDay - 1) ~/ 7) + 1;

  static String getPhaseId(int planDay, List<Phase> phases) {
    for (final p in phases) {
      if (planDay >= p.startDay && planDay <= p.endDay) return p.id;
    }
    return phases.first.id;
  }

  static double getPhaseProgress(int planDay, List<Phase> phases) {
    final pid = getPhaseId(planDay, phases);
    final phase = phases.firstWhere((p) => p.id == pid);
    final total = phase.endDay - phase.startDay + 1;
    final done = planDay - phase.startDay + 1;
    return (done / total).clamp(0.0, 1.0);
  }

  static bool isDayCompleted(int day, DateTime start, List<ReadingSession> sessions) {
    final target = start.add(Duration(days: day - 1));
    return sessions.any((s) =>
      s.dateCompleted.year == target.year &&
      s.dateCompleted.month == target.month &&
      s.dateCompleted.day == target.day);
  }

  static int daysThisWeek(DateTime start, List<ReadingSession> sessions) {
    final now = DateTime.now();
    final diff = now.difference(start).inDays + 1;
    final week = calcWeek(diff > 0 ? diff : 1);
    final weekStart = start.add(Duration(days: (week - 1) * 7));
    final weekEnd = weekStart.add(const Duration(days: 7));
    final unique = <int>{};
    for (final s in sessions) {
      if (s.dateCompleted.isAfter(weekStart.subtract(const Duration(hours: 1))) &&
          s.dateCompleted.isBefore(weekEnd)) {
        unique.add(s.dateCompleted.day);
      }
    }
    return unique.length;
  }

  static int getStreak(DateTime start, List<ReadingSession> sessions) {
    final today = DateTime.now();
    int streak = 0;
    for (int d = today.difference(start).inDays + 1; d > 0; d--) {
      if (isDayCompleted(d, start, sessions)) { streak++; } else { break; }
    }
    return streak;
  }

  static int totalMinutes(List<ReadingSession> sessions) =>
    sessions.fold(0, (s, r) => s + r.durationMinutes);

  static String totalHoursFormatted(List<ReadingSession> sessions) =>
    (totalMinutes(sessions) / 60).toStringAsFixed(1);

  static int todayMinutes(List<ReadingSession> sessions) {
    final now = DateTime.now();
    return sessions
      .where((s) => s.dateCompleted.year == now.year && s.dateCompleted.month == now.month && s.dateCompleted.day == now.day)
      .fold(0, (s, r) => s + r.durationMinutes);
  }

  static String encouragement(int planDay, bool missedYesterday, int streak) {
    if (planDay == 1) return "Start where you are — that's enough";
    if (missedYesterday) return "Come back, no condemnation — He's waiting";
    if (planDay == 7 || planDay == 14 || planDay == 21) return "A week of faithfulness. You're growing.";
    if (planDay == 30) return "30 days with God. Look how you've grown.";
    if (streak >= 3) return "Remain in Me, He remains in you";
    return "Each day is a step closer to Him";
  }

  static String verseCard(int planDay) {
    if (planDay <= 7) return "Psalm 1:1-3 — Blessed is the one... his delight is in the law of the Lord.";
    if (planDay <= 14) return "Joshua 1:8 — Keep this Book... meditate on it day and night.";
    if (planDay <= 22) return "2 Timothy 2:15 — Present yourself... a worker approved by God.";
    return "Psalm 119:105 — Your word is a lamp to my feet.";
  }

  static String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final phaseConfig = const [
  Phase(id: 'discipline', name: 'Discipline', startDay: 1, endDay: 7, iconName: 'eco', colorHex: 0xFF4CAF50),
  Phase(id: 'faith', name: 'Faith', startDay: 8, endDay: 15, iconName: 'park', colorHex: 0xFF2196F3),
  Phase(id: 'obedience', name: 'Obedience', startDay: 16, endDay: 22, iconName: 'forest', colorHex: 0xFF8BC34A),
  Phase(id: 'impact', name: 'Impact', startDay: 23, endDay: 30, iconName: 'nature_people', colorHex: 0xFFFF6F00),
];
