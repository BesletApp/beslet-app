import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/services/widget_service.dart';

void main() {
  group('lightStateFor', () {
    DateTime at(int hour, int minute) => DateTime(2025, 1, 1, hour, minute);

    test('boundary table', () {
      final cases = <(DateTime, LampLight)>[
        (at(4, 59), LampLight.night),
        (at(5, 0), LampLight.dawn),
        (at(11, 59), LampLight.dawn),
        (at(12, 0), LampLight.noon),
        (at(16, 59), LampLight.noon),
        (at(17, 0), LampLight.dusk),
        (at(19, 59), LampLight.dusk),
        (at(20, 0), LampLight.night),
        (at(23, 59), LampLight.night),
        (at(0, 0), LampLight.night),
      ];
      for (final (time, expected) in cases) {
        expect(WidgetService.lightStateFor(time), expected,
            reason: '${time.hour}:${time.minute}');
      }
    });
  });

  group('widgetDataFor', () {
    test('maps a dawn moment in English', () {
      final data = widgetDataFor(DateTime(2025, 1, 1, 6, 0), isAm: false);
      expect(data['verseEn'], 'Philippians 4:13');
      expect(data['verseAm'], isNotNull);
      expect(data['lightState'], 'dawn');
      expect(data['lightLabel'], 'Dawn');
    });

    test('maps a dawn moment in Amharic', () {
      final data = widgetDataFor(DateTime(2025, 1, 1, 6, 0), isAm: true);
      expect(data['lightState'], 'dawn');
      expect(data['lightLabel'], 'ጠዋት');
    });

    test('maps each light state label', () {
      expect(widgetDataFor(DateTime(2025, 1, 1, 13, 0))['lightLabel'], 'Noon');
      expect(widgetDataFor(DateTime(2025, 1, 1, 18, 0))['lightLabel'], 'Dusk');
      expect(widgetDataFor(DateTime(2025, 1, 1, 23, 0))['lightLabel'], 'Night');
    });

    test('verseEn is the thread reference for that day', () {
      final data = widgetDataFor(DateTime(2025, 1, 2, 6, 0));
      expect(data['verseEn'], 'Psalm 23:1');
    });
  });
}
