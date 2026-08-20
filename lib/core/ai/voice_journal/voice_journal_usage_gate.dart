import 'package:shared_preferences/shared_preferences.dart';

/// The daily cap on AI-organized voice journals, so the bundled free key is
/// never a surprise bill. "Voice Journal" is on-demand and separate from the
/// Study workbook and Delve Deeper, so it keeps its own independent allowance
/// (its own prefix and its own, independent daily cap). A reader who connects
/// their own Gemini key is never subject to it.
class VoiceJournalUsageGate {
  /// The daily voice-journal cap applies only to the app's bundled free key.
  static const int dailyCap = 10;
  static const String _prefix = 'voice_journal_usage_';

  /// Local day used to bucket usage (same shape as the Study/Delve gates).
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

  static Future<bool> mayOrganize(DateTime now) async {
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
      // Usage bookkeeping must never break an organized journal.
    }
  }
}