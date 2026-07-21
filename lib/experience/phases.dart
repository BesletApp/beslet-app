import 'dart:math';
import 'types.dart';

typedef _IntentVote = ({ExperienceIntent intent, double confidence});

List<_IntentVote> _voteEngagement(ExperienceContext ctx) {
  switch (ctx.engagementLevel) {
    case EngagementLevel.newUser:
      return const [
        (intent: ExperienceIntent.grounding, confidence: 0.6),
        (intent: ExperienceIntent.comforting, confidence: 0.4),
      ];
    case EngagementLevel.casual:
      return const [
        (intent: ExperienceIntent.grounding, confidence: 0.4),
        (intent: ExperienceIntent.awakening, confidence: 0.3),
        (intent: ExperienceIntent.comforting, confidence: 0.3),
      ];
    case EngagementLevel.regular:
      return const [
        (intent: ExperienceIntent.affirming, confidence: 0.4),
        (intent: ExperienceIntent.awakening, confidence: 0.3),
        (intent: ExperienceIntent.grounding, confidence: 0.3),
      ];
    case EngagementLevel.faithful:
      return const [
        (intent: ExperienceIntent.affirming, confidence: 0.5),
        (intent: ExperienceIntent.awakening, confidence: 0.3),
        (intent: ExperienceIntent.resting, confidence: 0.2),
      ];
    case EngagementLevel.devoted:
      return const [
        (intent: ExperienceIntent.resting, confidence: 0.4),
        (intent: ExperienceIntent.affirming, confidence: 0.4),
        (intent: ExperienceIntent.awakening, confidence: 0.2),
      ];
  }
}

List<_IntentVote> _voteMood(ExperienceContext ctx) {
  switch (ctx.userMood) {
    case UserMood.anxious:
      return const [
        (intent: ExperienceIntent.comforting, confidence: 0.8),
        (intent: ExperienceIntent.grounding, confidence: 0.7),
        (intent: ExperienceIntent.resting, confidence: 0.4),
      ];
    case UserMood.tired:
      return const [
        (intent: ExperienceIntent.resting, confidence: 0.8),
        (intent: ExperienceIntent.comforting, confidence: 0.5),
        (intent: ExperienceIntent.grounding, confidence: 0.4),
      ];
    case UserMood.joyful:
      return const [
        (intent: ExperienceIntent.awakening, confidence: 0.8),
        (intent: ExperienceIntent.affirming, confidence: 0.7),
        (intent: ExperienceIntent.slowing, confidence: 0.2),
      ];
    case UserMood.sorrowful:
      return const [
        (intent: ExperienceIntent.comforting, confidence: 0.9),
        (intent: ExperienceIntent.resting, confidence: 0.6),
        (intent: ExperienceIntent.grounding, confidence: 0.5),
      ];
    case UserMood.peaceful:
      return const [
        (intent: ExperienceIntent.slowing, confidence: 0.6),
        (intent: ExperienceIntent.grounding, confidence: 0.5),
        (intent: ExperienceIntent.resting, confidence: 0.4),
      ];
    case UserMood.neutral:
      return const [
        (intent: ExperienceIntent.grounding, confidence: 0.5),
        (intent: ExperienceIntent.awakening, confidence: 0.3),
        (intent: ExperienceIntent.affirming, confidence: 0.3),
      ];
  }
}

List<_IntentVote> _voteSpeed(ExperienceContext ctx) {
  switch (ctx.interactionSpeed) {
    case InteractionSpeed.contemplative:
      return const [
        (intent: ExperienceIntent.slowing, confidence: 0.8),
        (intent: ExperienceIntent.resting, confidence: 0.6),
        (intent: ExperienceIntent.grounding, confidence: 0.4),
      ];
    case InteractionSpeed.moderate:
      return const [
        (intent: ExperienceIntent.grounding, confidence: 0.5),
        (intent: ExperienceIntent.awakening, confidence: 0.4),
        (intent: ExperienceIntent.affirming, confidence: 0.3),
      ];
    case InteractionSpeed.quick:
      return const [
        (intent: ExperienceIntent.awakening, confidence: 0.7),
        (intent: ExperienceIntent.affirming, confidence: 0.6),
        (intent: ExperienceIntent.grounding, confidence: 0.2),
      ];
  }
}

List<_IntentVote> _voteTimeOfDay(ExperienceContext ctx) {
  switch (ctx.timeOfDay) {
    case DayTime.dawn:
      return const [
        (intent: ExperienceIntent.awakening, confidence: 0.9),
        (intent: ExperienceIntent.grounding, confidence: 0.3),
      ];
    case DayTime.morning:
      return const [
        (intent: ExperienceIntent.awakening, confidence: 0.6),
        (intent: ExperienceIntent.affirming, confidence: 0.5),
        (intent: ExperienceIntent.slowing, confidence: 0.2),
      ];
    case DayTime.afternoon:
      return const [
        (intent: ExperienceIntent.affirming, confidence: 0.5),
        (intent: ExperienceIntent.grounding, confidence: 0.4),
        (intent: ExperienceIntent.slowing, confidence: 0.3),
      ];
    case DayTime.evening:
      return const [
        (intent: ExperienceIntent.grounding, confidence: 0.6),
        (intent: ExperienceIntent.slowing, confidence: 0.5),
        (intent: ExperienceIntent.resting, confidence: 0.3),
      ];
    case DayTime.night:
      return const [
        (intent: ExperienceIntent.resting, confidence: 0.7),
        (intent: ExperienceIntent.comforting, confidence: 0.5),
        (intent: ExperienceIntent.slowing, confidence: 0.4),
      ];
    case DayTime.deepNight:
      return const [
        (intent: ExperienceIntent.resting, confidence: 0.9),
        (intent: ExperienceIntent.comforting, confidence: 0.6),
        (intent: ExperienceIntent.grounding, confidence: 0.2),
      ];
  }
}

Map<ExperienceIntent, double> _accumulateVotes(List<List<_IntentVote>> votes, List<double> weights) {
  final totals = <ExperienceIntent, double>{
    for (final intent in ExperienceIntent.values) intent: 0.0,
  };
  for (int i = 0; i < votes.length; i++) {
    final weight = weights[i];
    for (final vote in votes[i]) {
      totals[vote.intent] = (totals[vote.intent] ?? 0.0) + vote.confidence * weight;
    }
  }
  return totals;
}

ExperienceIntent getExperienceIntent(ExperienceContext ctx) {
  final votes = [
    _voteEngagement(ctx),
    _voteMood(ctx),
    _voteSpeed(ctx),
    _voteTimeOfDay(ctx),
  ];
  const weights = [0.3, 0.3, 0.25, 0.15];
  final totals = _accumulateVotes(votes, weights);

  ExperienceIntent best = ExperienceIntent.grounding;
  double bestScore = -1;
  for (final entry in totals.entries) {
    if (entry.value > bestScore) {
      bestScore = entry.value;
      best = entry.key;
    }
  }
  return best;
}

int blendTiming(int baseMs, ExperienceContext ctx, ExperienceIntent intent) {
  const speedFactors = {
    InteractionSpeed.contemplative: 1.4,
    InteractionSpeed.moderate: 1.0,
    InteractionSpeed.quick: 0.7,
  };

  const timeFactors = {
    DayTime.dawn: 0.85,
    DayTime.morning: 0.9,
    DayTime.afternoon: 1.0,
    DayTime.evening: 1.1,
    DayTime.night: 1.2,
    DayTime.deepNight: 1.3,
  };

  const engagementFactors = {
    EngagementLevel.newUser: 1.3,
    EngagementLevel.casual: 1.15,
    EngagementLevel.regular: 1.0,
    EngagementLevel.faithful: 0.85,
    EngagementLevel.devoted: 0.75,
  };

  const moodFactors = {
    UserMood.anxious: 1.3,
    UserMood.tired: 1.2,
    UserMood.joyful: 0.85,
    UserMood.sorrowful: 1.25,
    UserMood.peaceful: 1.0,
    UserMood.neutral: 1.0,
  };

  const intentOverrides = {
    ExperienceIntent.grounding: 1.1,
    ExperienceIntent.slowing: 1.3,
    ExperienceIntent.comforting: 1.15,
    ExperienceIntent.affirming: 0.9,
    ExperienceIntent.awakening: 0.85,
    ExperienceIntent.resting: 1.2,
  };

  final blended = baseMs *
      (0.3 * (engagementFactors[ctx.engagementLevel] ?? 1.0) +
          0.3 * (moodFactors[ctx.userMood] ?? 1.0) +
          0.25 * (speedFactors[ctx.interactionSpeed] ?? 1.0) +
          0.15 * (timeFactors[ctx.timeOfDay] ?? 1.0)) *
      (intentOverrides[intent] ?? 1.0);

  return (blended.clamp(400, 8000)).round();
}

int _baseDurationMs(VersePhase phase) {
  switch (phase) {
    case VersePhase.entering: return 3000;
    case VersePhase.revealing: return 4000;
    case VersePhase.resting: return 3500;
    case VersePhase.inviting: return 10000;
    case VersePhase.receiving: return 1500;
    case VersePhase.blessing: return 4000;
    case VersePhase.complete: return 2500;
  }
}

PhaseAnimationConfig _phaseAnimation(VersePhase phase, double softness) {
  switch (phase) {
    case VersePhase.revealing:
      return PhaseAnimationConfig(durationMs: 700, stiffness: 80, damping: softness);
    case VersePhase.receiving:
      return PhaseAnimationConfig(durationMs: 400, stiffness: 60, damping: 12);
    default:
      return PhaseAnimationConfig(durationMs: 600, stiffness: 100, damping: softness);
  }
}

bool shouldSkipPhase(VersePhase phase, ExperienceContext ctx, ExperienceIntent intent) {
  if (ctx.hasReducedMotion && phase == VersePhase.entering) return true;
  if (phase == VersePhase.entering && ctx.engagementLevel == EngagementLevel.devoted) return true;
  if (phase == VersePhase.entering && ctx.isReturning && ctx.interactionSpeed == InteractionSpeed.quick) return true;
  if (phase == VersePhase.inviting && ctx.engagementLevel == EngagementLevel.devoted && ctx.interactionSpeed == InteractionSpeed.quick) return true;
  if (phase == VersePhase.inviting && ctx.engagementLevel == EngagementLevel.faithful && ctx.interactionSpeed == InteractionSpeed.quick) return true;
  return false;
}

PhaseConfig getPhaseConfig(VersePhase phase, ExperienceContext ctx, ExperienceIntent intent) {
  final baseDuration = _baseDurationMs(phase);
  final effectiveDuration = blendTiming(baseDuration, ctx, intent);

  final softness = (20 + ctx.engagementLevel.index * 3).toDouble();

  var adjustedDuration = effectiveDuration;
  final sessionSeed = 1.0 + (Random().nextDouble() - 0.5) * 0.2;
  if (phase == VersePhase.resting || phase == VersePhase.blessing) {
    adjustedDuration = (effectiveDuration * sessionSeed).round();
  }
  if (phase == VersePhase.resting && ctx.userMood == UserMood.anxious) {
    adjustedDuration = (effectiveDuration * 1.5).round();
  }
  if (phase == VersePhase.resting && ctx.userMood == UserMood.tired) {
    adjustedDuration = (effectiveDuration * 1.3).round();
  }
  if (phase == VersePhase.entering && ctx.isReturning && intent == ExperienceIntent.awakening) {
    adjustedDuration = (effectiveDuration * 0.6).round();
  }

  return PhaseConfig(
    phase: phase,
    durationMs: adjustedDuration.clamp(400, 8000),
    skipAllowed: shouldSkipPhase(phase, ctx, intent),
    reducedMotionDurationMs: min(baseDuration, 400),
    animation: _phaseAnimation(phase, softness),
  );
}

VersePhase getNextPhase(VersePhase current, List<VersePhase> skipped) {
  final currentIdx = allPhases.indexOf(current);
  if (currentIdx == -1 || currentIdx >= allPhases.length - 1) return VersePhase.complete;

  for (int i = currentIdx + 1; i < allPhases.length; i++) {
    if (!skipped.contains(allPhases[i])) return allPhases[i];
  }
  return VersePhase.complete;
}
