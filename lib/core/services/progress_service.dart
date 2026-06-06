import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// DATA MODELS
// ============================================================================

class ReadingSession {
  final DateTime startTime;
  final int durationMinutes;
  final DateTime dateCompleted;

  ReadingSession({
    required this.startTime,
    required this.durationMinutes,
    required this.dateCompleted,
  });

  factory ReadingSession.fromJson(Map<String, dynamic> json) => ReadingSession(
        startTime: DateTime.parse(json['startTime']),
        durationMinutes: json['durationMinutes'],
        dateCompleted: DateTime.parse(json['dateCompleted']),
      );

  Map<String, dynamic> toJson() => {
        'startTime': startTime.toIso8601String(),
        'durationMinutes': durationMinutes,
        'dateCompleted': dateCompleted.toIso8601String(),
      };
}

class GrowthPhase {
  final String id;
  final String nameAm;
  final String nameEn;
  final IconData icon;
  final Color color;
  final int minDays;
  final int maxDays;

  const GrowthPhase({
    required this.id,
    required this.nameAm,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.minDays,
    required this.maxDays,
  });
}

const growthPhases = [
  GrowthPhase(id: 'seedling', nameAm: 'ቡቃያ', nameEn: 'Seedling', icon: Icons.eco, color: Color(0xFF4CAF50), minDays: 0, maxDays: 7),
  GrowthPhase(id: 'sprouting', nameAm: 'ማደግ', nameEn: 'Sprouting', icon: Icons.park, color: Color(0xFF2196F3), minDays: 8, maxDays: 30),
  GrowthPhase(id: 'growing', nameAm: 'ብስለት', nameEn: 'Growing', icon: Icons.forest, color: Color(0xFF8BC34A), minDays: 31, maxDays: 90),
  GrowthPhase(id: 'fruitful', nameAm: 'ፍሬያማ', nameEn: 'Fruitful', icon: Icons.nature_people, color: Color(0xFFFF6F00), minDays: 91, maxDays: 999999),
];

// ============================================================================
// STORAGE SERVICE
// ============================================================================

class ReadingSessionService {
  static final ReadingSessionService _instance = ReadingSessionService._();
  factory ReadingSessionService() => _instance;
  ReadingSessionService._();

  static const _kSessions = 'reading_sessions';

  Future<List<ReadingSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSessions) ?? [];
    return raw.map((s) => ReadingSession.fromJson(jsonDecode(s))).toList();
  }

  Future<void> saveSession(ReadingSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kSessions) ?? [];
    raw.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_kSessions, raw);
  }

  Future<void> markTodayRead({int durationMinutes = 10}) async {
    final now = DateTime.now();
    final sessions = await loadSessions();
    final alreadyDone = sessions.any((s) =>
        s.dateCompleted.year == now.year &&
        s.dateCompleted.month == now.month &&
        s.dateCompleted.day == now.day);
    if (!alreadyDone) {
      await saveSession(ReadingSession(
        startTime: now,
        durationMinutes: durationMinutes,
        dateCompleted: now,
      ));
    }
  }

  Future<bool> isTodayRead() async {
    final sessions = await loadSessions();
    final now = DateTime.now();
    return sessions.any((s) =>
        s.dateCompleted.year == now.year &&
        s.dateCompleted.month == now.month &&
        s.dateCompleted.day == now.day);
  }
}

// ============================================================================
// STATELESS SERVICES
// ============================================================================

class ProgressService {
  static int getStreak(List<ReadingSession> sessions) {
    int streak = 0;
    var checkDate = DateTime.now();
    while (true) {
      final completed = sessions.any((s) =>
          s.dateCompleted.year == checkDate.year &&
          s.dateCompleted.month == checkDate.month &&
          s.dateCompleted.day == checkDate.day);
      if (completed) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  static int getDaysThisWeek(List<ReadingSession> sessions) {
    final now = DateTime.now();
    final weekday = now.weekday;
    final weekStart = now.subtract(Duration(days: weekday - 1));
    return sessions
        .where((s) => !s.dateCompleted.isBefore(weekStart))
        .map((s) => s.dateCompleted.day)
        .toSet()
        .length;
  }

  static int getTotalCompletedDays(List<ReadingSession> sessions) {
    return sessions.map((s) => s.dateCompleted.day).toSet().length;
  }

  static GrowthPhase getGrowthPhase(int totalDays) {
    for (final phase in growthPhases) {
      if (totalDays >= phase.minDays && totalDays <= phase.maxDays) {
        return phase;
      }
    }
    return growthPhases.last;
  }
}

class TimeService {
  static int getTotalMinutes(List<ReadingSession> sessions) {
    return sessions.fold(0, (sum, s) => sum + s.durationMinutes);
  }

  static String getTotalHoursFormatted(List<ReadingSession> sessions, bool isAm) {
    final minutes = getTotalMinutes(sessions);
    final hours = minutes / 60.0;
    return '${hours.toStringAsFixed(1)} ${isAm ? "ሰዓታት" : "hours"}';
  }
}

class EncouragementService {
  static String getMessage(int streak, ReadingSession? lastSession, bool isAm) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final readYesterday = lastSession != null &&
        lastSession.dateCompleted.year == yesterday.year &&
        lastSession.dateCompleted.month == yesterday.month &&
        lastSession.dateCompleted.day == yesterday.day;

    if (streak == 0) {
      return isAm ? "ተመለስ — ኩነኔ የለም። እሱ ይጠብቃል።" : "Come back — no condemnation. He's waiting.";
    }
    if (streak == 1) {
      return isAm ? "ዛሬ ጀመርክ — ይህ በቂ ነው።" : "You started today — that's enough.";
    }
    if (streak < 7) {
      return isAm ? "በእኔ ውሰጥ ጸንሁ፣ እኔም በእናንተ እጸናለሁ።" : "Remain in me, He remains in you.";
    }
    if (streak % 7 == 0) {
      return isAm ? "ሌላ ሳምንት ታማኝነት። እያደግህ ነው።" : "Another week of faithfulness. You're growing.";
    }
    return isAm ? "ማደግህን ቀጥል። እሱ ታማኝ ነው።" : "Keep growing. He is faithful.";
  }

  static String getVerse(int totalDays, bool isAm) {
    if (totalDays < 8) {
      return isAm ? "\"የእግዚአብሔር ሕግ ፍጹም ነው፥ ነፍስንም መልሶታል።\" — መዝሙር 19:7" : '"The law of the Lord is perfect, refreshing the soul." — Psalm 19:7';
    }
    if (totalDays < 31) {
      return isAm ? "\"ልቤ ላይ ቃልህን ሰውሬአለሁ፥ በአንተ እንዳልበድል።\" — መዝሙር 119:11" : '"I have hidden your word in my heart that I might not sin against you." — Psalm 119:11';
    }
    if (totalDays < 91) {
      return isAm ? "\"በቃልህ ብርሃን ለእግሮቼ መብራት፥ ለመንገዴም ብርሃን ነው።\" — መዝሙር 119:105" : '"Your word is a lamp to my feet and a light to my path." — Psalm 119:105';
    }
    return isAm ? "\"የእግዚአብሔርን ምሕረት በዘመኔ ሁሉ አያሳድደኝም እንጂ።\" — መዝሙር 23:6" : '"Surely your goodness and love will follow me all the days of my life." — Psalm 23:6';
  }
}
