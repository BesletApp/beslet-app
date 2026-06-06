import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true);
    await _plugin.initialize(const InitializationSettings(android: androidSettings, iOS: iosSettings));
    _createChannels();
    _initialized = true;
  }

  static void _createChannels() {
    final morningChannel = AndroidNotificationChannel('morning_reminder', 'Morning Reminder', description: 'Daily morning habit reminder', importance: Importance.high);
    final eveningChannel = AndroidNotificationChannel('evening_reminder', 'Evening Reminder', description: 'Evening check-in reminder', importance: Importance.high);
    final xpChannel = AndroidNotificationChannel('xp_earned', 'XP Updates', description: 'XP earned notifications', importance: Importance.defaultImportance);
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(morningChannel);
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(eveningChannel);
    _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(xpChannel);
  }


}
