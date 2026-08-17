import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Announces new releases to installed app versions: checks GitHub's latest
/// release once per day and posts a tappable notification when it is newer
/// than the running build. Older installed versions show this the moment
/// their users open the app, pointing them at the release page.
class UpdateCheckService {
  static const _repo = 'BesletApp/beslet-app';
  static const _latestUrl = 'https://api.github.com/repos/$_repo/releases/latest';
  static const _pageUrl = 'https://github.com/$_repo/releases';
  static const _lastCheckKey = 'update_check_last_day';
  static const _notifiedVersionKey = 'update_check_notified_version';

  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (prefs.getString(_lastCheckKey) == today) return;
      await prefs.setString(_lastCheckKey, today);

      final current = await PackageInfo.fromPlatform();
      final tag = await _fetchLatestTag();
      if (tag == null) return;
      if (!_isNewer(tag, current.version)) return;
      if (prefs.getString(_notifiedVersionKey) == tag) return;

      await prefs.setString(_notifiedVersionKey, tag);
      await _postUpdateNotification(tag);
    } catch (e) {
      debugPrint('[BesletAlarm] update check failed: $e');
    }
  }

  static Future<String?> _fetchLatestTag() async {
    final res = await http
        .get(Uri.parse(_latestUrl), headers: {'User-Agent': 'beslet-app'})
        .timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) return null;
    return _tagFromJson(res.body);
  }

  static String? _tagFromJson(String body) {
    try {
      final match = RegExp(r'"tag_name"\s*:\s*"([^"]+)"').firstMatch(body);
      return match?.group(1);
    } catch (_) {
      return null;
    }
  }

  static List<int> _parts(String version) {
    final clean = version.replaceAll(RegExp(r'^v'), '').split('+').first;
    return clean.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  }

  static bool _isNewer(String tag, String current) {
    final a = _parts(tag);
    final b = _parts(current);
    final n = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < n; i++) {
      final x = i < a.length ? a[i] : 0;
      final y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  static Future<void> _postUpdateNotification(String tag) async {
    final isAm = NotificationService.isAmharic;
    final title = isAm ? 'አዲስ ስሪት ተለቋል 📲' : 'New version available 📲';
    final body = isAm
        ? 'Beslet $tag ወጥቷል — ለማውረድ ይንኩ!'
        : 'Beslet $tag is out — tap to update.';
    await NotificationService.plugin.show(
      3007,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'app_update',
          'App Updates',
          channelDescription: 'New Beslet version announcements',
          importance: Importance.defaultImportance,
          priority: Priority.high,
        ),
      ),
      payload: _pageUrl,
    );
  }
}