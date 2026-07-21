import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../experience/types.dart';
import '../../../experience/context.dart';
import '../../../experience/phases.dart';
import '../../../experience/theme_config.dart';
import '../../../core/services/scripture_service.dart';
import '../../../core/services/session_service.dart';
import '../../../core/providers/user_provider.dart';

class ExperienceState {
  final ExperienceContext context;
  final ExperienceIntent intent;
  final ThemeConfig theme;
  final Map<VersePhase, PhaseConfig> phaseConfigs;
  final List<VersePhase> skippedPhases;
  final Scripture scripture;

  const ExperienceState({
    required this.context,
    required this.intent,
    required this.theme,
    required this.phaseConfigs,
    required this.skippedPhases,
    required this.scripture,
  });
}

final experienceProvider = FutureProvider<ExperienceState>((ref) async {
  final user = await ref.watch(userProvider.future);

  final hasReducedMotion = WidgetsBinding.instance.platformDispatcher
      .accessibilityFeatures.reduceMotion;

  await SessionService.recordVisit();
  final totalSessions = await SessionService.getTotalSessions();
  final lastActiveDate = await SessionService.getLastActiveDate();

  final context = buildExperienceContext(
    totalSessions: totalSessions,
    lastActiveDate: lastActiveDate,
    preferredVisualTone: VisualTone.calm,
    storedSpeed: null,
    averageDwellTimeMs: null,
    moodCheckIns: null,
    hasReducedMotion: hasReducedMotion,
    preferredLanguage: user.lang,
  );

  final intent = getExperienceIntent(context);
  final theme = getTheme(context, intent);
  final scripture = ScriptureService.getDailyScripture();

  final phaseConfigs = <VersePhase, PhaseConfig>{};
  for (final phase in allPhases) {
    phaseConfigs[phase] = getPhaseConfig(phase, context, intent);
  }

  final skippedPhases = allPhases
      .where((p) => shouldSkipPhase(p, context, intent))
      .toList();

  return ExperienceState(
    context: context,
    intent: intent,
    theme: theme,
    phaseConfigs: phaseConfigs,
    skippedPhases: skippedPhases,
    scripture: scripture,
  );
});
