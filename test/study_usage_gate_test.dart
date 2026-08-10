import 'package:beslet_app/core/ai/study/study_usage_gate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StudyUsageGate', () {
    test('starts at zero and increments on record', () async {
      final now = DateTime(2026, 8, 10, 9);
      expect(await StudyUsageGate.usedToday(now), 0);
      await StudyUsageGate.record(now);
      expect(await StudyUsageGate.usedToday(now), 1);
    });

    test('allows up to the daily cap, then refuses', () async {
      final now = DateTime(2026, 8, 10, 9);
      for (var i = 0; i < StudyUsageGate.dailyCap; i++) {
        expect(await StudyUsageGate.mayStudy(now), isTrue);
        await StudyUsageGate.record(now);
      }
      expect(await StudyUsageGate.mayStudy(now), isFalse);
    });

    test('usage is bucketed per local day', () async {
      final day1 = DateTime(2026, 8, 10, 23, 59);
      final day2 = DateTime(2026, 8, 11, 0, 1);
      await StudyUsageGate.record(day1);
      expect(await StudyUsageGate.usedToday(day1), 1);
      expect(await StudyUsageGate.usedToday(day2), 0);
    });

    test('dayKeyFor formats zero-padded keys', () {
      expect(StudyUsageGate.dayKeyFor(DateTime(2026, 8, 5)), '2026-08-05');
    });
  });
}