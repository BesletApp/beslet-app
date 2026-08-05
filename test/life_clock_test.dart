import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/features/growth/widgets/life_clock.dart';

void main() {
  group('VineSpring', () {
    test('an impulse moves the vine and it settles back', () {
      final spring = VineSpring();
      spring.impulse(50);
      // Step the physics over ~3 simulated seconds.
      var maxDisplacement = 0.0;
      for (var i = 0; i < 180; i++) {
        spring.update(1 / 60);
        if (spring.value.abs() > maxDisplacement) {
          maxDisplacement = spring.value.abs();
        }
      }
      expect(maxDisplacement, greaterThan(0.5));
      expect(maxDisplacement, lessThan(30)); // bounded, no explosion
      expect(spring.settled, isTrue);
      expect(spring.value.abs(), lessThan(0.05));
    });

    test('at rest it stays perfectly still', () {
      final spring = VineSpring();
      for (var i = 0; i < 120; i++) {
        spring.update(1 / 60);
      }
      expect(spring.settled, isTrue);
      expect(spring.value, 0);
    });

    test('a gentle impulse settles sooner than a strong one', () {
      final gentle = VineSpring();
      final strong = VineSpring();
      gentle.impulse(12);
      strong.impulse(120);
      var gentleSettledAt = 0;
      var strongSettledAt = 0;
      for (var i = 1; i <= 240; i++) {
        gentle.update(1 / 60);
        strong.update(1 / 60);
        if (gentleSettledAt == 0 && gentle.settled) gentleSettledAt = i;
        if (strongSettledAt == 0 && strong.settled) strongSettledAt = i;
      }
      expect(gentleSettledAt, greaterThan(0));
      expect(gentleSettledAt, lessThan(strongSettledAt));
    });

    test('it wobbles (under-damped): the vine overshoots then comes back', () {
      final spring = VineSpring();
      spring.impulse(80);
      var firstPass = false;
      var secondPass = false;
      double? previous;
      for (var i = 0; i < 200; i++) {
        spring.update(1 / 60);
        final x = spring.value;
        if (previous != null) {
          if (previous > 0.5 && x < 0.5) firstPass = true;
          if (firstPass && previous > 0.5 && x < 0.5) secondPass = true;
        }
        previous = x;
      }
      expect(secondPass, isTrue, reason: 'a living vine should wobble, not spring back instantly');
    });

    test('update never diverges even with a pathological frame time', () {
      final spring = VineSpring();
      spring.impulse(200);
      spring.update(5); // a huge, unrealistic dt
      expect(spring.value.abs(), lessThanOrEqualTo(80));
    });
  });
}
