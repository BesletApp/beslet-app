import 'dart:convert';

import 'package:beslet_app/core/services/prayer_reminder_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PrayerTime', () {
    test('serializes and restores', () {
      const t = PrayerTime(id: 3, hour: 6, minute: 30, enabled: true);
      final restored = PrayerTime.fromJson(
          (jsonDecode(jsonEncode(t.toJson())) as Map).cast<String, Object?>());
      expect(restored.id, 3);
      expect(restored.hour, 6);
      expect(restored.minute, 30);
      expect(restored.enabled, true);
    });

    test('copyWith changes only enabled', () {
      const t = PrayerTime(id: 1, hour: 9, minute: 0);
      expect(t.copyWith(enabled: false).enabled, false);
      expect(t.copyWith(enabled: false).id, 1);
      expect(t.copyWith(enabled: false).hour, 9);
      expect(t.copyWith(enabled: false).minute, 0);
    });
  });

  group('PrayerReminderService', () {
    test('starts with no prayer times', () async {
      expect(await PrayerReminderService.getPrayerTimes(), isEmpty);
    });

    test('addPrayerTime persists a time and assigns ids', () async {
      await PrayerReminderService.addPrayerTime(6, 30);
      await PrayerReminderService.addPrayerTime(12, 0);
      final times = await PrayerReminderService.getPrayerTimes();
      expect(times.length, 2);
      expect(times.first.hour, 6);
      expect(times.first.minute, 30);
      expect(times.first.id, 1);
      expect(times.last.id, 2);
      expect(times.first.enabled, true);
    });

    test('setPrayerTimeEnabled quietly rests a time', () async {
      await PrayerReminderService.addPrayerTime(6, 30);
      final id = (await PrayerReminderService.getPrayerTimes()).first.id;
      await PrayerReminderService.setPrayerTimeEnabled(id, false);
      final times = await PrayerReminderService.getPrayerTimes();
      expect(times.single.enabled, false);
      expect(times.single.id, id, reason: 'a resting time keeps its place');
    });

    test('removePrayerTime lets a time go', () async {
      await PrayerReminderService.addPrayerTime(6, 30);
      await PrayerReminderService.addPrayerTime(19, 0);
      final first = (await PrayerReminderService.getPrayerTimes()).first;
      await PrayerReminderService.removePrayerTime(first.id);
      final times = await PrayerReminderService.getPrayerTimes();
      expect(times.length, 1);
      expect(times.single.hour, 19);
    });

    test('clearAllPrayerTimes empties the list', () async {
      await PrayerReminderService.addPrayerTime(6, 30);
      await PrayerReminderService.clearAllPrayerTimes();
      expect(await PrayerReminderService.getPrayerTimes(), isEmpty);
    });

    test('updatePrayerNotificationContent records today once', () async {
      await PrayerReminderService.addPrayerTime(6, 30);
      await PrayerReminderService.updatePrayerNotificationContent();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('prayer_reminder_last_update'),
          DateTime.now().toIso8601String().substring(0, 10));
      await PrayerReminderService.updatePrayerNotificationContent();
    });

    test('updatePrayerNotificationContent is a no-op with no enabled times',
        () async {
      await PrayerReminderService.addPrayerTime(6, 30);
      final id = (await PrayerReminderService.getPrayerTimes()).first.id;
      await PrayerReminderService.setPrayerTimeEnabled(id, false);
      await PrayerReminderService.updatePrayerNotificationContent();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('prayer_reminder_last_update'), isNull);
    });

    test('nextPrayerOccurrence picks the next enabled clock moment', () {
      final times = [
        PrayerTime(id: 1, hour: 6, minute: 0),
        PrayerTime(id: 2, hour: 18, minute: 0),
      ];
      final now = DateTime(2026, 8, 7, 10, 0);
      final next = PrayerReminderService.nextPrayerOccurrence(times, now)!;
      expect(next.time.hour, 18);
      expect(next.when, DateTime(2026, 8, 7, 18, 0));
    });

    test('nextPrayerOccurrence wraps to tomorrow when today has passed', () {
      final times = [
        PrayerTime(id: 1, hour: 6, minute: 0),
        PrayerTime(id: 2, hour: 18, minute: 0),
      ];
      final after = DateTime(2026, 8, 7, 19, 0);
      final next = PrayerReminderService.nextPrayerOccurrence(times, after)!;
      expect(next.time.hour, 6);
      expect(next.when, DateTime(2026, 8, 8, 6, 0));
    });

    test('nextPrayerOccurrence ignores resting times and empty lists', () {
      final times = [
        PrayerTime(id: 1, hour: 6, minute: 0, enabled: false),
        PrayerTime(id: 2, hour: 18, minute: 0, enabled: true),
      ];
      final now = DateTime(2026, 8, 7, 5, 0);
      final next = PrayerReminderService.nextPrayerOccurrence(times, now)!;
      expect(next.time.hour, 18);
      expect(PrayerReminderService.nextPrayerOccurrence([], now), isNull);
      expect(
          PrayerReminderService.nextPrayerOccurrence(
              [PrayerTime(id: 1, hour: 6, minute: 0, enabled: false)], now),
          isNull);
    });

    test('nextPrayerOccurrence keeps adjacent slots in order across midnight',
        () {
      final times = [
        PrayerTime(id: 1, hour: 23, minute: 55),
        PrayerTime(id: 2, hour: 0, minute: 5),
      ];
      final now = DateTime(2026, 8, 7, 23, 58);
      final next = PrayerReminderService.nextPrayerOccurrence(times, now)!;
      expect(next.time.hour, 0, reason: '00:05 is the next slot, not 23:55');
      expect(next.when, DateTime(2026, 8, 8, 0, 5));
    });

    test('nextLocalMoment stays today while upcoming and rolls tomorrow after',
        () {
      final now = DateTime(2026, 8, 7, 10, 30);
      expect(PrayerReminderService.nextLocalMoment(18, 0, now),
          DateTime(2026, 8, 7, 18, 0));
      expect(PrayerReminderService.nextLocalMoment(6, 0, now),
          DateTime(2026, 8, 8, 6, 0));
      expect(PrayerReminderService.nextLocalMoment(10, 30, now),
          DateTime(2026, 8, 8, 10, 30),
          reason: 'exactly now counts as reached, matching the countdown');
    });

    test('scheduled epoch matches the countdown moment (single source of time)',
        () {
      final times = [PrayerTime(id: 1, hour: 5, minute: 30)];
      final now = DateTime(2026, 8, 7, 2, 0);
      final next = PrayerReminderService.nextPrayerOccurrence(times, now)!;
      // _scheduleOne arms at nextLocalMoment(...), which must equal the
      // countdown's next.when — a regression here means the alarm fires at a
      // wall-clock time different from what the screen promised.
      expect(
          PrayerReminderService.nextLocalMoment(next.time.hour, next.time.minute, now),
          next.when);
      expect(
          PrayerReminderService.nextLocalMoment(next.time.hour, next.time.minute, now)
              .millisecondsSinceEpoch,
          next.when.millisecondsSinceEpoch);
    });
  });
}
