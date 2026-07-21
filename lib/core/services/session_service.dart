import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _sessionsKey = 'total_sessions';
  static const String _lastActiveKey = 'last_active_date';

  static Future<int> getTotalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_sessionsKey) ?? 0;
  }

  static Future<String?> getLastActiveDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastActiveKey);
  }

  static Future<void> recordVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastActive = prefs.getString(_lastActiveKey);

    if (lastActive != today) {
      final current = prefs.getInt(_sessionsKey) ?? 0;
      await prefs.setInt(_sessionsKey, current + 1);
      await prefs.setString(_lastActiveKey, today);
    }
  }
}
