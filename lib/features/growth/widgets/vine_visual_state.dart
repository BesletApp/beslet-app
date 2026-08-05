import 'dart:ui' show Color;

import 'vine_painter.dart' show VineGeometry, VinePalette;

/// An immutable snapshot of everything the vine's renderer needs for one frame.
///
/// The Growth Zone scene computes it each frame from the journey's lifecycle
/// plus the [VineRig]'s posed geometry, and *any* renderer — the movie painter
/// today, or a Rive / three_dart renderer later — consumes the exact same
/// object. The vine's "brain" never depends on how it is drawn, which is the
/// seam that keeps the renderer swappable.
class VineVisualState {
  final int seed;
  final double growth01;
  final int branches;
  final int fruitCount;
  final Color fruitColor;
  final VinePalette palette;
  final bool showBlossoms;
  final double hydration;
  final double leafGlow;
  final double branchOpen;
  final double ripen;
  final double droop;
  final double blossomOpen;
  final double lifeT;
  final double flutterAmt;
  final double dew;
  final double wilt;
  final double fullness;

  /// Atmospheric haze color toward which the back canopy recedes (usually the
  /// sky's horizon tone). Transparent disables the depth cue.
  final Color haze;

  /// The posed geometry for this frame (rest, or driven by the rig). When
  /// null the renderer falls back to building the deterministic rest vine.
  final VineGeometry? geometry;

  const VineVisualState({
    required this.seed,
    required this.growth01,
    required this.branches,
    required this.fruitCount,
    required this.fruitColor,
    required this.palette,
    this.showBlossoms = false,
    this.hydration = 1,
    this.leafGlow = 1,
    this.branchOpen = 1,
    this.ripen = 0,
    this.droop = 0,
    this.blossomOpen = 1,
    this.lifeT = 0,
    this.flutterAmt = 1,
    this.dew = 0,
    this.wilt = 0,
    this.fullness = 1,
    this.haze = const Color(0x00000000),
    this.geometry,
  });

  VineVisualState copyWith({VineGeometry? geometry}) {
    return VineVisualState(
      seed: seed,
      growth01: growth01,
      branches: branches,
      fruitCount: fruitCount,
      fruitColor: fruitColor,
      palette: palette,
      showBlossoms: showBlossoms,
      hydration: hydration,
      leafGlow: leafGlow,
      branchOpen: branchOpen,
      ripen: ripen,
      droop: droop,
      blossomOpen: blossomOpen,
      lifeT: lifeT,
      flutterAmt: flutterAmt,
      dew: dew,
      wilt: wilt,
      fullness: fullness,
      haze: haze,
      geometry: geometry ?? this.geometry,
    );
  }
}
