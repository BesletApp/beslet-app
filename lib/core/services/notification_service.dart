import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'prayer_reminder_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String route)? navigateTo;

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true,
    );
    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    await _createChannels();
    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'dismiss_alarm') {
      PrayerReminderService.stopAlarmNow();
    }
    final route = response.payload ?? '/prayer';
    navigateTo?.call(route);
  }

  static Future<void> _createChannels() async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'morning_reminder', 'Morning Reminder',
      description: 'Daily morning habit reminder', importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'evening_reminder', 'Evening Reminder',
      description: 'Evening check-in reminder', importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'xp_earned', 'XP Updates',
      description: 'XP earned notifications', importance: Importance.defaultImportance,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'streak_reminder', 'Streak Reminder',
      description: 'Streak risk and broken streak alerts', importance: Importance.high,
    ));
  }

  static const _eveningReviewId = 1001;
  static const _streakRiskId = 1002;
  static const _streakBrokenId = 1003;

  static Future<void> scheduleEveningReview() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool('eveningReviewScheduled') ?? false;
    if (already) return;
    await prefs.setBool('eveningReviewScheduled', true);

    tzdata.initializeTimeZones();
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, 19, 0);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'evening_reminder', 'Evening Reminder',
      channelDescription: 'Evening check-in reminder',
      importance: Importance.high, priority: Priority.high,
    );
    await plugin.zonedSchedule(
      _eveningReviewId,
      '⏰ Time to review your day!',
      'You planned tasks today. How did it go?',
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/daily-todo',
    );
  }

  static Future<void> cancelEveningReview() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eveningReviewScheduled', false);
    await plugin.cancel(_eveningReviewId);
  }

  static Future<void> scheduleStreakRisk() async {
    tzdata.initializeTimeZones();
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, 18, 0);
    if (scheduledDate.isBefore(now)) return;

    final androidDetails = AndroidNotificationDetails(
      'streak_reminder', 'Streak Reminder',
      channelDescription: 'Streak risk and broken streak alerts',
      importance: Importance.high, priority: Priority.high,
    );
    await plugin.zonedSchedule(
      _streakRiskId,
      '🔥 Streak at risk!',
      'Complete your prayer or Bible reading to keep your streak alive.',
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/daily-todo',
    );
  }

  static Future<void> scheduleStreakBroken() async {
    tzdata.initializeTimeZones();
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, 8, 0);
    if (scheduledDate.isBefore(now)) return;

    final androidDetails = AndroidNotificationDetails(
      'streak_reminder', 'Streak Reminder',
      channelDescription: 'Streak risk and broken streak alerts',
      importance: Importance.high, priority: Priority.high,
    );
    await plugin.zonedSchedule(
      _streakBrokenId,
      '💔 Streak broken',
      'Your streak ended yesterday. Repair it by doing double today (pray twice or read 2 chapters).',
      scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/daily-todo',
    );
  }

  static Future<void> cancelStreakNotifications() async {
    await plugin.cancel(_streakRiskId);
    await plugin.cancel(_streakBrokenId);
  }

  static Future<bool> requestPermissions() async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      return true;
    }
    return false;
  }
}
