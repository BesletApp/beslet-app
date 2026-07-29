import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class PrayerAlarmSoundService {
  static const _soundUriKey = 'prayer_alarm_sound_uri';
  static const _soundNameKey = 'prayer_alarm_sound_name';
  static const _isCustomKey = 'prayer_alarm_is_custom';
  static const _allowedExtensions = ['mp3', 'wav', 'ogg', 'm4a', 'aac', 'flac', '3gp', 'amr'];

  static const _channel = MethodChannel('beslet_app/sounds');

  static const AndroidNotificationSound bundledSound =
      RawResourceAndroidNotificationSound('prayer_alarm');

  static Future<AndroidNotificationSound> resolveAndroidSound() async {
    final isCustom = await _isCustom();
    final storedUri = await _getSoundUri();
    if (isCustom && storedUri != null && storedUri.isNotEmpty) {
      return UriAndroidNotificationSound(storedUri);
    }
    try {
      final systemUri = await _channel.invokeMethod<String>('getDefaultAlarmUri');
      if (systemUri != null && systemUri.isNotEmpty) {
        await _clearCustomPrefs();
        return UriAndroidNotificationSound(systemUri);
      }
    } catch (_) {}
    await _clearCustomPrefs();
    return bundledSound;
  }

  static String channelIdFor(AndroidNotificationSound sound) {
    if (sound == bundledSound) return 'prayer_alarm_v3';
    if (sound is UriAndroidNotificationSound) {
      return 'prayer_alarm_v3_${sound.sound.hashCode.abs()}';
    }
    return 'prayer_alarm_v3';
  }

  static Future<void> deleteChannel(String channelId) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('deleteNotificationChannel', {'id': channelId});
    } catch (_) {}
  }

  static Future<void> ensureChannel(AndroidNotificationSound sound) async {
    if (kIsWeb || !Platform.isAndroid) return;
    final android = NotificationService.plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    final channelId = channelIdFor(sound);
    await deleteChannel(channelId);

    await android.createNotificationChannel(AndroidNotificationChannel(
      channelId,
      'Prayer Reminder',
      description: 'Daily prayer alarm with scripture',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: sound,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
  }

  static Future<String?> pickAndSaveFromPhone() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedExtensions,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final sourcePath = picked.path;
    if (sourcePath == null || sourcePath.isEmpty) return null;

    final ext = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw PrayerAlarmSoundException('Unsupported format. Use MP3, WAV, OGG, or M4A.');
    }

    final uri = await _channel.invokeMethod<String>('saveAlarmSound', {
      'src': sourcePath,
      'ext': ext,
    });
    if (uri == null || uri.isEmpty) {
      throw PrayerAlarmSoundException('Could not save the alarm sound.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_soundUriKey, uri);
    await prefs.setString(_soundNameKey, picked.name.isNotEmpty ? picked.name : p.basename(sourcePath));
    await prefs.setBool(_isCustomKey, true);
    return uri;
  }

  static Future<void> useDefaultTone() async {
    await _clearCustomPrefs();
    final sound = await resolveAndroidSound();
    await ensureChannel(sound);
  }

  static Future<String?> getSoundDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_isCustomKey) == true) return prefs.getString(_soundNameKey);
    return null;
  }

  static Future<bool> hasCustomSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isCustomKey) ?? false;
  }

  static Future<String?> _getSoundUri() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_soundUriKey);
  }

  static Future<bool> _isCustom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isCustomKey) ?? false;
  }

  static Future<void> _clearCustomPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_soundUriKey);
    await prefs.remove(_soundNameKey);
    await prefs.remove(_isCustomKey);
  }
}

class PrayerAlarmSoundException implements Exception {
  final String message;
  PrayerAlarmSoundException(this.message);
  @override
  String toString() => message;
}
