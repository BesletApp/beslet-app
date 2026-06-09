import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
