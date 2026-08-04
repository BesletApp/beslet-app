import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:beslet_app/core/services/growth_content.dart';
import 'package:beslet_app/core/services/vineyard_reminder_content.dart';

ReminderContext ctx({int day = 20, int mood = 3, bool isAm = false}) => ReminderContext(
  day: day,
  movement: GrowthContent.movementFor(day, 30),
  stage: GrowthContent.vineStageFor(day, 30),
  intention: JourneyIntention.heart,
  mood: mood,
  isAm: isAm,
);

void main() {
  group('pickCard', () {
    test('returns a card with non-empty fields', () {
      final picked = VineyardReminderContent.pickCard(ctx(), history: const []);
      expect(picked.card.title, isNotEmpty);
      expect(picked.card.body, isNotEmpty);
      expect(picked.card.bigText, isNotEmpty);
      expect(picked.key, contains(':'));
    });

    test('does not repeat a recently sent key while alternatives exist', () {
      final picked = VineyardReminderContent.pickCard(ctx(), history: const []);
      final again = VineyardReminderContent.pickCard(ctx(), history: [picked.key]);
      expect(again.card.kind, isNot(picked.card.kind));
    });

    test('never returns the same kind twice in a row even with full history', () {
      var history = <String>[];
      ReminderKind? previous;
      for (var i = 0; i < 20; i++) {
        final picked = VineyardReminderContent.pickCard(ctx(day: i + 1), history: history);
        if (previous != null) expect(picked.card.kind, isNot(previous));
        previous = picked.card.kind;
        history = [...history, picked.key];
      }
    });

    test('returns Amharic content when isAm is true', () {
      final picked = VineyardReminderContent.pickCard(ctx(isAm: true), history: const []);
      expect(picked.card.body.runes.any((r) => r >= 0x1200 && r <= 0x137F), isTrue);
    });
  });

  group('pickNextFire', () {
    test('gentle picks a fire 1-3 days ahead in the window', () {
      final now = DateTime(2026, 8, 4, 12, 0);
      final rng = Random(7);
      for (var i = 0; i < 50; i++) {
        final fire = VineyardReminderContent.pickNextFire(
          now,
          frequency: ReminderFrequency.gentle,
          evening: true,
          rng: rng,
        );
        final days = fire.difference(DateTime(now.year, now.month, now.day)).inDays;
        expect(days, inInclusiveRange(1, 3));
        expect(fire.hour, inInclusiveRange(18, 20));
      }
    });

    test('attentive schedules the very next day', () {
      final now = DateTime(2026, 8, 4, 12, 0);
      final fire = VineyardReminderContent.pickNextFire(
        now,
        frequency: ReminderFrequency.attentive,
        evening: false,
        rng: Random(1),
      );
      expect(fire.difference(DateTime(now.year, now.month, now.day)).inDays, 1);
      expect(fire.hour, inInclusiveRange(7, 9));
    });
  });
}
