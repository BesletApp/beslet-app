import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/ai/ai_boundary.dart';
import 'package:beslet_app/core/ai/ai_models.dart';

void main() {
  const gate = AiBoundaryGate();

  group('AiBoundaryGate.allows', () {
    test('seeding users get up to the daily cap', () {
      expect(gate.allows(
        todayMomentCount: 0,
        maturity: AiMaturityBucket.seeding,
        absence: AiAbsenceBucket.present,
      ), isTrue);
      expect(gate.allows(
        todayMomentCount: 2,
        maturity: AiMaturityBucket.seeding,
        absence: AiAbsenceBucket.present,
      ), isTrue);
      expect(gate.allows(
        todayMomentCount: 3,
        maturity: AiMaturityBucket.seeding,
        absence: AiAbsenceBucket.present,
      ), isFalse);
    });

    test('growing users are heard a little less', () {
      expect(gate.allows(
        todayMomentCount: 0,
        maturity: AiMaturityBucket.growing,
        absence: AiAbsenceBucket.present,
      ), isTrue);
      expect(gate.allows(
        todayMomentCount: 2,
        maturity: AiMaturityBucket.growing,
        absence: AiAbsenceBucket.present,
      ), isFalse);
    });

    test('rooted users are near-silent — at most one a day', () {
      expect(gate.allows(
        todayMomentCount: 0,
        maturity: AiMaturityBucket.rooted,
        absence: AiAbsenceBucket.present,
      ), isTrue);
      expect(gate.allows(
        todayMomentCount: 1,
        maturity: AiMaturityBucket.rooted,
        absence: AiAbsenceBucket.present,
      ), isFalse);
    });

    test('a returning user gets exactly one gentle pointer, then silence', () {
      expect(gate.allows(
        todayMomentCount: 0,
        maturity: AiMaturityBucket.seeding,
        absence: AiAbsenceBucket.returning,
      ), isTrue);
      expect(gate.allows(
        todayMomentCount: 1,
        maturity: AiMaturityBucket.seeding,
        absence: AiAbsenceBucket.returning,
      ), isFalse);
    });
  });

  group('AiBoundaryGate.dayKeyFor', () {
    test('formats local date as yyyy-MM-dd', () {
      expect(AiBoundaryGate.dayKeyFor(DateTime(2026, 8, 9)), '2026-08-09');
      expect(AiBoundaryGate.dayKeyFor(DateTime(2026, 1, 1)), '2026-01-01');
    });
  });
}
