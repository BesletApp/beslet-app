import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';
import 'prayer_alarm_sound_service.dart';
import 'prayer_verse_service.dart';

enum PrayerAlarmPermissionStatus { granted, notificationsDenied, exactAlarmDenied }

/// A single daily prayer appointment the user chose. `enabled` is quiet: a
/// time can rest without being forgotten. An appointment, never a metric.
class PrayerTime {
  final int id;
  final int hour;
  final int minute;
  final bool enabled;
  const PrayerTime({
    required this.id,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  PrayerTime copyWith({bool? enabled}) => PrayerTime(
        id: id, hour: hour, minute: minute, enabled: enabled ?? this.enabled);

  Map<String, Object> toJson() =>
      {'id': id, 'hour': hour, 'minute': minute, 'enabled': enabled};

  factory PrayerTime.fromJson(Map<String, Object?> json) => PrayerTime(
        id: (json['id'] as num).toInt(),
        hour: (json['hour'] as num).toInt(),
        minute: (json['minute'] as num).toInt(),
        enabled: json['enabled'] == null ? true : json['enabled'] as bool,
      );
}

class PrayerReminderService {
  static const _timesKey = 'prayer_times';
  static const _lastUpdateKey = 'prayer_reminder_last_update';
  static const _playbackRequestBase = 1000;
  static const _channel = MethodChannel('beslet_app/notifications');

  static final MethodChannel _soundChannel = MethodChannel('beslet_app/sounds');

  // ── Permissions ───────────────────────────────────────────
  static Future<PrayerAlarmPermissionStatus> ensurePermissions() async {
    final android = NotificationService.plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return PrayerAlarmPermissionStatus.granted;

    if (await android.requestNotificationsPermission() == false) {
      return PrayerAlarmPermissionStatus.notificationsDenied;
    }
    if (Platform.isAndroid && await android.requestExactAlarmsPermission() == false) {
      return PrayerAlarmPermissionStatus.exactAlarmDenied;
    }
    return PrayerAlarmPermissionStatus.granted;
  }

  static Future<void> openNotificationSettings() async {
    try { await _channel.invokeMethod('openNotificationSettings'); } catch (_) {}
  }

  static Future<void> openExactAlarmSettings() async {
    try { await _channel.invokeMethod('openExactAlarmSettings'); } catch (_) {}
  }

  // ── Prayer times (a rhythm of daily appointments) ─────────
  static Future<List<PrayerTime>> getPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_timesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PrayerTime.fromJson((e as Map).cast<String, Object?>()))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _savePrayerTimes(List<PrayerTime> times) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_timesKey, jsonEncode(times.map((t) => t.toJson()).toList()));
  }

  static Future<void> addPrayerTime(int hour, int minute) async {
    final times = await getPrayerTimes();
    final nextId =
        times.isEmpty ? 1 : times.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    times.add(PrayerTime(id: nextId, hour: hour, minute: minute));
    await _savePrayerTimes(times);
    await syncSchedules();
  }

  static Future<void> setPrayerTimeEnabled(int id, bool enabled) async {
    final times = await getPrayerTimes();
    await _savePrayerTimes(
        times.map((t) => t.id == id ? t.copyWith(enabled: enabled) : t).toList());
    await syncSchedules();
  }

  static Future<void> removePrayerTime(int id) async {
    final times = await getPrayerTimes();
    final removed = times.where((t) => t.id == id).toList();
    await _savePrayerTimes(times.where((t) => t.id != id).toList());
    for (final r in removed) {
      try { await _cancelPlaybackAlarm(_playbackRequestBase + r.id); } catch (_) {}
    }
    await syncSchedules();
  }

  static Future<void> clearAllPrayerTimes() async {
    await _savePrayerTimes([]);
    await syncSchedules();
  }

  /// The next enabled prayer time as an actual clock moment. Wraps to
  /// tomorrow when every enabled time has already passed today.
  static ({PrayerTime time, DateTime when})? nextPrayerOccurrence(
      List<PrayerTime> times, DateTime now) {
    final enabled = times.where((t) => t.enabled).toList();
    if (enabled.isEmpty) return null;
    PrayerTime? bestTime;
    DateTime? best;
    for (final t in enabled) {
      var candidate = DateTime(now.year, now.month, now.day, t.hour, t.minute);
      if (!candidate.isAfter(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }
      if (best == null || candidate.isBefore(best)) {
        best = candidate;
        bestTime = t;
      }
    }
    return (time: bestTime!, when: best!);
  }

  // ── Scheduling: cancel everything, then arm every enabled time ──
  static Future<void> syncSchedules() async {
    if (!Platform.isAndroid) return;
    try { await NotificationService.init(); } catch (_) {}
    final times = await getPrayerTimes();

    for (final t in times) {
      try { await _cancelPlaybackAlarm(_playbackRequestBase + t.id); } catch (_) {}
    }
    for (final t in times.where((t) => t.enabled)) {
      await _scheduleOne(t);
    }
  }

  static Future<void> _scheduleOne(PrayerTime t) async {
    AndroidNotificationSound sound;
    try {
      sound = await PrayerAlarmSoundService.resolveAndroidSound();
    } catch (_) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));

    final dayIndex = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    final verse = PrayerVerseService.getPrayerVerse(dayIndex);
    final isAm = NotificationService.isAmharic;
    final title = isAm ? 'የጸሎት ጊዜ! 🙏' : 'Time to pray! 🙏';
    final body = '${verse.textAm} — ${verse.reference}';

    try {
      await _soundChannel.invokeMethod('schedulePlaybackAlarm', {
        'timestamp': scheduledDate.millisecondsSinceEpoch,
        'soundUri': _soundUriFor(sound),
        'title': title,
        'body': body,
        'hour': t.hour,
        'minute': t.minute,
        'verseText': verse.textAm,
        'verseRef': verse.reference,
        'dayIndex': dayIndex,
        'lang': isAm ? 'am' : 'en',
        'requestCode': _playbackRequestBase + t.id,
      });
    } catch (_) {}
  }

  /// A URI the native side understands for every sound flavour:
  /// custom phone files come as `content://`, the system alarm ringtone as
  /// `content://...`, and the bundled raw resource is marked resource://
  /// so Kotlin maps it to `android.resource://…/raw/prayer_alarm`.
  static String? _soundUriFor(AndroidNotificationSound sound) {
    if (sound is UriAndroidNotificationSound) return sound.sound;
    return 'resource://prayer_alarm';
  }

  static Future<void> _cancelPlaybackAlarm(int requestCode) async {
    try {
      await _soundChannel.invokeMethod('cancelPlaybackAlarm', {
        'requestCode': requestCode,
      });
    } catch (_) {}
  }

  // ── Housekeeping ──────────────────────────────────────────
  static Future<void> rescheduleAfterSoundChange() async {
    await syncSchedules();
  }

  /// Refreshes the day's verse on each scheduled time, at most once a day.
  static Future<void> updatePrayerNotificationContent() async {
    final times = await getPrayerTimes();
    if (times.every((t) => !t.enabled)) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString(_lastUpdateKey) == today) return;
    await syncSchedules();
    await prefs.setString(_lastUpdateKey, today);
  }
}
