import 'package:beslet_app/core/services/prayer_topics_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PrayerTopicsService', () {
    test('starts with an empty list', () async {
      expect(await PrayerTopicsService.getTopics(), isEmpty);
    });

    test('saveTopics records what was written', () async {
      await PrayerTopicsService.saveTopics('For my family\nFor my work');
      expect(await PrayerTopicsService.getTopics(), 'For my family\nFor my work');
    });

    test('saving again edits the list in place', () async {
      await PrayerTopicsService.saveTopics('First draft');
      await PrayerTopicsService.saveTopics('First draft, then a new one');
      expect(await PrayerTopicsService.getTopics(), 'First draft, then a new one');
    });

    test('blank writes trim away', () async {
      await PrayerTopicsService.saveTopics('   ');
      expect(await PrayerTopicsService.getTopics(), isEmpty);
    });
  });
}
