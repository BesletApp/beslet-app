import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:drift/drift.dart' hide Column;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../database/app_database.dart';
import 'growth_content.dart';
import 'notification_service.dart';
import 'vineyard_reminder_content.dart';

/// "Vineyard visits": gentle, irregular, context-aware reminders from the
/// Growth zone. They never nag — they visit like a gardener, 1–3 days apart,
/// with content drawn from the journey's own state and never repeated nearby.
class VineyardReminderService {
  const VineyardReminderService._();

  static const _id = 1010;
  static const _channelId = 'vineyard_reminder';
  static const _enabledKey = 'vineyardVisitsEnabled';
  static const _frequencyKey = 'vineyardVisitsFrequency';
  static const _windowKey = 'vineyardVisitsWindow';
  static const _nextFireKey = 'vineyardNextFire';
  static const _historyKey = 'vineyardReminderHistory';

  static AppDatabase? _db;
  static bool _isAm = true;

  static void configure(AppDatabase db, {required bool isAm}) {
    _db = db;
    _isAm = isAm;
  }

  static void setLanguage(bool isAm) => _isAm = isAm;

  // ── Public control ───────────────────────────────────────────────
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    if (!enabled) await prefs.remove(_nextFireKey);
    // Turning Vineyard visits on is the moment to surface the notification
    // permission prompt on Android 13+ (no-op when already granted).
    if (enabled) {
      try {
        await NotificationService.requestPermissions();
      } catch (_) {}
    }
    await refresh();
  }

  static Future<void> setFrequency(ReminderFrequency frequency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_frequencyKey, frequency.name);
    await refresh();
  }

  static Future<void> setWindow(bool evening) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_windowKey, evening ? 'evening' : 'morning');
    await refresh();
  }

  /// Recompute the next visit (or cancel) based on current state.
  static Future<void> refresh() async {
    final db = _db;
    if (db == null) return;
    final prefs = await SharedPreferences.getInstance();

    if (!(prefs.getBool(_enabledKey) ?? false)) {
      await _cancel();
      return;
    }

    final journey = await _latestJourney(db);
    if (journey == null || journey.harvested) {
      await _cancel();
      return;
    }

    final nextStr = prefs.getString(_nextFireKey);
    final next = nextStr != null ? DateTime.tryParse(nextStr) : null;
    if (next != null && next.isAfter(DateTime.now())) return; // already scheduled

    final mood = await _todayMood(db);
    final start = DateTime.tryParse(journey.startDate) ?? DateTime.now();
    final day = GrowthContent.journeyDay(start, DateTime.now());
    final ctx = ReminderContext(
      day: day,
      movement: GrowthContent.movementFor(day, journey.timeframeDays),
      stage: GrowthContent.vineStageFor(day, journey.timeframeDays),
      intention: JourneyIntention.values.firstWhere(
        (i) => i.name == journey.intention,
        orElse: () => JourneyIntention.abide,
      ),
      mood: mood,
      isAm: _isAm,
    );

    final history = prefs.getStringList(_historyKey) ?? <String>[];
    final picked = VineyardReminderContent.pickCard(ctx, history: history);
    final frequency = prefs.getString(_frequencyKey) == ReminderFrequency.attentive.name
        ? ReminderFrequency.attentive
        : ReminderFrequency.gentle;
    final evening = prefs.getString(_windowKey) == 'evening';
    final fire = VineyardReminderContent.pickNextFire(
      DateTime.now(),
      frequency: frequency,
      evening: evening,
    );

    await _schedule(picked.card, fire);
    await prefs.setString(_nextFireKey, fire.toIso8601String());
    final trimmed = [...history, picked.key];
    await prefs.setStringList(_historyKey, trimmed.length > 14 ? trimmed.sublist(trimmed.length - 14) : trimmed);
  }

  // ── Scheduling ───────────────────────────────────────────────────
  static Future<void> _schedule(ReminderCard card, DateTime fire) async {
    tzdata.initializeTimeZones();
    final location = tz.local;
    final when = tz.TZDateTime(location, fire.year, fire.month, fire.day, fire.hour, fire.minute);

    final channelName = _isAm ? 'የወይን እርሻ' : 'The Vineyard';
    final channelDesc = _isAm
        ? 'ከወይን እርሻ ገር ጉብኝት — ማበረታቻና ማስታወሻ'
        : 'Gentle visits from the Vineyard — encouragement, never pressure';

    final android = NotificationService.plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(AndroidNotificationChannel(
      _channelId, channelName,
      description: channelDesc,
      importance: Importance.high,
    ));

    await NotificationService.plugin.zonedSchedule(
      _id, card.title, card.body, when,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF4A7C3F),
          ledColor: const Color(0xFF4A7C3F),
          ledOnMs: 500,
          ledOffMs: 500,
          vibrationPattern: Int64List.fromList([0, 300, 200, 300]),
          visibility: NotificationVisibility.public,
          styleInformation: BigTextStyleInformation(card.bigText),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/progress',
    );
  }

  static Future<void> _cancel() async {
    await NotificationService.plugin.cancel(_id);
  }

  // ── Data reads ───────────────────────────────────────────────────
  static Future<GrowthJourneyData?> _latestJourney(AppDatabase db) async {
    final rows = await (db.select(db.growthJourney)
      ..orderBy([
        (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
      ])
    ).get();
    return rows.isEmpty ? null : rows.first;
  }

  static Future<int?> _todayMood(AppDatabase db) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final logs = await (db.select(db.soulLog)..where((t) => t.date.equals(today))).get();
    return logs.isEmpty ? null : logs.first.mood;
  }
}
