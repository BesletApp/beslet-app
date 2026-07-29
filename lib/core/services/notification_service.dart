import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'prayer_reminder_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static void Function(String route)? navigateTo;

  static final _rng = Random();
  static bool _isAmharicLang = true;

  static void setLanguage(bool isAm) => _isAmharicLang = isAm;

  // ── Message Pools ──────────────────────────────────────────
  static const _dawnPoolEn = [
    ('Good morning! ☀️', '"This is the day the Lord has made; let us rejoice and be glad in it." — Psalm 118:24'),
    ('Rise and shine! 🌅', '"The steadfast love of the Lord never ceases; his mercies are new every morning." — Lamentations 3:22-23'),
    ('New day, new grace ✨', '"Because of the Lord\'s great love we are not consumed, for his compassions never fail." — Lamentations 3:22'),
    ('Morning light 🌞', '"Jesus spoke to them, saying, \'I am the light of the world. Whoever follows me will not walk in darkness.\'" — John 8:12'),
    ('Awake, my soul! 🎵', '"I will give thanks to the Lord with my whole heart; I will recount all of your wonderful deeds." — Psalm 9:1'),
    ('Today is a gift 🎁', '"Every good gift and every perfect gift is from above." — James 1:17'),
    ('Walk in love 🕊️', '"Walk in love, as Christ loved us and gave himself up for us." — Ephesians 5:2'),
    ('Seek Him first 🙏', '"Seek first the kingdom of God and his righteousness, and all these things will be added to you." — Matthew 6:33'),
    ('Be still 🕯️', '"Be still, and know that I am God." — Psalm 46:10'),
    ('You are loved ❤️', '"I have loved you with an everlasting love; therefore I have continued my faithfulness to you." — Jeremiah 31:3'),
  ];

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

  static const _dawnPoolAm = [
    ('ደህና እድሜ! ☀️', '"ይህ እግዚአብሔር ያደረገው ቀን ነው፤ በእርሱ ደስ እንይል ሐሴትም እናድርግ።" — መዝሙር 118፥24'),
    ('ንቁ! 🌅', '"የእግዚአብሔር ቸርነት አያልቅም፤ ምሕረቱም በየቀኑ ታድሳለች።" — ልቅሶ 3፥22-23'),
    ('አዲስ ቀን አዲስ ጸጋ ✨', '"ከእግዚአብሔር ታላቅ ፍቅር የተነሣ አልጠፋንም፤ ምሕረቱ አያልቅምና።" — ልቅሶ 3፥22'),
    ('የማለዳ ብርሃን 🌞', '"እኔ የዓለም ብርሃን ነኝ፤ የሚከተለኝ በጨለማ አይሄድም።" — ዮሐንስ 8፥12'),
    ('ነፍሴ ሆይ ንቂ! 🎵', '"እግዚአብሔርን በፍጹም ልቤ አመሰግናለሁ፤ ድንቅ ሥራዎችህን ሁሉ እናገራለሁ።" — መዝሙር 9፥1'),
    ('ዛሬ ስጦታ ነው 🎁', '"መልካም ስጦታ ሁሉ ከላይ ከአባት ይወርዳል።" — ያዕቆብ 1፥17'),
    ('በፍቅር ተመላለሱ 🕊️', '"ክርስቶስ እንደ ወደደን በፍቅር ተመላለሱ።" — ኤፌሶን 5፥2'),
    ('መጀመሪያ እርሱን ፈልጉ 🙏', '"መጀመሪያ የእግዚአብሔርን መንግሥት ፈልጉ፤ ይህ ሁሉ ይጨመርላችኋል።" — ማቴዎስ 6፥33'),
    ('ጸጥ ይበሉ 🕯️', '"ጸጥ በሉ እኔም አምላክ እንደ ሆንሁ እወቁ።" — መዝሙር 46፥10'),
    ('ተወድደዋል ❤️', '"በዘላለም ፍቅር ወድጄሃለሁ፤ በቸርነትም ጎትቼሃለሁ።" — ኤርምያስ 31፥3'),
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
    await android.createNotificationChannel(const AndroidNotificationChannel(
      'streak_reminder', 'Streak Reminder',
      description: 'Grace-based encouragement after missed days', importance: Importance.high,
    ));
  }

  // ── Morning / Dawn Reminder ────────────────────────────────
  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    await cancelDailyReminder();
    final pool = _isAmharicLang ? _dawnPoolAm : _dawnPoolEn;
    final i = await _nextIndex('dawnMsgIndex', pool.length);
    final (title, body) = pool[i];
    await _schedule(
      id: _dailyReminderId, channelId: 'morning_reminder', channelName: 'Morning Reminder',
      channelDesc: 'Daily morning habit reminder',
      title: title, body: body, hour: hour, minute: minute,
    );
  }

  static Future<void> cancelDailyReminder() async {
    await plugin.cancel(_dailyReminderId);
  }

  // ── Evening Review ─────────────────────────────────────────
  static Future<void> scheduleEveningReview() async {
    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool('eveningReviewScheduled') ?? false;
    if (already) return;
    await prefs.setBool('eveningReviewScheduled', true);

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
    await prefs.setBool('eveningReviewScheduled', false);
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
