import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

/// A single monotonic clock driving the garden's ambient life. Every painter —
/// clouds, grass, fluttering leaves, the breathing lamp, the spring — reads
/// the same timebase so the whole scene breathes together.
class LifeClock {
  LifeClock({required TickerProvider vsync, void Function(double dt)? onTick}) {
    _ticker = vsync.createTicker(_tick);
    _onTick = onTick;
  }

  late final Ticker _ticker;
  void Function(double dt)? _onTick;
  double _t = 0;
  Duration? _lastElapsed;

  /// Seconds since the clock started ticking.
  double get t => _t;

  bool get isActive => _ticker.isActive;

  /// A gentle continuous sway, period ~7s.
  double swayPhase() => math.sin(_t * 2 * math.pi / 7);

  /// A slow, deep breath (0..1) for the lamp's glow.
  double breath({double speed = 1, double phase = 0}) =>
      (math.sin(_t * speed * 2 * math.pi / 9 + phase) + 1) / 2;

  /// Per-leaf flutter: deterministic micro-motion from a per-leaf phase.
  double flutter(double phase) => math.sin(_t * 6.0 + phase * 2 * math.pi);

  void start() {
    if (_ticker.isActive) return;
    _lastElapsed = null;
    _ticker.start();
  }

  void stop() => _ticker.stop();

  void _tick(Duration elapsed) {
    final last = _lastElapsed;
    _lastElapsed = elapsed;
    var dt = 0.0;
    if (last != null) {
      dt = (elapsed - last).inMicroseconds / 1e6;
      _t += dt;
    }
    _onTick?.call(dt);
  }

  void dispose() => _ticker.dispose();
}

/// A damped spring-mass oscillator for the vine's physical gestures. Impulses
/// from disciplines and taps decay with a natural wobble (under-damped), so
/// the vine feels alive and then settles back into stillness.
class VineSpring {
  VineSpring({this.stiffness = 60, this.damping = 9});

  final double stiffness;
  final double damping;

  double x = 0;
  double v = 0;

  double get value => x;

  bool get settled => x.abs() < 0.01 && v.abs() < 0.01;

  /// A tap or a logged discipline nudges the vine's velocity.
  void impulse(double force) => v += force;

  void update(double dt) {
    if (dt <= 0) return;
    dt = dt > 0.1 ? 0.1 : dt; // clamp spikes after the app is backgrounded
    final acceleration = -stiffness * x - damping * v;
    v += acceleration * dt;
    x += v * dt;
    if (x.abs() > 80) {
      x = x < 0 ? -80 : 80;
      v = 0;
    }
  }
}
