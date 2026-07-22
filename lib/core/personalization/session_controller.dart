import 'package:flutter/material.dart';
import '../theme/app_durations.dart';
import '../theme/app_motion.dart';
import '../theme/screen_rhythm.dart';
import 'personalization_engine.dart';

class SessionController {
  final PersonalizationEngine _engine;

  SessionController(this._engine);

  PersonalizationEngine get engine => _engine;

  /// Scale factor for transition durations (±0–20% depending on session state)
  double get _paceScale {
    if (_engine.isFirstSessionToday && _engine.wasAwayForDays) return 1.2;
    if (_engine.isFirstSessionToday) return 1.15;
    if (_engine.sessionsToday >= 10) return 0.75;
    if (_engine.sessionsToday >= 5) return 0.85;
    return 1.0;
  }

  /// How prominent animations feel: 0.0 (muted) → 1.0 (full)
  double get emphasisLevel {
    double base = 0.8;
    if (_engine.isFirstSessionToday && _engine.wasAwayForDays) base += 0.15;
    if (_engine.isFirstSessionToday) base += 0.1;
    if (_engine.sessionsToday >= 10) base -= 0.2;
    if (_engine.sessionsToday >= 5) base -= 0.1;
    return base.clamp(0.0, 1.0);
  }

  /// Whether to skip non-essential animations (fatigue reduction)
  bool get shouldAnimate => _engine.sessionsToday < 10;

  Duration transition([Duration? base]) {
    final d = base ?? AppDurations.normal;
    return Duration(milliseconds: (d.inMilliseconds * _paceScale).round());
  }

  Duration delayShort() => transition(AppDurations.fast);
  Duration delayLong() => transition(AppDurations.slow);

  Duration staggerFrom(ScreenRhythm rhythm) {
    final d = rhythm.stagger;
    return Duration(milliseconds: (d.inMilliseconds * _paceScale).round());
  }

  Duration baseFrom(ScreenRhythm rhythm) {
    final d = rhythm.base;
    return Duration(milliseconds: (d.inMilliseconds * _paceScale).round());
  }

  Curve get entryCurve => AppMotion.entry;
  Curve get exitCurve => AppMotion.exit;
  Curve get emphasisCurve => AppMotion.emphasis;
  Curve get gentleCurve => AppMotion.gentle;

  ScreenRhythm rhythmFor(ScreenRhythm profile) {
    final base = Duration(milliseconds: (profile.base.inMilliseconds * _paceScale).round());
    final stagger = Duration(milliseconds: (profile.stagger.inMilliseconds * _paceScale).round());
    final delay = Duration(milliseconds: (profile.delay.inMilliseconds * _paceScale).round());
    return ScreenRhythm(base: base, stagger: stagger, delay: delay, emphasis: profile.emphasis);
  }
}
