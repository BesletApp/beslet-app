import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'core/router/app_router.dart';
import 'core/config.dart';
import 'core/services/notification_service.dart';
import 'core/services/telegram_bible_service.dart';
import 'core/services/widget_service.dart';
import 'core/services/prayer_reminder_service.dart';
import 'core/services/prayer_alarm_sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
  try { await NotificationService.init(); } catch (_) {}
  try { await PrayerAlarmSoundService.ensureChannel(await PrayerAlarmSoundService.resolveAndroidSound()); } catch (_) {}
  NotificationService.navigateTo = (route) => AppRouter.router.go(route);
  try { await NotificationService.requestPermissions(); } catch (_) {}
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
  TelegramBibleService.setBaseUrl(AppConfig.bridgeUrl);
  runApp(const ProviderScope(child: BesletApp()));
}
