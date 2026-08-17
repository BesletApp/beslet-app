import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'daily_verse_service.dart';
import 'prayer_reminder_service.dart';
import 'scripture_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String route)? navigateTo;

  static final _rng = Random();
  static bool _isAmharicLang = true;

  static void setLanguage(bool isAm) => _isAmharicLang = isAm;

  static bool get isAmharic => _isAmharicLang;

  // ── Helpers ────────────────────────────────────────────────
  static const _eveningPoolEn = [
    ('⏰ Time to reflect', 'You planned tasks today. How did it go? Take a moment to review.'),
    ('🌙 Day is done', '"Do not let the sun go down on your anger." — Ephesians 4:26. How was your day?'),
    ('✨ Evening check-in', '"Give thanks to the Lord, for he is good; his love endures forever." — Psalm 118:29'),
    ('🕯️ Quiet evening', '"In peace I will both lie down and sleep; for you alone, O Lord, make me dwell in safety." — Psalm 4:8'),
    ('📖 How was today?', '"Let the words of my mouth and the meditation of my heart be acceptable in your sight." — Psalm 19:14'),
    ('🌟 The Lord watches over you', '"The Lord will watch over your coming and going both now and forevermore." — Psalm 121:8'),
    ('💭 Pause and reflect', '"Search me, O God, and know my heart! Try me and know my thoughts!" — Psalm 139:23'),
    ('🌙 Gentle reminder', '"Come to me, all who labor and are heavy laden, and I will give you rest." — Matthew 11:28'),
  ];

  static const _comebackPoolEn = [
    '"The steadfast love of the Lord never ceases; his mercies are new every morning." — Lamentations 3:22-23. Today is a fresh start.',
    '"He who began a good work in you will bring it to completion." — Philippians 1:6. You haven\'t failed — you\'re still growing.',
    '"But they who wait for the Lord shall renew their strength." — Isaiah 40:31. Welcome back, friend.',
    '"My grace is sufficient for you, for my power is made perfect in weakness." — 2 Corinthians 12:9. Today is a new beginning.',
    '"The Lord is not slow to fulfill his promise... but is patient toward you." — 2 Peter 3:9. He\'s always glad to see you.',
    '"Because of the Lord\'s great love we are not consumed, for his compassions never fail. They are new every morning." — Lamentations 3:22-23',
    '"Sing to the Lord a new song, for he has done marvelous things!" — Psalm 98:1. Every day is a chance to start again.',
    '"I will restore to you the years that the swarming locust has eaten." — Joel 2:25. God redeems every season.',
    '"The Lord is near to all who call on him." — Psalm 145:18. He never left — and he\'s thrilled you\'re here.',
    '"Therefore, if anyone is in Christ, he is a new creation. The old has passed away; behold, the new has come." — 2 Corinthians 5:17',
  ];

  static const _eveningPoolAm = [
    ('⏰ ለማሰላሰል ጊዜ', 'ዛሬ ሥራ አቅደህ ነበር። እንዴት ሆነ? ለማሰላሰል ጊዜ ውሰድ።'),
    ('🌙 ቀን አልፏል', '"በቍጣችሁ ኃጢአትን አትሥሩ፤ ፀሐይ በቍጣችሁ ላይ አትግባ።" — ኤፌሶን 4፥26'),
    ('✨ የማታ ግምገማ', '"እግዚአብሔር መልካም ነውና አመሰግኑት፤ ቸርነቱ ለዘላለም ነው።" — መዝሙር 118፥29'),
    ('🕯️ ሰላማዊ ማታ', '"በሰላም ተኝቼ ያርፋለሁ፤ አንተ ብቻ አቤቱ በደህና ታኖረኛለህ።" — መዝሙር 4፥8'),
    ('📖 ቀንህ እንዴት ነበር?', '"የአፌ ቃልና የልቤ ማሰላሰያ በፊትህ ተቀባይ ይሁን።" — መዝሙር 19፥14'),
    ('🌟 እግዚአብሔር ይጠብቅሃል', '"እግዚአብሔር መውጣትህንና መግባትህን ይጠብቃል።" — መዝሙር 121፥8'),
    ('💭 አቁምና አሰላስል', '"እግዚአብሔር ሆይ ፈትሸኝ ልቤንም እወቅ።" — መዝሙር 139፥23'),
    ('🌙 ገር አስታዋሽ', '"እናንተ ደከማችሁ የተሸከማችሁም ሁሉ ወደ እኔ ኑ፤ እኔም አሳርፋችኋለሁ።" — ማቴዎስ 11፥28'),
  ];

  static const _comebackPoolAm = [
    '"የእግዚአብሔር ቸርነት አያልቅም፤ ምሕረቱም በየቀኑ ታዳሳለች።" — ልቅሶ 3፥22-23። ዛሬ አዲስ ጅማሮ ነው።',
    '"በእናንተ መልካም ሥራ የጀመረ እስከ ፍጻሜ ድረስ ያደርሰዋል።" — ፊልጵስዩስ 1፥6። አልተሸነፍህም — እያደግህ ነው።',
    '"እግዚአብሔርን የሚጠባበቁ ኃይላቸውን ያድሳሉ።" — ኢሳይያስ 40፥31። እንኳን ደህና መጣህ።',
    '"ጸጋዬ ይበቃሃል፤ ኃይሌ በድካም ይፈጸማልና።" — 2 ቆሮንቶስ 12፥9። ዛሬ አዲስ ጅማሮ ነው።',
    '"እግዚአብሔር የተስፋውን ነገር ስለ ማዘግየት አይዘገይም ... ነገር ግን ይታገሣል።" — 2 ጴጥሮስ 3፥9። ሁሌም ሊያይህ ደስ ይለዋል።',
    '"ከእግዚአብሔር ታላቅ ፍቅር የተነሣ አልጠፋንም፤ ምሕረቱ በየቀኑ ታድሳለች።" — ልቅሶ 3፥22-23',
    '"ለእግዚአብሔር አዲስ ዝማሬ ዘምሩ፤ ድንቅ ነገርን አድርጓልና!" — መዝሙር 98፥1። በየቀኑ እንደገና መጀመር ይቻላል።',
    '"አንበጣ የበላቸውን ዓመታት እመልሳለሁ።" — ኢዮኤል 2፥25። እግዚአብሔር ዘመንን ሁሉ ይቤዣል።',
    '"እግዚአብሔር በሚጠሩት ሁሉ ላይ ቅርብ ነው።" — መዝሙር 145፥18። እርሱ ፈጽሞ አልራቀም።',
    '"ስለዚህ ማንም በክርስቶስ ቢሆን አዲስ ፍጥረት ነው፤ ያለፈው አልፏል፤ እነሆ አዲስ ሆኗል።" — 2 ቆሮንቶስ 5፥17',
  ];

  static const _eveningReviewId = 1001;
  static const _dailyReminderId = 1004;
  static const _streakBrokenId = 1003;

  // ── Helpers ────────────────────────────────────────────────
  static Future<int> _nextIndex(String key, int poolSize) async {
    final prefs = await SharedPreferences.getInstance();
    final i = (prefs.getInt(key) ?? _rng.nextInt(poolSize)) % poolSize;
    await prefs.setInt(key, i + 1);
    return i;
  }

  static Future<void> _schedule({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String payload = '/home',
  }) async {
    tzdata.initializeTimeZones();
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduledDate = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      channelId, channelName,
      channelDescription: channelDesc,
      importance: Importance.high, priority: Priority.high,
    );
    await plugin.zonedSchedule(
      id, title, body, scheduledDate,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ── Init ───────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false,
    );
    await plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    await _createChannels();
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try { await android?.requestFullScreenIntentPermission(); } catch (_) {}
    _initialized = true;
  }

  static void _onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'dismiss_alarm') {
      PrayerReminderService.stopAlarmNow();
      return;
    }
    final route = response.payload ?? '/prayer';
    navigateTo?.call(route);
  }

  // ── Prayer alarm (plugin leg of the dual trigger) ──────────
  /// The independent duplicate of the native prayer alarm: a daily exact
  /// zonedSchedule with its own audible channel. When an OEM battery manager
  /// or a frozen process swallows the native AlarmManager chain, this leg
  /// still rings — and vice versa. The fire instant is taken from the
  /// device-local [fire] moment, so it can never drift from the countdown.
  /// Always uses the bundled raw sound on its own dedicated channel so the
  /// leg never depends on a user-picked tone that may not resolve.
  static Future<void> schedulePrayerAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime fire,
    String payload = '/prayer',
  }) async {
    tzdata.initializeTimeZones();
    final details = AndroidNotificationDetails(
      'prayer_alarm_system',
      'Prayer Alarm',
      channelDescription: 'Daily prayer alarm with scripture',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      fullScreenIntent: true,
      actions: [
        AndroidNotificationAction(
          'dismiss_alarm',
          _isAmharicLang ? 'ማቆም' : 'Dismiss',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ],
    );
    final when = tz.TZDateTime.from(fire, tz.local);
    await plugin.zonedSchedule(
      id, title, body, when,
      NotificationDetails(android: details),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
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
      description: 'Grace-based encouragement after missed days', importance: Importance.high,
    ));
    await android.createNotificationChannel(AndroidNotificationChannel(
      'prayer_alarm_system', 'Prayer Alarm',
      description: 'Daily prayer alarm with scripture',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      sound: const RawResourceAndroidNotificationSound('prayer_alarm'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
    ));
  }

  // ── Morning / Dawn Reminder ────────────────────────────────
  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    await cancelDailyReminder();
    final now = tz.TZDateTime.now(tz.local);
    final verse = await DailyVerseService.resolveDay(now);
    final title = _isAmharicLang ? ScriptureService.amharicReference(verse.reference) : verse.reference;
    final body = _isAmharicLang ? (verse.textAm ?? verse.text) : verse.text;
    await _schedule(
      id: _dailyReminderId, channelId: 'morning_reminder', channelName: 'Morning Reminder',
      channelDesc: 'Daily morning habit reminder',
      title: title, body: body, hour: hour, minute: minute,
      payload: '/threshold',
    );
  }

  static Future<void> cancelDailyReminder() async {
    await plugin.cancel(_dailyReminderId);
  }

  // ── Evening Review ─────────────────────────────────────────
  static Future<void> scheduleEveningReview() async {
    final prefs = await SharedPreferences.getInstance();
    // The evening closing is a daily rhythm: re-armed once per calendar day
    // so the greeting rotates from the pool each evening, never a stale one.
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastArm = prefs.getString('eveningReviewLastDate');
    if (lastArm == today) return;
    await prefs.setString('eveningReviewLastDate', today);

    final pool = _isAmharicLang ? _eveningPoolAm : _eveningPoolEn;
    final i = await _nextIndex('eveningMsgIndex', pool.length);
    final (title, body) = pool[i];
    await _schedule(
      id: _eveningReviewId, channelId: 'evening_reminder', channelName: 'Evening Reminder',
      channelDesc: 'Evening check-in reminder',
      title: title, body: body, hour: 19, minute: 0,
      payload: '/daily-todo',
    );
  }

  static Future<void> cancelEveningReview() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('eveningReviewLastDate');
    await plugin.cancel(_eveningReviewId);
  }

  // ── Fresh Start (comeback) ─────────────────────────────────
  static Future<void> scheduleFreshStart() async {
    final pool = _isAmharicLang ? _comebackPoolAm : _comebackPoolEn;
    final i = await _nextIndex('comebackMsgIndex', pool.length);
    final body = pool[i];
    await _schedule(
      id: _streakBrokenId, channelId: 'streak_reminder', channelName: 'Streak Reminder',
      channelDesc: 'Grace-based encouragement after missed days',
      title: _isAmharicLang ? 'ዛሬ አዲስ ምሕረት 🌅' : 'New mercies this morning 🌅',
      body: body, hour: 8, minute: 0,
    );
  }

  static Future<void> cancelStreakNotifications() async {
    await plugin.cancel(_streakBrokenId);
  }

  // ── Permissions ────────────────────────────────────────────
  static Future<bool> requestPermissions() async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      return true;
    }
    return false;
  }
}
