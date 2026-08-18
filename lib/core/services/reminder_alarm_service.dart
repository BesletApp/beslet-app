import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// A phone-style one-off reminder: fires at a chosen moment, shows a written
/// note, and never repeats. The UI list lives in [SharedPreferences] (source
/// of truth); the actual ring is a dual trigger just like the prayer alarm —
/// a native exact AlarmManager chain (with snooze/dismiss handled on the
/// native side) plus an independent one-shot plugin notification on its own
/// gentle channel, so at least one path rings on every OEM.
class ReminderAlarm {
  final int id;
  final DateTime fireAt;
  final String note;

  const ReminderAlarm({required this.id, required this.fireAt, required this.note});

  Map<String, Object?> toJson() => {
        'id': id,
        'fireAt': fireAt.millisecondsSinceEpoch,
        'note': note,
      };

  static ReminderAlarm fromJson(Map<String, Object?> json) => ReminderAlarm(
        id: (json['id'] as num).toInt(),
        fireAt: DateTime.fromMillisecondsSinceEpoch((json['fireAt'] as num).toInt()),
        note: (json['note'] as String?) ?? '',
      );
}

class ReminderAlarmService {
  static const _prefsKey = 'reminder_alarms';
  static const _nativeBase = 4000;
  static const _pluginBase = 5000;
  static const _snoozeMinutes = 9;

  static const _soundChannel = MethodChannel('beslet_app/sounds');

  static Future<List<ReminderAlarm>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => ReminderAlarm.fromJson((e as Map).cast<String, Object?>()))
          .toList();
      final now = DateTime.now();
      final stale = list.where((a) => !a.fireAt.isAfter(now)).toList();
      if (stale.isNotEmpty) {
        for (final a in stale) {
          await _purgePlugin(a.id);
        }
        await _save(list.where((a) => a.fireAt.isAfter(now)).toList());
        return list.where((a) => a.fireAt.isAfter(now)).toList();
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _save(List<ReminderAlarm> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(alarms.map((a) => a.toJson()).toList()),
    );
  }

  static Future<ReminderAlarm> add({required DateTime fireAt, required String note}) async {
    final alarms = await load();
    final id = alarms.isEmpty ? 1 : alarms.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    final alarm = ReminderAlarm(id: id, fireAt: fireAt, note: note.trim());
    await _save([...alarms, alarm]);

    // Enabling a reminder is the moment to surface the notification
    // permission prompt on Android 13+ (no-op when already granted).
    try {
      await NotificationService.requestPermissions();
    } catch (_) {}

    try {
      await _soundChannel.invokeMethod('scheduleOnceReminder', {
        'requestCode': _nativeBase + id,
        'timestamp': fireAt.millisecondsSinceEpoch,
        'note': alarm.note,
      });
    } catch (e) {
      debugPrint('[BesletReminder] native schedule failed id=$id: $e');
    }

    try {
      await NotificationService.scheduleReminderAlarm(
        id: _pluginBase + id,
        note: alarm.note,
        fire: fireAt,
      );
    } catch (e) {
      debugPrint('[BesletReminder] plugin schedule failed id=$id: $e');
    }

    return alarm;
  }

  static Future<void> remove(int id) async {
    final alarms = await load();
    await _save(alarms.where((a) => a.id != id).toList());
    try {
      await _soundChannel.invokeMethod('cancelOnceReminder', {
        'requestCode': _nativeBase + id,
      });
    } catch (_) {}
    await _purgePlugin(id);
  }

  static Future<void> snooze(int id) async {
    final alarms = await load();
    final index = alarms.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final alarm = alarms[index];
    final newFireAt = DateTime.now().add(const Duration(minutes: _snoozeMinutes));
    final updated = ReminderAlarm(id: alarm.id, fireAt: newFireAt, note: alarm.note);
    final updatedList = [...alarms]..[index] = updated;
    await _save(updatedList);
    try {
      await _soundChannel.invokeMethod('snoozeReminder', {
        'requestCode': _nativeBase + id,
      });
    } catch (_) {}
  }

  static Future<void> _purgePlugin(int id) async {
    try {
      await NotificationService.plugin.cancel(_pluginBase + id);
    } catch (_) {}
  }
}