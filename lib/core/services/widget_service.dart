import 'package:home_widget/home_widget.dart';
import 'scripture_service.dart';

class WidgetService {
  static Future<void> updateWidgetData({int? planDay}) async {
    final verse = ScriptureService.getDailyScripture();
    final day = planDay ?? (DateTime.now().difference(DateTime(2025, 1, 1)).inDays % 90) + 1;

    await HomeWidget.saveWidgetData<String>('verseAm', verse.textAm ?? verse.text);
    await HomeWidget.saveWidgetData<String>('verseEn', verse.reference);
    await HomeWidget.saveWidgetData<String>('dayLabel', 'Day $day of 90');

    await HomeWidget.updateWidget(
      androidName: 'BesletWidget',
    );
  }
}
