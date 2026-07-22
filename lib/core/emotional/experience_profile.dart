import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppSeason {
  seedling,
  rooting,
  flourishing,
  established,
  rooted;

  static AppSeason fromStreak(int streak) {
    if (streak >= 90) return AppSeason.rooted;
    if (streak >= 30) return AppSeason.established;
    if (streak >= 14) return AppSeason.flourishing;
    if (streak >= 7) return AppSeason.rooting;
    return AppSeason.seedling;
  }
}

enum DayState {
  newDay,
  inProgress,
  completed,
  missed,
  returning;

  static DayState detect({
    required bool isFirstSessionToday,
    required bool allStepsComplete,
    required bool missedYesterday,
    required bool wasAwayForDays,
  }) {
    if (wasAwayForDays && isFirstSessionToday) return DayState.returning;
    if (missedYesterday) return DayState.missed;
    if (allStepsComplete) return DayState.completed;
    if (isFirstSessionToday) return DayState.newDay;
    return DayState.inProgress;
  }
}

class SeasonColors {
  final Color greeting;
  final Color accent;
  final Color streakRing;
  final Color stepActive;
  final Color stepComplete;

  const SeasonColors({
    required this.greeting,
    required this.accent,
    required this.streakRing,
    required this.stepActive,
    required this.stepComplete,
  });
}

class ExperienceProfile {
  final Duration animationDuration;
  final Curve animationCurve;
  final SeasonColors colors;
  final double spacingScale;
  final String greetingStyle;
  final FontWeight visualWeight;
  final bool showStreakRing;
  final bool showStepAsHero;

  const ExperienceProfile({
    required this.animationDuration,
    required this.animationCurve,
    required this.colors,
    required this.spacingScale,
    required this.greetingStyle,
    required this.visualWeight,
    required this.showStreakRing,
    required this.showStepAsHero,
  });
}

ExperienceProfile getProfile(AppSeason season, DayState state, ThemePalette palette) {
  Duration duration;
  Curve curve;

  switch (season) {
    case AppSeason.seedling:
      duration = const Duration(milliseconds: 450);
      curve = Curves.easeOutCubic;
    case AppSeason.rooting:
      duration = const Duration(milliseconds: 380);
      curve = Curves.easeOutCubic;
    case AppSeason.flourishing:
      duration = const Duration(milliseconds: 280);
      curve = Curves.easeOutQuart;
    case AppSeason.established:
      duration = const Duration(milliseconds: 350);
      curve = Curves.easeInOut;
    case AppSeason.rooted:
      duration = const Duration(milliseconds: 500);
      curve = Curves.easeInOut;
  }

  if (state == DayState.completed) {
    duration = Duration(milliseconds: (duration.inMilliseconds * 1.4).round().clamp(400, 700));
    curve = Curves.easeInOut;
  } else if (state == DayState.returning) {
    duration = Duration(milliseconds: (duration.inMilliseconds * 1.3).round().clamp(350, 650));
    curve = Curves.easeOutCubic;
  } else if (state == DayState.missed) {
    duration = Duration(milliseconds: (duration.inMilliseconds * 1.1).round());
  }

  SeasonColors colors;

  switch (season) {
    case AppSeason.seedling:
      colors = SeasonColors(
        greeting: palette.primary.withValues(alpha: 0.9),
        accent: palette.primary,
        streakRing: palette.primary,
        stepActive: palette.primary,
        stepComplete: palette.success,
      );
    case AppSeason.rooting:
      colors = SeasonColors(
        greeting: palette.primaryLight,
        accent: palette.primaryLight,
        streakRing: palette.progressGreen.withValues(alpha: 0.8),
        stepActive: palette.primaryLight,
        stepComplete: palette.success,
      );
    case AppSeason.flourishing:
      colors = SeasonColors(
        greeting: palette.textPrimary,
        accent: palette.primary,
        streakRing: palette.primary,
        stepActive: palette.primary,
        stepComplete: palette.progressGreen,
      );
    case AppSeason.established:
      colors = SeasonColors(
        greeting: palette.textPrimary,
        accent: palette.primaryDark,
        streakRing: palette.primaryDark,
        stepActive: palette.primaryDark,
        stepComplete: palette.progressGreen,
      );
    case AppSeason.rooted:
      colors = SeasonColors(
        greeting: palette.textSecondary,
        accent: palette.textMuted,
        streakRing: palette.textMuted,
        stepActive: palette.primaryDark,
        stepComplete: palette.success,
      );
  }

  if (state == DayState.missed) {
    colors = SeasonColors(
      greeting: palette.warningOrange,
      accent: palette.warningOrange.withValues(alpha: 0.7),
      streakRing: palette.warningOrange.withValues(alpha: 0.6),
      stepActive: colors.stepActive,
      stepComplete: colors.stepComplete,
    );
  } else if (state == DayState.completed) {
    colors = SeasonColors(
      greeting: palette.success,
      accent: palette.success,
      streakRing: palette.progressGreen,
      stepActive: colors.stepActive,
      stepComplete: palette.success,
    );
  } else if (state == DayState.returning) {
    colors = SeasonColors(
      greeting: palette.primary.withValues(alpha: 0.9),
      accent: palette.primary,
      streakRing: palette.primary,
      stepActive: palette.primary,
      stepComplete: colors.stepComplete,
    );
  }

  double spacingScale;

  switch (season) {
    case AppSeason.seedling:
      spacingScale = 1.2;
    case AppSeason.rooting:
      spacingScale = 1.1;
    case AppSeason.flourishing:
      spacingScale = 1.0;
    case AppSeason.established:
      spacingScale = 0.9;
    case AppSeason.rooted:
      spacingScale = 0.85;
  }

  String greetingStyle;
  FontWeight visualWeight;

  switch (season) {
    case AppSeason.seedling:
      greetingStyle = 'full';
      visualWeight = FontWeight.w600;
    case AppSeason.rooting:
      greetingStyle = 'short';
      visualWeight = FontWeight.w500;
    case AppSeason.flourishing:
      greetingStyle = 'short';
      visualWeight = FontWeight.w500;
    case AppSeason.established:
      greetingStyle = 'minimal';
      visualWeight = FontWeight.w400;
    case AppSeason.rooted:
      greetingStyle = 'nameOnly';
      visualWeight = FontWeight.w300;
  }

  final showStreakRing = season != AppSeason.seedling;
  final showStepAsHero = state != DayState.completed;

  return ExperienceProfile(
    animationDuration: duration,
    animationCurve: curve,
    colors: colors,
    spacingScale: spacingScale,
    greetingStyle: greetingStyle,
    visualWeight: visualWeight,
    showStreakRing: showStreakRing,
    showStepAsHero: showStepAsHero,
  );
}
