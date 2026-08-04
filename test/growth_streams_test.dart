import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/services/growth_streams.dart';
import 'package:beslet_app/core/services/scene_event_bus.dart';

void main() {
  group('GrowthVitality', () {
    test('prayer waters the vine to full hydration', () {
      final v = GrowthVitality.compute(
        prayed: true,
        read: false,
        connected: false,
        habitsDone: 0,
        bestStreak: 0,
      );
      expect(v.hydration01, 1.0);
      expect(v.leafGlow01, GrowthVitality.graceFloor);
      expect(v.branchOpen01, GrowthVitality.graceFloor);
    });

    test('a quiet day rests at the grace floor, never zero', () {
      final v = GrowthVitality.compute(
        prayed: false,
        read: false,
        connected: false,
        habitsDone: 0,
        bestStreak: 0,
      );
      expect(v.hydration01, GrowthVitality.graceFloor);
      expect(v.leafGlow01, GrowthVitality.graceFloor);
      expect(v.branchOpen01, GrowthVitality.graceFloor);
      expect(v.ripen01, 0.0);
    });

    test('the Word lights the leaves, fellowship opens the branches', () {
      final v = GrowthVitality.compute(
        prayed: false,
        read: true,
        connected: true,
        habitsDone: 0,
        bestStreak: 0,
      );
      expect(v.leafGlow01, 1.0);
      expect(v.branchOpen01, 1.0);
    });

    test('consistency ripens the fruit toward a full harvest', () {
      final quiet = GrowthVitality.compute(
        prayed: false, read: false, connected: false, habitsDone: 0, bestStreak: 0,
      );
      final full = GrowthVitality.compute(
        prayed: true, read: true, connected: true, habitsDone: 3, bestStreak: 30,
      );
      expect(full.ripen01, greaterThan(quiet.ripen01));
      expect(full.ripen01, lessThanOrEqualTo(1.0));
    });

    test('ripen never exceeds 1.0', () {
      final v = GrowthVitality.compute(
        prayed: true, read: true, connected: true, habitsDone: 5, bestStreak: 100,
      );
      expect(v.ripen01, lessThanOrEqualTo(1.0));
    });

    test('quiet is the constant grace-floor state', () {
      expect(GrowthVitality.quiet.hydration01, GrowthVitality.graceFloor);
      expect(GrowthVitality.quiet.leafGlow01, GrowthVitality.graceFloor);
      expect(GrowthVitality.quiet.branchOpen01, GrowthVitality.graceFloor);
    });
  });

  group('SceneEventBus', () {
    test('emits events with monotonically increasing ids', () {
      final bus = SceneEventBus();
      expect(bus.value, isNull);
      bus.emit(SceneEventType.water);
      expect(bus.value?.type, SceneEventType.water);
      expect(bus.value?.id, 1);
      bus.emit(SceneEventType.fruitPop);
      expect(bus.value?.type, SceneEventType.fruitPop);
      expect(bus.value?.id, 2);
      bus.dispose();
    });

    test('notifies listeners on emit', () {
      final bus = SceneEventBus();
      SceneEvent? seen;
      bus.addListener(() => seen = bus.value);
      bus.emit(SceneEventType.bloom);
      expect(seen?.type, SceneEventType.bloom);
      bus.dispose();
    });
  });
}
