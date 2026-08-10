import 'package:shared_preferences/shared_preferences.dart';

/// The daily cap on AI-generated studies, so a shared bundled key is never a
/// surprise bill and the app stays offline-first. The curated bank is free and
/// unlimited; only model-generated notes count against the gate.
class StudyUsageGate {
  static const int dailyCap = 5;
  static const String _prefix = 'study_usage_';

  /// Local day used to bucket usage (same shape as AiBoundaryGate.dayKeyFor).
  static String dayKeyFor(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<int> usedToday(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getInt('$_prefix${dayKeyFor(now)}') ?? 0;
      return raw < 0 ? 0 : raw;
    } catch (_) {
      return dailyCap; // on failure, refuse rather than spend the key
    }
  }

  static Future<bool> mayStudy(DateTime now) async {
    try {
      return await usedToday(now) < dailyCap;
    } catch (_) {
      return false;
    }
  }

  static Future<void> record(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final day = dayKeyFor(now);
      final next = (prefs.getInt('$_prefix$day') ?? 0) + 1;
      await prefs.setInt('$_prefix$day', next);
    } catch (_) {
      // Usage bookkeeping must never break a study.
    }
  }
}