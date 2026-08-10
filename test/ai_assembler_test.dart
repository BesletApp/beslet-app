import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/ai/ai_assembler.dart';
import 'package:beslet_app/core/ai/ai_models.dart';

void main() {
  const assembler = AiContextAssembler();

  ContextPacket build({
    bool isAmharic = false,
    DateTime? now,
    int streak = 0,
    bool isRestDay = false,
    bool wasAway = false,
    bool completed = false,
  }) =>
      assembler.assemble(
        isAmharic: isAmharic,
        now: now ?? DateTime(2026, 8, 9, 9),
        currentStreak: streak,
        isRestDay: isRestDay,
        wasAwayForDays: wasAway,
        completedToday: completed,
      );

  group('AiContextAssembler (anti-surveillance contract)', () {
    test('maps language bucket', () {
      expect(build(isAmharic: false).language, AiLanguageBucket.english);
      expect(build(isAmharic: true).language, AiLanguageBucket.amharic);
    });

    test('maps day part by hour', () {
      expect(build(now: DateTime(2026, 1, 1, 8)).dayPart, AiDayPartBucket.morning);
      expect(build(now: DateTime(2026, 1, 1, 14)).dayPart, AiDayPartBucket.afternoon);
      expect(build(now: DateTime(2026, 1, 1, 19)).dayPart, AiDayPartBucket.evening);
      expect(build(now: DateTime(2026, 1, 1, 23)).dayPart, AiDayPartBucket.night);
    });

    test('maps maturity from the journey season', () {
      expect(build(streak: 0).maturity, AiMaturityBucket.seeding);
      expect(build(streak: 10).maturity, AiMaturityBucket.growing);
      expect(build(streak: 30).maturity, AiMaturityBucket.rooted);
      expect(build(streak: 200).maturity, AiMaturityBucket.rooted);
    });

    test('maps engagement coarsely', () {
      expect(build(completed: true).engagement, AiEngagementBucket.deep);
      expect(build(streak: 5, completed: false).engagement, AiEngagementBucket.steady);
      expect(build(streak: 0, completed: false).engagement, AiEngagementBucket.low);
    });

    test('flags returning after absence and rest days', () {
      expect(build(wasAway: true).absence, AiAbsenceBucket.returning);
      expect(build(wasAway: false).absence, AiAbsenceBucket.present);
      expect(build(isRestDay: true).isRestDay, isTrue);
    });

    test('fasting bucket exists but is off until Phase 2', () {
      expect(build().isFastingSeason, isFalse);
    });
  });
}
