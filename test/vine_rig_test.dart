import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:beslet_app/features/growth/widgets/vine_painter.dart';
import 'package:beslet_app/features/growth/widgets/vine_rig.dart';

void main() {
  VineGeometry makeGeometry({int seed = 42, int branches = 8, double growth = 1}) {
    return buildVine(
      seed: seed,
      growth01: growth,
      branches: branches,
      size: const Size(360, 440),
      fullness: 1,
    );
  }

  test('rest pose reproduces the input geometry exactly', () {
    final geometry = makeGeometry();
    final rig = VineRig.fromGeometry(geometry, seed: 42, size: const Size(360, 440));
    final posed = rig.solve();
    expect(posed.segments.length, geometry.segments.length);
    expect(posed.tips.length, geometry.tips.length);
    for (var i = 0; i < geometry.tips.length; i++) {
      final d = (posed.tips[i] - geometry.tips[i]).distance;
      expect(d, lessThan(1e-9));
    }
  });

  test('same seed produces identical motion (deterministic)', () {
    final a = VineRig.fromGeometry(makeGeometry(), seed: 7, size: const Size(360, 440));
    final b = VineRig.fromGeometry(makeGeometry(), seed: 7, size: const Size(360, 440));
    for (var i = 0; i < 90; i++) {
      a.update(1 / 30);
      b.update(1 / 30);
    }
    a.impulse(140);
    b.impulse(140);
    for (var i = 0; i < 30; i++) {
      a.update(1 / 30);
      b.update(1 / 30);
    }
    final pa = a.solve();
    final pb = b.solve();
    for (var i = 0; i < pa.tips.length; i++) {
      expect((pa.tips[i] - pb.tips[i]).distance, lessThan(1e-9));
    }
  });

  test('different seeds produce different motion', () {
    final a = VineRig.fromGeometry(makeGeometry(seed: 7), seed: 7, size: const Size(360, 440));
    final b = VineRig.fromGeometry(makeGeometry(seed: 8), seed: 8, size: const Size(360, 440));
    for (var i = 0; i < 120; i++) {
      a.update(1 / 30);
      b.update(1 / 30);
    }
    final pa = a.solve();
    final pb = b.solve();
    var moved = 0;
    for (var i = 0; i < pa.tips.length; i++) {
      if ((pa.tips[i] - pb.tips[i]).distance > 0.5) moved++;
    }
    expect(moved, greaterThan(0));
  });

  test('impulse is damped: oscillation decays over time', () {
    final rig = VineRig.fromGeometry(makeGeometry(), seed: 3, size: const Size(360, 440));
    rig.windScale = 0; // isolate the impulse response
    rig.update(1 / 30);

    // Measure peak tip deviation in two windows after a poke.
    double peakDeviation(int startFrame, int endFrame) {
      var peak = 0.0;
      for (var i = startFrame; i < endFrame; i++) {
        rig.update(1 / 30);
        final posed = rig.solve();
        for (final t in posed.tips) {
          final d = (t - posed.segments.first.from).distance;
          if (d > peak) peak = d;
        }
      }
      return peak;
    }

    rig.impulse(140);
    final early = peakDeviation(0, 24);
    final late = peakDeviation(24, 90);
    // The tips should swing less once the wave has settled.
    expect(early, greaterThan(late * 0.6));
  });

  test('tips stay inside the canvas for a long wind run', () {
    final rig = VineRig.fromGeometry(makeGeometry(), seed: 11, size: const Size(360, 440));
    final size = const Size(360, 440);
    for (var i = 0; i < 600; i++) {
      rig.update(1 / 30);
      final posed = rig.solve();
      for (final t in posed.tips) {
        expect(t.dx, greaterThan(-60));
        expect(t.dx, lessThan(size.width + 60));
        expect(t.dy, greaterThan(-60));
        expect(t.dy, lessThan(size.height + 60));
      }
      if (i == 300) rig.impulse(160);
    }
  });

  test('fruit tap tips track the rig (pose changes tips)', () {
    final geometry = makeGeometry();
    final rig = VineRig.fromGeometry(geometry, seed: 5, size: const Size(360, 440));
    final restTips = geometry.tips;
    for (var i = 0; i < 60; i++) {
      rig.update(1 / 30);
    }
    rig.impulse(150);
    for (var i = 0; i < 12; i++) {
      rig.update(1 / 30);
    }
    final moved = rig.solve().tips;
    expect(moved.length, restTips.length);
    var anyMoved = false;
    for (var i = 0; i < moved.length; i++) {
      if ((moved[i] - restTips[i]).distance > 0.5) anyMoved = true;
    }
    expect(anyMoved, isTrue);
  });
}
