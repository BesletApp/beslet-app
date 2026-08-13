import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'daily_verse_service.dart';
import 'scripture_service.dart';

enum LampLight { dawn, noon, dusk, night }

@visibleForTesting
Map<String, String> widgetDataFor(DateTime moment, {bool isAm = false}) {
  final verse = ScriptureService.threadVerseFor(moment);
  final light = WidgetService.lightStateFor(moment);
  final label = switch (light) {
    LampLight.dawn => isAm ? 'ጠዋት' : 'Dawn',
    LampLight.noon => isAm ? 'ቀትር' : 'Noon',
    LampLight.dusk => isAm ? 'ምሽት' : 'Dusk',
    LampLight.night => isAm ? 'ሌሊት' : 'Night',
  };
  return {
    'verseAm': verse.textAm ?? verse.text,
    'verseEn': verse.reference,
    'lightState': light.name,
    'lightLabel': label,
  };
}

class WidgetService {
  /// The Lamp at Dawn: a light-state that shifts with the hour, never a feed
  /// or notification.
  static LampLight lightStateFor(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 12) return LampLight.dawn;
    if (h >= 12 && h < 17) return LampLight.noon;
    if (h >= 17 && h < 20) return LampLight.dusk;
    return LampLight.night;
  }

  static Future<void> updateWidgetData({DateTime? now, bool isAm = false}) async {
    final moment = now ?? DateTime.now();
    final verse = await DailyVerseService.resolveDay(moment);
    final data = widgetDataFor(moment, isAm: isAm);
    await HomeWidget.saveWidgetData<String>('verseAm', verse.textAm ?? verse.text);
    await HomeWidget.saveWidgetData<String>('verseEn', verse.reference);
    await HomeWidget.saveWidgetData<String>('lightState', data['lightState']!);
    await HomeWidget.saveWidgetData<String>('lightLabel', data['lightLabel']!);

    await HomeWidget.updateWidget(
      androidName: 'BesletWidget',
    );
  }
}
