import '../../l10n/app_localizations.dart';
import 'personalization_engine.dart';

class ToneService {
  final PersonalizationEngine _engine;

  ToneService(this._engine);

  String greeting(AppLocalizations l, int hour) {
    final warmth = _engine.wasAwayForDays ? 2 : (_engine.isFirstSessionToday ? 1 : 0);
    final base = hour < 12
        ? l.goodMorning
        : hour < 18
            ? l.goodAfternoon
            : l.goodEvening;

    if (_engine.appOpenCount == 1) return base;

    final cycle = _engine.appOpenCount % 3;
    if (warmth >= 2 && cycle == 0) return '$base, friend';
    if (warmth >= 2 && cycle == 1) return '$base — welcome back';
    if (warmth >= 1 && cycle == 0) return '$base — good to see you';
    return base;
  }

  String reflectionPrompt(AppLocalizations l, int index) {
    final cycle = _engine.appOpenCount % 3;
    final prompts = [
      [
        'What helped you grow this week?',
        'What brought you closer this week?',
        'Where did you see growth this week?',
      ],
      [
        'Where did you slip or struggle?',
        'What felt heavy this week?',
        'What was difficult this week?',
      ],
      [
        'What will you focus on next week?',
        'What do you want to carry into next week?',
        'What intention will you set for next week?',
      ],
    ];
    if (index < 0 || index >= prompts.length) return '';
    final variants = prompts[index];
    return variants[cycle % variants.length];
  }

  String completionMessage(AppLocalizations l, String name) {
    final cycle = _engine.appOpenCount % 3;
    final messages = [
      'Beautiful, $name.',
      'Well done, $name.',
      'You showed up. That is enough, $name.',
    ];
    return messages[cycle];
  }

  String emptyState(String area) {
    final cycle = _engine.appOpenCount % 3;
    final messages = {
      'tasks': ['Space awaits.', 'A quiet day. What matters?', 'Rest. Then begin.'],
      'tasks_alt': ['No tasks yet — breathe.', 'Stillness is okay.', 'The day is yours.'],
      'reflection': ['Pause and breathe.', 'Stillness speaks.', 'Rest here a moment.'],
    };
    final opts = messages[area] ?? ['Nothing here yet.', 'All is quiet.', 'Peace for now.'];
    return opts[cycle % opts.length];
  }

  String saveAction() {
    final cycle = _engine.appOpenCount % 2;
    return cycle == 0 ? 'Keep this moment' : 'Hold this gently';
  }

  String planAction() {
    final cycle = _engine.appOpenCount % 2;
    return cycle == 0 ? 'Shape your day' : 'Set your intention';
  }
}
