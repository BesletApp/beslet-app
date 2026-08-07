import 'package:shared_preferences/shared_preferences.dart';

/// A single persistent list of prayer topics — written once, remembered every
/// time, edited in place whenever the person wants. Stored as plain text so it
/// stays simple and easy to understand.
class PrayerTopicsService {
  static const _topicsKey = 'prayer_topics';

  static Future<String> getTopics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_topicsKey) ?? '';
  }

  static Future<void> saveTopics(String text) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_topicsKey, text.trim());
  }
}
