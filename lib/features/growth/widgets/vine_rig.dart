import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'vine_painter.dart' show VineGeometry, VineSegment;

/// An articulated bone rig for the vine. Every branch segment becomes a joint
/// carrying its own angular spring; a layered, seeded wind field sways the
/// canopy in a natural cascade (tips lag and overshoot), and a discipline or
/// tap impulse travels up from the trunk as a soft wave. Deterministic for a
/// given [seed], fully offline.
///
/// The rig is the vine's "skeleton": it answers one question — *where does
/// every joint and leaf tip stand this frame?* — and any renderer (the movie
/// painter, or a Rive / three_dart renderer later) draws that answer. Rest
/// pose (angles all zero) reproduces the input geometry exactly.
class VineRig {
  VineRig._({
    required this._joints,
    required this._tips,
    required this._soil,
    required this._seed,
    required this._maxDepth,
    required this._size,
    required this._rest,
  });

  final List<_RigJoint> _joints;
  final List<int> _tips;
  final Offset _soil;
  final int _seed;
  final int _maxDepth;
  final Size _size;
  final VineGeometry _rest;

  /// Master strength of the ambient wind (0 disables it — used in tests and
  /// when the user's system requests reduced motion).
  double windScale = 1;

  /// When true the rig holds its rest pose (reduced-motion mode).
  bool reduced = false;

  double _t = 0;
  double _kickMag = 0;
  double _kickT = -1e9;
  double _dragTarget = 0;
  double _dragPx = 0;

  /// Builds a rig from the deterministic rest geometry. Segment i's parent is
  /// the segment whose end point equals its start point (exact geometry), so
  /// the tree is reconstructed without changing how vines are grown.
  factory VineRig.fromGeometry(VineGeometry geometry, {required int seed, required Size size}) {
    final segments = geometry.segments;
    final n = segments.length;
    final parent = List<int>.filled(n, -1);
    for (var i = 0; i < n; i++) {
      final from = segments[i].from;
      for (var j = 0; j < i; j++) {
        if (segments[j].to == from) {
          parent[i] = j;
          break;
        }
      }
    }

    var maxDepth = 0;
    for (final s in segments) {
      if (s.depth > maxDepth) maxDepth = s.depth;
    }

    final joints = <_RigJoint>[];
    for (var i = 0; i < n; i++) {
      final s = segments[i];
      final dir = s.to - s.from;
      final len = dir.distance;
      final restAngle = math.atan2(dir.dy, dir.dx);
      final depth01 = maxDepth == 0 ? 0.0 : s.depth / maxDepth;
      // Trunk is stiff; tips are light so they lag and overshoot.
      final stiffness = 46.0 + (1 - depth01) * 34.0;
      final zeta = 0.62 + (1 - depth01) * 0.30;
      final damping = 2 * math.sqrt(stiffness) * zeta;
      joints.add(_RigJoint(
        parent: parent[i],
        restAngle: restAngle,
        length: len,
        width: s.width,
        depth: s.depth,
        stiffness: stiffness,
        damping: damping,
        phase: _phaseFor(i, seed),
      ));
    }

    // Leaf tips hang on the segments whose end matches a rest tip (exact).
    final tips = <int>[];
    for (final tip in geometry.tips) {
      for (var i = 0; i < n; i++) {
        if (segments[i].to == tip) {
          tips.add(i);
          break;
        }
      }
    }

    final soil = n == 0 ? Offset(size.width / 2, size.height * 0.9) : segments[0].from;
    return VineRig._(
      joints: joints,
      tips: tips,
      soil: soil,
      seed: seed,
      maxDepth: maxDepth,
      size: size,
      rest: geometry,
    );
  }

  static double _phaseFor(int i, int seed) {
    final rng = math.Random(seed + i * 7919);
    return rng.nextDouble() * math.pi * 2;
  }

  /// A poke: a discipline logged, a tap, a drag release. The impulse is applied
  /// with a per-depth delay so it visibly travels from trunk to tips.
  void impulse(double magnitude) {
    if (reduced) return;
    _kickMag = magnitude;
    _kickT = _t;
  }

  /// Horizontal finger drag, in pixels from the drag start. Positive leans the
  /// vine to the right.
  void drag(double dxPx) {
    if (reduced) return;
    _dragTarget = dxPx.clamp(-_size.width * 0.45, _size.width * 0.45);
  }

  /// Release the finger: the vine springs back toward stillness.
  void releaseDrag() {
    _dragTarget = 0;
  }

  /// Advance the physics by [dt] seconds.
  void update(double dt) {
    if (reduced) return;
    if (dt <= 0) return;
    dt = dt.clamp(0.0, 0.05);
    _t += dt;

    // Drag eases toward its target; releasing springs it back.
    final dragEase = 1 - math.exp(-dt * 8);
    _dragPx += (_dragTarget - _dragPx) * dragEase;

    for (final j in _joints) {
      final depth01 = _maxDepth == 0 ? 0.0 : j.depth / _maxDepth;
      final target = _windTarget(j, depth01) +
          _impulseTarget(j, depth01) +
          _dragContribution(depth01);
      j.omega += (j.stiffness * (target - j.angle) - j.damping * j.omega) * dt;
      j.angle += j.omega * dt;
      const maxBend = 0.55;
      if (j.angle > maxBend) {
        j.angle = maxBend;
        j.omega *= 0.4;
      } else if (j.angle < -maxBend) {
        j.angle = -maxBend;
        j.omega *= 0.4;
      }
    }
  }

  double _windTarget(_RigJoint j, double depth01) {
    if (windScale <= 0) return 0;
    // Slow gust envelope so the wind breathes, not hums.
    final gust = 0.5 + 0.5 * math.sin(_t * 0.42 + _seed * 0.13);
    final amp = (0.015 + depth01 * 0.10) * windScale;
    return gust *
        amp *
        (0.6 * math.sin(_t * 1.35 + j.phase) +
            0.3 * math.sin(_t * 2.3 + j.phase * 1.7) +
            0.1 * math.sin(_t * 0.7 + j.phase * 0.6));
  }

  double _impulseTarget(_RigJoint j, double depth01) {
    if (_kickMag <= 0) return 0;
    final elapsed = _t - _kickT - j.depth * 0.055;
    if (elapsed < 0 || elapsed > 1.4) return 0;
    final decay = math.exp(-elapsed * 4.0);
    final wave = math.sin(elapsed * 8.5);
    // The trunk leads; the tips trail the wave.
    return _kickMag * 0.012 * decay * wave * (0.5 + depth01 * 0.9);
  }

  double _dragContribution(double depth01) {
    if (_dragPx.abs() < 0.5) return 0;
    return (_dragPx / _size.width) * (0.16 + depth01 * 0.35);
  }

  /// Forward kinematics: world positions for every joint, then a posed
  /// [VineGeometry] the painter can draw directly.
  VineGeometry solve() {
    if (reduced) return _rest;
    final pos = List<Offset>.filled(_joints.length, Offset.zero);
    for (var i = 0; i < _joints.length; i++) {
      final j = _joints[i];
      final base = j.parent < 0 ? _soil : pos[j.parent];
      final ang = j.restAngle + j.angle;
      pos[i] = base + Offset(math.cos(ang), math.sin(ang)) * j.length;
    }
    final segments = <VineSegment>[];
    for (var i = 0; i < _joints.length; i++) {
      final j = _joints[i];
      final base = j.parent < 0 ? _soil : pos[j.parent];
      segments.add(VineSegment(
        from: base,
        to: pos[i],
        width: j.width,
        depth: j.depth,
      ));
    }
    final tips = <Offset>[for (final i in _tips) pos[i]];
    return VineGeometry(segments: segments, tips: tips);
  }

  /// The posed leaf-tip positions for this frame (used by the fruit tap layer
  /// so taps stay glued to moving fruit).
  List<Offset> get tipPositions => solve().tips;
}

class _RigJoint {
  _RigJoint({
    required this.parent,
    required this.restAngle,
    required this.length,
    required this.width,
    required this.depth,
    required this.stiffness,
    required this.damping,
    required this.phase,
  });

  final int parent;
  final double restAngle;
  final double length;
  final double width;
  final int depth;
  final double stiffness;
  final double damping;
  final double phase;

  double angle = 0;
  double omega = 0;
}
