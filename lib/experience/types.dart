import 'package:flutter/material.dart';

enum ExperienceIntent {
  grounding,
  slowing,
  comforting,
  affirming,
  awakening,
  resting,
}

enum VersePhase {
  entering,
  revealing,
  resting,
  inviting,
  receiving,
  blessing,
  complete,
}

enum DayTime {
  dawn,
  morning,
  afternoon,
  evening,
  night,
  deepNight,
}

enum EngagementLevel {
  newUser,
  casual,
  regular,
  faithful,
  devoted,
}

enum InteractionSpeed {
  contemplative,
  moderate,
  quick,
}

enum VisualTone {
  calm,
  warm,
  highContrast,
  candlelight,
}

enum UserMood {
  anxious,
  tired,
  joyful,
  sorrowful,
  peaceful,
  neutral,
}

enum LiturgicalSeason {
  ordinary,
  advent,
  christmas,
  lent,
  easter,
  epiphany,
}

class ThemeConfig {
  final Color backgroundFrom;
  final Color backgroundTo;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final double glowIntensity;
  final double animationSoftness;
  final double ambientOpacity;
  final Color glowColor;
  final Color borderColor;

  const ThemeConfig({
    required this.backgroundFrom,
    required this.backgroundTo,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.glowIntensity,
    required this.animationSoftness,
    required this.ambientOpacity,
    required this.glowColor,
    required this.borderColor,
  });
}

class PhaseAnimationConfig {
  final double durationMs;
  final double delayMs;
  final double stiffness;
  final double damping;

  const PhaseAnimationConfig({
    this.durationMs = 600,
    this.delayMs = 0,
    this.stiffness = 100,
    this.damping = 30,
  });
}

class PhaseConfig {
  final VersePhase phase;
  final int durationMs;
  final bool skipAllowed;
  final int reducedMotionDurationMs;
  final PhaseAnimationConfig animation;
  final String? contentKey;

  const PhaseConfig({
    required this.phase,
    required this.durationMs,
    required this.skipAllowed,
    required this.reducedMotionDurationMs,
    this.animation = const PhaseAnimationConfig(),
    this.contentKey,
  });
}

class ExperienceContext {
  final DayTime timeOfDay;
  final EngagementLevel engagementLevel;
  final InteractionSpeed interactionSpeed;
  final UserMood userMood;
  final LiturgicalSeason liturgicalSeason;
  final VisualTone preferredVisualTone;
  final bool isFirstVisit;
  final bool isReturning;
  final bool hasReducedMotion;
  final int totalSessions;
  final String? lastActiveDate;
  final int hour;
  final String preferredLanguage;

  const ExperienceContext({
    required this.timeOfDay,
    required this.engagementLevel,
    required this.interactionSpeed,
    required this.userMood,
    required this.liturgicalSeason,
    required this.preferredVisualTone,
    required this.isFirstVisit,
    required this.isReturning,
    required this.hasReducedMotion,
    required this.totalSessions,
    this.lastActiveDate,
    required this.hour,
    this.preferredLanguage = 'en',
  });
}

class VerseContent {
  final String reference;
  final String text;
  final String? textAm;
  final List<String> phrases;
  final List<String> phrasesAm;

  const VerseContent({
    required this.reference,
    required this.text,
    this.textAm,
    required this.phrases,
    required this.phrasesAm,
  });
}

class InvitationContent {
  final String en;
  final String am;
  final String variant;

  const InvitationContent({
    required this.en,
    required this.am,
    required this.variant,
  });
}

class BlessingContent {
  final String en;
  final String am;
  final String variant;

  const BlessingContent({
    required this.en,
    required this.am,
    required this.variant,
  });
}

const List<VersePhase> allPhases = [
  VersePhase.entering,
  VersePhase.revealing,
  VersePhase.resting,
  VersePhase.inviting,
  VersePhase.receiving,
  VersePhase.blessing,
  VersePhase.complete,
];

int phaseIndex(VersePhase phase) {
  return allPhases.indexOf(phase);
}
