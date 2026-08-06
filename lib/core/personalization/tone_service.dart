import '../../l10n/app_localizations.dart';
import 'personalization_engine.dart';

class ToneService {
  final PersonalizationEngine _engine;

  ToneService(this._engine);

  /// Maps the chosen voice to a tone index:
  /// 'quiet' → 0 (soft, minimal), 'warm' → 1 (friendly), 'still' → 2 (calm, reflective)
  int get _tone {
    final v = _engine.voice;
    if (v == 'quiet') return 0;
    if (v == 'still') return 2;
    return 1;
  }

  String greeting(AppLocalizations l, int hour) {
    final warmth = _engine.wasAwayForDays ? 2 : (_engine.isFirstSessionToday ? 1 : 0);
    final base = hour < 12
        ? l.goodMorning
        : hour < 18
            ? l.goodAfternoon
            : l.goodEvening;

    if (_engine.appOpenCount == 1) return base;

    final tone = _tone;
    if (warmth >= 2 && tone == 1) return '$base, friend';
    if (warmth >= 2 && tone == 0) return '$base — welcome back';
    if (warmth >= 1 && tone == 0) return '$base — good to see you';
    return base;
  }

  String reflectionPrompt(AppLocalizations l, int index) {
    final tone = _tone;
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
    return variants[tone % variants.length];
  }

  String completionMessage(AppLocalizations l, String name) {
    final tone = _tone;
    final displayName = name.isNotEmpty ? name : 'you';
    final messages = [
      'Beautiful, $displayName.',
      'Well done, $displayName.',
      'You showed up. That is enough, $displayName.',
    ];
    return messages[tone];
  }

  String emptyState(String area) {
    final tone = _tone;
    final messages = {
      'tasks': ['Space awaits.', 'A quiet day. What matters?', 'Rest. Then begin.'],
      'tasks_alt': ['No tasks yet — breathe.', 'Stillness is okay.', 'The day is yours.'],
      'reflection': ['Pause and breathe.', 'Stillness speaks.', 'Rest here a moment.'],
    };
    final opts = messages[area] ?? ['Nothing here yet.', 'All is quiet.', 'Peace for now.'];
    return opts[tone % opts.length];
  }

  String saveAction() {
    return _tone % 2 == 0 ? 'Keep this moment' : 'Hold this gently';
  }

  String planAction() {
    return _tone % 2 == 0 ? 'Shape your day' : 'Set your intention';
  }
}
