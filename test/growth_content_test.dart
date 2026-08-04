import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/services/growth_content.dart';
import 'package:beslet_app/core/services/widget_service.dart';

void main() {
  group('intentions', () {
    test('all six intentions have non-empty labels in both languages', () {
      for (final i in GrowthContent.intentions) {
        final l = GrowthContent.intentionLabel(i);
        final c = GrowthContent.intentionCommitment(i);
        expect(l.en, isNotEmpty);
        expect(l.am, isNotEmpty);
        expect(c.en, isNotEmpty);
        expect(c.am, isNotEmpty);
      }
    });
  });

  group('questions', () {
    test('question rotates deterministically through the pool', () {
      const intention = JourneyIntention.word;
      final q1 = GrowthContent.questionFor(intention, 1);
      final q2 = GrowthContent.questionFor(intention, 2);
      final q3 = GrowthContent.questionFor(intention, 3);
      final q4 = GrowthContent.questionFor(intention, 4);
      expect(q1.en, isNot(q2.en));
      expect(q2.en, isNot(q3.en));
      expect(q1.en, q4.en, reason: 'pool length is 3, so day 4 repeats day 1');
      expect(GrowthContent.questionFor(intention, 1).en, q1.en, reason: 'deterministic');
    });

    test('day 0 maps to the last question in the pool (wraps backwards safely)', () {
      final q = GrowthContent.questionFor(JourneyIntention.discipline, 0);
      final last = GrowthContent.questionFor(JourneyIntention.discipline, 3);
      expect(q.en, last.en);
    });

    test('each intention exposes its own question set', () {
      final word = GrowthContent.questionFor(JourneyIntention.word, 1).en;
      final service = GrowthContent.questionFor(JourneyIntention.service, 1).en;
      expect(word, isNot(service));
    });

    test('every question has an Amharic translation', () {
      for (final i in GrowthContent.intentions) {
        for (var d = 1; d <= 9; d++) {
          final q = GrowthContent.questionFor(i, d);
          expect(q.am, isNotEmpty);
        }
      }
    });
  });

  group('timeframes', () {
    test('bounded timeframes map to their day counts', () {
      expect(GrowthContent.daysFor(JourneyTimeframe.week), 7);
      expect(GrowthContent.daysFor(JourneyTimeframe.fortnight), 14);
      expect(GrowthContent.daysFor(JourneyTimeframe.month), 30);
      expect(GrowthContent.daysFor(JourneyTimeframe.season), 90);
      expect(GrowthContent.daysFor(JourneyTimeframe.open), isNull);
    });

    test('all timeframes have non-empty labels', () {
      for (final t in GrowthContent.timeframes) {
        final l = GrowthContent.timeframeLabel(t);
        expect(l.en, isNotEmpty);
        expect(l.am, isNotEmpty);
      }
    });
  });

  group('journey day', () {
    test('day 1 on the planting date', () {
      final start = DateTime(2026, 8, 3);
      expect(GrowthContent.journeyDay(start, start), 1);
    });

    test('advances one per elapsed day', () {
      final start = DateTime(2026, 8, 3);
      expect(GrowthContent.journeyDay(start, DateTime(2026, 8, 5)), 3);
    });

    test('clamps to at least 1 when start is in the future', () {
      final start = DateTime(2026, 8, 3);
      expect(GrowthContent.journeyDay(start, DateTime(2026, 8, 1)), 1);
    });
  });

  group('movement', () {
    test('90-day journey uses equal quartiles', () {
      expect(GrowthContent.movementFor(1, 90), JourneyMovement.planting);
      expect(GrowthContent.movementFor(22, 90), JourneyMovement.planting);
      expect(GrowthContent.movementFor(23, 90), JourneyMovement.rooting);
      expect(GrowthContent.movementFor(44, 90), JourneyMovement.rooting);
      expect(GrowthContent.movementFor(45, 90), JourneyMovement.growing);
      expect(GrowthContent.movementFor(66, 90), JourneyMovement.growing);
      expect(GrowthContent.movementFor(67, 90), JourneyMovement.fruiting);
      expect(GrowthContent.movementFor(90, 90), JourneyMovement.fruiting);
      expect(GrowthContent.movementFor(200, 90), JourneyMovement.fruiting, reason: 'never leaves fruiting');
    });

    test('short journey still passes through all four movements', () {
      expect(GrowthContent.movementFor(1, 7), JourneyMovement.planting);
      expect(GrowthContent.movementFor(2, 7), JourneyMovement.rooting);
      expect(GrowthContent.movementFor(3, 7), JourneyMovement.growing);
      expect(GrowthContent.movementFor(4, 7), JourneyMovement.fruiting);
      expect(GrowthContent.movementFor(10, 7), JourneyMovement.fruiting);
    });

    test('open journey matures slowly and then rests at fruiting', () {
      expect(GrowthContent.movementFor(1, null), JourneyMovement.planting);
      expect(GrowthContent.movementFor(7, null), JourneyMovement.planting);
      expect(GrowthContent.movementFor(8, null), JourneyMovement.rooting);
      expect(GrowthContent.movementFor(30, null), JourneyMovement.rooting);
      expect(GrowthContent.movementFor(31, null), JourneyMovement.growing);
      expect(GrowthContent.movementFor(90, null), JourneyMovement.growing);
      expect(GrowthContent.movementFor(91, null), JourneyMovement.fruiting);
      expect(GrowthContent.movementFor(500, null), JourneyMovement.fruiting);
    });
  });

  group('vine stage', () {
    test('day 1 is always the seed', () {
      expect(GrowthContent.vineStageFor(1, 90), VineStage.seed);
      expect(GrowthContent.vineStageFor(1, null), VineStage.seed);
    });

    test('bounded journey stages track its movements', () {
      expect(GrowthContent.vineStageFor(2, 90), VineStage.sprout);
      expect(GrowthContent.vineStageFor(23, 90), VineStage.rooted);
      expect(GrowthContent.vineStageFor(45, 90), VineStage.blooming);
      expect(GrowthContent.vineStageFor(67, 90), VineStage.fruiting);
    });

    test('open journey stages follow its gentle clock', () {
      expect(GrowthContent.vineStageFor(8, null), VineStage.rooted);
      expect(GrowthContent.vineStageFor(31, null), VineStage.blooming);
      expect(GrowthContent.vineStageFor(91, null), VineStage.fruiting);
    });
  });

  group('vine geometry', () {
    test('day 1 has no branches', () {
      expect(GrowthContent.vineGeometry(1, 90).branches, 0);
      expect(GrowthContent.vineGeometry(1, null).branches, 0);
    });

    test('a finished season reaches full growth and branch count', () {
      final g = GrowthContent.vineGeometry(90, 90);
      expect(g.growth01, 1.0);
      expect(g.branches, 8);
    });

    test('open journey grows gently toward a cap', () {
      expect(GrowthContent.vineGeometry(75, null).growth01, closeTo(0.5, 0.001));
      expect(GrowthContent.vineGeometry(150, null).growth01, 1.0);
      expect(GrowthContent.vineGeometry(400, null).growth01, 1.0);
    });

    test('growth never exceeds one', () {
      expect(GrowthContent.vineGeometry(500, 90).growth01, 1.0);
    });
  });

  group('season story', () {
    test('every movement has a title, prose, and verse in both languages', () {
      for (final m in JourneyMovement.values) {
        expect(GrowthContent.movementTitle(m).en, isNotEmpty);
        expect(GrowthContent.movementTitle(m).am, isNotEmpty);
        expect(GrowthContent.movementProse(m).en.length, greaterThan(40));
        expect(GrowthContent.movementProse(m).am.length, greaterThan(20));
        expect(GrowthContent.movementVerse(m), isNotEmpty);
      }
    });

    test('verse references align with the four movements', () {
      expect(GrowthContent.movementVerse(JourneyMovement.planting), 'John 15:2');
      expect(GrowthContent.movementVerse(JourneyMovement.rooting), '2 Peter 1:5');
      expect(GrowthContent.movementVerse(JourneyMovement.growing), 'John 14:15');
      expect(GrowthContent.movementVerse(JourneyMovement.fruiting), 'John 15:16');
    });
  });

  group('stage lines and grace note', () {
    test('every stage has a bilingual line', () {
      for (final s in VineStage.values) {
        final l = GrowthContent.vineStageLine(s);
        expect(l.en, isNotEmpty);
        expect(l.am, isNotEmpty);
      }
    });

    test('grace note and horizon are present', () {
      expect(GrowthContent.graceNote().en, contains('God'));
      expect(GrowthContent.horizonLine().am, isNotEmpty);
    });
  });

  group('encouragement', () {
    test('pools are weather-aware', () {
      expect(GrowthContent.encouragementPool(1), isNotEmpty);
      expect(GrowthContent.encouragementPool(2), GrowthContent.encouragementPool(1), reason: 'storm pool shared');
      expect(GrowthContent.encouragementPool(3), isNotEmpty);
      expect(GrowthContent.encouragementPool(null), GrowthContent.encouragementPool(3), reason: 'neutral defaults to cloudy');
      expect(GrowthContent.encouragementPool(4), isNotEmpty);
      expect(GrowthContent.encouragementPool(5), GrowthContent.encouragementPool(4), reason: 'clear pool shared');
      expect(GrowthContent.encouragementPool(1).first.en, isNot(GrowthContent.encouragementPool(4).first.en));
    });

    test('deterministic for a given day and mood', () {
      expect(GrowthContent.encouragementFor(1, 4).en, GrowthContent.encouragementFor(1, 4).en);
      expect(GrowthContent.encouragementFor(1, 1).en, isNot(GrowthContent.encouragementFor(1, 4).en));
    });

    test('always includes a scripture reference', () {
      expect(GrowthContent.encouragementFor(2, null).en, contains('—'));
    });
  });

  group('weather glyph', () {
    test('maps all five moods', () {
      final five = [1, 2, 3, 4, 5].map(GrowthContent.weatherGlyph).toList();
      final glyphs = five.map((g) => g.glyph).toSet();
      expect(glyphs.length, 5, reason: 'each mood has a distinct glyph');
      for (final g in five) {
        expect(g.labelEn, isNotEmpty);
        expect(g.labelAm, isNotEmpty);
      }
    });

    test('clamps out-of-range moods', () {
      expect(GrowthContent.weatherGlyph(0).glyph, GrowthContent.weatherGlyph(1).glyph);
      expect(GrowthContent.weatherGlyph(9).glyph, GrowthContent.weatherGlyph(5).glyph);
    });
  });

  group('atmosphere', () {
    test('storm weather forces rain particles regardless of light', () {
      final a = GrowthContent.atmosphereFor(1, LampLight.noon);
      expect(a.particle, VineParticle.rain);
      final b = GrowthContent.atmosphereFor(2, LampLight.night);
      expect(b.particle, VineParticle.rain);
    });

    test('light drives the clear-weather particles', () {
      expect(GrowthContent.atmosphereFor(5, LampLight.dawn).particle, VineParticle.dust);
      expect(GrowthContent.atmosphereFor(5, LampLight.noon).particle, VineParticle.clear);
      expect(GrowthContent.atmosphereFor(null, LampLight.dusk).particle, VineParticle.dust);
      expect(GrowthContent.atmosphereFor(4, LampLight.night).particle, VineParticle.fireflies);
    });

    test('storm overrides the sky palette', () {
      final storm = GrowthContent.atmosphereFor(1, LampLight.dawn);
      final calm = GrowthContent.atmosphereFor(5, LampLight.dawn);
      expect(storm.skyTop, isNot(calm.skyTop));
    });
  });

  group('harvest letter', () {
    test('empty journey receives a gentle message', () {
      final en = GrowthContent.harvestLetter([], JourneyMovement.planting, isAm: false);
      final am = GrowthContent.harvestLetter([], JourneyMovement.planting, isAm: true);
      expect(en, contains('still yours'));
      expect(am, isNotEmpty);
    });

    test('single answer is quoted once and counted', () {
      final en = GrowthContent.harvestLetter(['I prayed'], JourneyMovement.rooting, isAm: false);
      expect(en, contains('answered 1 times'));
      expect(en, contains('"I prayed"'));
      expect(en, contains('Galatians 6:9'));
    });

    test('multiple answers are woven together', () {
      final en = GrowthContent.harvestLetter(['First', 'Second'], JourneyMovement.fruiting, isAm: false);
      expect(en, contains('"First"'));
      expect(en, contains('"Second"'));
      expect(en, contains('Philippians 1:6'));
    });

    test('Amharic letter uses the Amharic movement title', () {
      final am = GrowthContent.harvestLetter(['ሰገድኩ'], JourneyMovement.planting, isAm: true);
      expect(am, contains('መትከል'));
    });
  });
}
