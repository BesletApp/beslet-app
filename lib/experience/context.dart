import 'package:flutter/material.dart';
import 'types.dart';

DayTime getTimeOfDay(int hour) {
  if (hour >= 4 && hour < 7) return DayTime.dawn;
  if (hour >= 7 && hour < 12) return DayTime.morning;
  if (hour >= 12 && hour < 17) return DayTime.afternoon;
  if (hour >= 17 && hour < 20) return DayTime.evening;
  if (hour >= 20 && hour < 24) return DayTime.night;
  return DayTime.deepNight;
}

EngagementLevel getEngagementLevel(int sessions) {
  if (sessions >= 100) return EngagementLevel.devoted;
  if (sessions >= 50) return EngagementLevel.faithful;
  if (sessions >= 20) return EngagementLevel.regular;
  if (sessions >= 5) return EngagementLevel.casual;
  return EngagementLevel.newUser;
}

InteractionSpeed getInteractionSpeed(double? dwellTimeMs, InteractionSpeed? storedPreference) {
  if (storedPreference != null) return storedPreference;
  if (dwellTimeMs == null) return InteractionSpeed.moderate;
  if (dwellTimeMs > 60000) return InteractionSpeed.contemplative;
  if (dwellTimeMs < 15000) return InteractionSpeed.quick;
  return InteractionSpeed.moderate;
}

LiturgicalSeason getLiturgicalSeason(DateTime date) {
  final month = date.month;
  final day = date.day;

  bool isBetween(int startM, int startD, int endM, int endD) {
    final start = DateTime(2000, startM, startD);
    final end = DateTime(2000, endM, endD);
    final current = DateTime(2000, month, day);
    if (start.isBefore(end) || start.isAtSameMomentAs(end)) {
      return (current.isAfter(start) || current.isAtSameMomentAs(start)) &&
          (current.isBefore(end) || current.isAtSameMomentAs(end));
    }
    return (current.isAfter(start) || current.isAtSameMomentAs(start)) ||
        (current.isBefore(end) || current.isAtSameMomentAs(end));
  }

  if (isBetween(12, 25, 12, 26)) return LiturgicalSeason.christmas;
  if (isBetween(11, 3, 12, 24)) return LiturgicalSeason.advent;
  if (isBetween(1, 7, 1, 13)) return LiturgicalSeason.epiphany;
  if (isBetween(2, 1, 2, 14)) return LiturgicalSeason.lent;
  if (isBetween(2, 15, 3, 31)) return LiturgicalSeason.easter;
  return LiturgicalSeason.ordinary;
}

UserMood getUserMood(List<Map<String, dynamic>>? checkIns) {
  if (checkIns == null || checkIns.isEmpty) return UserMood.neutral;
  final last = checkIns.last;
  final moodStr = last['mood']?.toString() ?? '';
  switch (moodStr) {
    case 'anxious': return UserMood.anxious;
    case 'tired': return UserMood.tired;
    case 'joyful': return UserMood.joyful;
    case 'sorrowful': return UserMood.sorrowful;
    case 'peaceful': return UserMood.peaceful;
    default: return UserMood.neutral;
  }
}

bool detectReducedMotion() {
  try {
    return WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.reduceMotion;
  } catch (_) {
    return false;
  }
}

ExperienceContext buildExperienceContext({
  required int totalSessions,
  String? lastActiveDate,
  VisualTone preferredVisualTone = VisualTone.calm,
  InteractionSpeed? storedSpeed,
  double? averageDwellTimeMs,
  List<Map<String, dynamic>>? moodCheckIns,
  required bool hasReducedMotion,
  String preferredLanguage = 'en',
}) {
  final now = DateTime.now();
  final hour = now.hour;

  return ExperienceContext(
    timeOfDay: getTimeOfDay(hour),
    engagementLevel: getEngagementLevel(totalSessions),
    interactionSpeed: getInteractionSpeed(averageDwellTimeMs, storedSpeed),
    userMood: getUserMood(moodCheckIns),
    liturgicalSeason: getLiturgicalSeason(now),
    preferredVisualTone: preferredVisualTone,
    isFirstVisit: totalSessions == 0,
    isReturning: lastActiveDate != null
        ? DateTime.parse(lastActiveDate).isBefore(DateTime(now.year, now.month, now.day - 1))
        : false,
    hasReducedMotion: hasReducedMotion,
    totalSessions: totalSessions,
    lastActiveDate: lastActiveDate,
    hour: hour,
    preferredLanguage: preferredLanguage,
  );
}
