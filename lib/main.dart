import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/widget_service.dart';
import 'core/services/prayer_reminder_service.dart';
import 'core/services/prayer_alarm_sound_service.dart';
import 'core/services/vineyard_reminder_service.dart';
import 'core/personalization/personalization_engine.dart';
import 'core/personalization/personalization_providers.dart';
import 'core/providers/database_provider.dart';
import 'core/providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
  try { await NotificationService.init(); } catch (_) {}
  try { await PrayerAlarmSoundService.ensureChannel(await PrayerAlarmSoundService.resolveAndroidSound()); } catch (_) {}
  NotificationService.navigateTo = (route) => AppRouter.router.go(route);
  try { await NotificationService.requestPermissions(); } catch (_) {}
  try {
    final prefs = await SharedPreferences.getInstance();
    final reminderTime = prefs.getString('reminderTime');
    if (reminderTime != null) {
      final parts = reminderTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 20;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await NotificationService.scheduleDailyReminder(hour, minute);
    }
  } catch (_) {}
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0A0A0A),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  try { await WidgetService.updateWidgetData(); } catch (_) {}
  try { await PrayerReminderService.updatePrayerNotificationContent(); } catch (_) {}

  final engine = await PersonalizationEngine.init();

  final container = ProviderContainer(
    overrides: [
      personalizationEngineProvider.overrideWithValue(engine),
    ],
  );
  final db = container.read(databaseProvider);
  String lang = 'en';
  try {
    final user = await container.read(userProvider.future);
    lang = user.lang;
  } catch (_) {}
  VineyardReminderService.configure(db, isAm: lang == 'am');
  try { await VineyardReminderService.refresh(); } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BesletApp(),
    ),
  );
}
