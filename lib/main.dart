import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
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
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Africa/Addis_Ababa'));
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

  // Only local, fast startup work stays before the first frame: the
  // personalization engine (SharedPreferences) and the Riverpod container.
  final engine = await PersonalizationEngine.init();
  final container = ProviderContainer(
    overrides: [
      personalizationEngineProvider.overrideWithValue(engine),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BesletApp(),
    ),
  );

  // The native icon is dismissed the moment Flutter draws its first frame.
  // Everything plugin-bound then warms up in the background, each step
  // time-boxed so a hung platform channel can never trap the app again.
  WidgetsBinding.instance.addPostFrameCallback((_) => _warmStart(container));
}

Future<void> _warmStart(ProviderContainer container) async {
  FlutterNativeSplash.remove();

  await _attempt(() => NotificationService.init());
  NotificationService.navigateTo = (route) => AppRouter.router.go(route);
  await _attempt(() async {
    final sound = await PrayerAlarmSoundService.resolveAndroidSound();
    await PrayerAlarmSoundService.ensureChannel(sound);
  });
  await _attempt(() => NotificationService.requestPermissions());

  try {
    final prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 2));
    final reminderTime = prefs.getString('reminderTime');
    if (reminderTime != null) {
      final parts = reminderTime.split(':');
      final hour = int.tryParse(parts[0]) ?? 20;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      await _attempt(() => NotificationService.scheduleDailyReminder(hour, minute));
    }
  } catch (_) {}

  await _attempt(() => WidgetService.updateWidgetData());
  await _attempt(() => PrayerReminderService.updatePrayerNotificationContent());

  final db = container.read(databaseProvider);
  String lang = 'en';
  try {
    final user = await container.read(userProvider.future).timeout(const Duration(seconds: 2));
    lang = user.lang;
  } catch (_) {}
  VineyardReminderService.configure(db, isAm: lang == 'am');
  await _attempt(() => VineyardReminderService.refresh());
}

/// Runs a startup step with a hard time box so a slow or hung platform call
/// can never block the app or the splash from dismissing.
Future<void> _attempt(
  Future<void> Function() step, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  try {
    await step().timeout(timeout);
  } catch (_) {}
}
