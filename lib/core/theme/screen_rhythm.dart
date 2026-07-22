import 'app_durations.dart';

class ScreenRhythm {
  final Duration base;
  final Duration stagger;
  final Duration delay;
  final double emphasis;

  const ScreenRhythm({
    required this.base,
    required this.stagger,
    required this.delay,
    this.emphasis = 0.8,
  });

  static const home = ScreenRhythm(
    base: AppDurations.normal,
    stagger: Duration(milliseconds: 150),
    delay: Duration(milliseconds: 200),
    emphasis: 0.8,
  );

  static const reflection = ScreenRhythm(
    base: AppDurations.slow,
    stagger: Duration.zero,
    delay: Duration(milliseconds: 400),
    emphasis: 1.0,
  );

  static const stats = ScreenRhythm(
    base: Duration(milliseconds: 300),
    stagger: Duration(milliseconds: 100),
    delay: Duration(milliseconds: 100),
    emphasis: 0.6,
  );

  static const prayer = ScreenRhythm(
    base: AppDurations.slow,
    stagger: Duration(milliseconds: 200),
    delay: Duration(milliseconds: 300),
    emphasis: 0.9,
  );

  static const bible = ScreenRhythm(
    base: AppDurations.normal,
    stagger: Duration(milliseconds: 100),
    delay: Duration(milliseconds: 100),
    emphasis: 0.7,
  );

  static const settings = ScreenRhythm(
    base: AppDurations.fast,
    stagger: Duration.zero,
    delay: Duration.zero,
    emphasis: 0.5,
  );

  static const splash = ScreenRhythm(
    base: AppDurations.slow,
    stagger: Duration(milliseconds: 200),
    delay: Duration.zero,
    emphasis: 1.0,
  );
}
