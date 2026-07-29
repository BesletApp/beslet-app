import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'notification_service.dart';
import 'prayer_alarm_sound_service.dart';
import 'prayer_verse_service.dart';

enum PrayerAlarmPermissionStatus { granted, notificationsDenied, exactAlarmDenied }

class PrayerReminderService {
  static const _hourKey = 'prayer_reminder_hour';
  static const _minuteKey = 'prayer_reminder_minute';
  static const _lastUpdateKey = 'prayer_reminder_last_update';
  static const _notificationId = 100;
  static const _testNotificationId = 101;
  static const _playbackRequestCode = 1000;
  static const _alarmActiveKey = 'prayer_alarm_active';
  static const _channel = MethodChannel('beslet_app/notifications');

  static final MethodChannel _soundChannel = MethodChannel('beslet_app/sounds');

  static Future<bool> isAlarmActive() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_alarmActiveKey) ?? false;
  }

  static Future<void> _setAlarmActive(bool active) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alarmActiveKey, active);
  }

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

  static Future<void> schedulePrayerReminder(int hour, int minute) async {
    await NotificationService.init();
    final permission = await ensurePermissions();
    if (permission != PrayerAlarmPermissionStatus.granted) {
      throw PrayerReminderException(_permissionMessage(permission));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, hour);
    await prefs.setInt(_minuteKey, minute);

    final sound = await PrayerAlarmSoundService.resolveAndroidSound();
    await PrayerAlarmSoundService.ensureChannel(sound);
    await NotificationService.plugin.cancel(_notificationId);
    await _cancelPlaybackAlarm();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) scheduledDate = scheduledDate.add(const Duration(days: 1));

    final dayIndex = DateTime.now().difference(DateTime(2025, 1, 1)).inDays;
    final verse = PrayerVerseService.getPrayerVerse(dayIndex);
    final title = 'Time to pray! 🙏';
    final body = '${verse.textAm} — ${verse.reference}';
    final channelId = PrayerAlarmSoundService.channelIdFor(sound);

    await NotificationService.plugin.zonedSchedule(
      _notificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, 'Prayer Reminder',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: false,
          enableVibration: false,
          silent: true,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          fullScreenIntent: true,
          actions: [
            AndroidNotificationAction('dismiss_alarm', '🔕 Stop Alarm',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/prayer',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _schedulePlaybackAlarm(scheduledDate, sound, title, body);
  }

  static Future<void> testAlarmNow({Duration delay = const Duration(seconds: 3)}) async {
    await NotificationService.init();
    final permission = await ensurePermissions();
    if (permission != PrayerAlarmPermissionStatus.granted) {
      throw PrayerReminderException(_permissionMessage(permission));
    }
    final sound = await PrayerAlarmSoundService.resolveAndroidSound();
    await PrayerAlarmSoundService.ensureChannel(sound);
    final channelId = PrayerAlarmSoundService.channelIdFor(sound);

    final soundUri = sound is UriAndroidNotificationSound ? sound.sound : null;
    final title = 'Prayer alarm test 🔔';
    final body = 'If you hear this, your prayer reminder is working!';
    final fireAt = DateTime.now().add(delay);

    // Schedule the native alarm to play for 5 minutes
    try {
      await _soundChannel.invokeMethod('schedulePlaybackAlarm', {
        'timestamp': fireAt.millisecondsSinceEpoch,
        'soundUri': soundUri,
        'title': title,
        'body': body,
        'requestCode': _testNotificationId,
      });
      await _setAlarmActive(true);
    } catch (_) {}

    await Future<void>.delayed(delay + const Duration(seconds: 1));

    await NotificationService.plugin.show(
      _testNotificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, 'Prayer Reminder',
          importance: Importance.max, priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: false, enableVibration: false, silent: true,
          category: AndroidNotificationCategory.alarm,
          actions: [
            AndroidNotificationAction('dismiss_alarm', '🔕 Stop Alarm',
              cancelNotification: true,
              showsUserInterface: false,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true, presentBadge: true, presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
    );
  }

  static Future<void> _schedulePlaybackAlarm(
      tz.TZDateTime scheduledDate, AndroidNotificationSound sound, String title, String body) async {
    final soundUri = sound is UriAndroidNotificationSound ? sound.sound : null;
    try {
      await _soundChannel.invokeMethod('schedulePlaybackAlarm', {
        'timestamp': scheduledDate.millisecondsSinceEpoch,
        'soundUri': soundUri,
        'title': title,
        'body': body,
        'requestCode': _notificationId + _playbackRequestCode,
      });
    } catch (_) {}
  }

  static Future<void> _cancelPlaybackAlarm() async {
    try {
      await _soundChannel.invokeMethod('cancelPlaybackAlarm', {
        'requestCode': _notificationId + _playbackRequestCode,
      });
    } catch (_) {}
  }

  static Future<void> stopAlarmNow() async {
    try { await _soundChannel.invokeMethod('stopAlarmNow'); } catch (_) {}
    await _setAlarmActive(false);
  }

  static Future<void> cancelPrayerReminder() async {
    await NotificationService.plugin.cancel(_notificationId);
    await NotificationService.plugin.cancel(_testNotificationId);
    await _cancelPlaybackAlarm();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hourKey);
    await prefs.remove(_minuteKey);
    await prefs.remove(_lastUpdateKey);
  }

  static Future<void> rescheduleAfterSoundChange() async {
    final time = await getReminderTime();
    if (time == null) return;
    await schedulePrayerReminder(time.hour, time.minute);
  }

  static Future<void> updatePrayerNotificationContent() async {
    final time = await getReminderTime();
    if (time == null) return;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (prefs.getString(_lastUpdateKey) == today) return;
    await schedulePrayerReminder(time.hour, time.minute);
    await prefs.setString(_lastUpdateKey, today);
  }

  static Future<({int hour, int minute})?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_hourKey);
    final minute = prefs.getInt(_minuteKey);
    if (hour == null || minute == null) return null;
    return (hour: hour, minute: minute);
  }

  static String _permissionMessage(PrayerAlarmPermissionStatus status) {
    switch (status) {
      case PrayerAlarmPermissionStatus.notificationsDenied:
        return 'Notifications are disabled. Enable them in Settings to hear the prayer alarm.';
      case PrayerAlarmPermissionStatus.exactAlarmDenied:
        return 'Exact alarms are disabled. Enable "Alarms & reminders" for Beslet in Settings.';
      case PrayerAlarmPermissionStatus.granted:
        return '';
    }
  }
}

class PrayerReminderException implements Exception {
  final String message;
  PrayerReminderException(this.message);
  @override
  String toString() => message;
}
