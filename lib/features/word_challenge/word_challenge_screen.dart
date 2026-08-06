import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/audio_player_provider.dart';
import '../../core/providers/word_challenge_provider.dart';
import '../../core/services/scripture_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import 'emphasized_verse_text.dart';

/// A gentle, whole-person journey through one verse a day: See & Hear, then
/// Build, then Pray, then Live it out. There is no timer and no score — each
/// stage is simply a quiet step forward.
class WordChallengeScreen extends ConsumerStatefulWidget {
  final String? reviewId;

  const WordChallengeScreen({super.key, this.reviewId});

  @override
  ConsumerState<WordChallengeScreen> createState() => _WordChallengeScreenState();
}

class _WordChallengeScreenState extends ConsumerState<WordChallengeScreen> {
  static const List<Color> _masteryColors = [
    Color(0xFF9CBD8A), // NEW
    Color(0xFF6FA85A), // GROWING
    Color(0xFF2E7D32), // ROOTED
  ];

  int _stage = 0;
  bool _prayed = false;
  bool _acted = false;
  bool _spokeOnce = false;
  bool _toasted = false;
  bool _finishedReview = false;
  String _prayer = '';
  final TextEditingController _prayerCtrl = TextEditingController();

  bool get _isReview => widget.reviewId != null;

  @override
  void dispose() {
    _prayerCtrl.dispose();
    super.dispose();
  }

  Future<void> _speak(VerseChallengeData c, bool isAm) async {
    final text = isAm ? (c.textAm ?? c.textEn) : c.textEn;
    try {
      await ref
          .read(audioPlayerProvider.notifier)
          .speakVerse(text, isAmharic: isAm);
    } catch (_) {
      // TTS unavailable (offline, no engine) — the verse is still readable.
    }
  }

  void _maybeAutoSpeak(VerseChallengeData c, bool isAm) {
    if (_spokeOnce) return;
    _spokeOnce = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak(c, isAm));
  }

  Future<void> _completeBuild() async {
    await ref.read(wordChallengeNotifierProvider.notifier).completeBuild();
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    if (!_toasted) {
      _toasted = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.wordIsRooting),
          backgroundColor: AppColors.of(context).success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
    setState(() => _stage = 2);
  }

  Future<void> _finishReview() async {
    if (_finishedReview) return;
    _finishedReview = true;
    await ref.read(wordChallengeNotifierProvider.notifier).reviewVerse(widget.reviewId!);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.reviewDone),
        backgroundColor: AppColors.of(context).success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    context.pop();
  }

  Future<void> _savePrayer() async {
    final text = _prayer.trim().isEmpty ? null : _prayer.trim();
    await ref.read(wordChallengeNotifierProvider.notifier).savePrayer(text ?? '');
    if (!mounted) return;
    setState(() => _prayed = true);
  }

  Future<void> _chooseAct(String act) async {
    await ref.read(wordChallengeNotifierProvider.notifier).chooseAct(act);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.actAdded),
        backgroundColor: AppColors.of(context).success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    setState(() => _acted = true);
  }

  /// Loads the specific verse being reviewed. If it has not been touched yet
  /// it still resolves, so the review never dead-ends.
  AsyncValue<VerseChallengeData> _reviewChallenge() {
    final all = ref.watch(allWordChallengesProvider);
    final existing = all.valueOrNull;
    if (existing == null) {
      if (all.hasError) {
        return AsyncError<VerseChallengeData>(
          all.error!,
          all.stackTrace ?? StackTrace.current,
        );
      }
      return const AsyncLoading<VerseChallengeData>();
    }
    final match = existing.isEmpty
        ? VerseChallengeData.fromScripture(ScriptureService.threadVerseFor(DateTime.now()))
        : existing.firstWhere(
            (c) => c.id == widget.reviewId,
            orElse: () => existing.first,
          );
    return AsyncData(match);
  }

  String _themeWord(String verse) {
    const stop = {
      'the', 'and', 'for', 'you', 'your', 'i', 'a', 'an', 'of', 'to', 'in',
      'is', 'it', 'that', 'he', 'his', 'her', 'we', 'our', 'their', 'they',
      'all', 'this', 'with', 'as', 'on', 'at', 'be', 'by', 'from', 'who',
      'not', 'but', 'have', 'has', 'are', 'was', 'were', 'me', 'my', 'so',
      'or', 'if', 'when', 'what', 'which', 'there', 'these', 'those', 'do',
      'does', 'did', 'shall', 'can', 'will', 'would', 'should', 'unto',
    };
    String best = '';
    for (final w in verse.split(RegExp(r'\s+'))) {
      final core = w.replaceAll(RegExp(r'[^a-zA-Z]'), '').toLowerCase();
      if (core.length > best.length && !stop.contains(core)) best = core;
    }
    return best.isEmpty ? 'love' : best;
  }

  String _masteryLabel(int level, AppLocalizations l) => switch (level) {
        1 => l.masteryGrowing,
        2 => l.masteryRooted,
        _ => l.masteryNew,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final AsyncValue<VerseChallengeData> challenge = _isReview
        ? _reviewChallenge()
        : ref.watch(todayWordChallengeProvider);

    return Scaffold(
      backgroundColor: AppColors.of(context).background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isReview ? l.review : l.wordChallenge),
      ),
      body: SafeArea(
        child: challenge.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text(l.somethingWentWrong)),
          data: (c) {
            _maybeAutoSpeak(c, isAm);
            final segments = _isReview ? 1 : 3;
            return Column(
              children: [
                _ProgressBar(segments: segments, active: _isReview ? 1 : (_stage + 1).clamp(1, 3)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _buildStage(c, l, isAm),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStage(VerseChallengeData c, AppLocalizations l, bool isAm) {
    switch (_stage) {
      case 0:
        return _buildSeeAndHear(c, l, isAm);
      case 1:
        return _buildBuild(c, l, isAm);
      default:
        return _buildPrayAndAct(c, l, isAm);
    }
  }

  Widget _buildSeeAndHear(VerseChallengeData c, AppLocalizations l, bool isAm) {
    final cCol = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final primary = isAm ? (c.textAm ?? c.textEn) : c.textEn;
    final secondary = isAm ? c.textEn : (c.textAm ?? '');
    final primaryStyle = isAm
        ? t.displaySmall.copyWith(fontSize: 22, height: 1.7)
        : t.displaySmall.copyWith(
            fontFamily: 'CormorantGaramond',
            fontStyle: FontStyle.italic,
            fontSize: 24,
            height: 1.55,
          );
    final secondaryStyle = isAm
        ? t.bodyMedium.copyWith(
            fontFamily: 'CormorantGaramond',
            fontStyle: FontStyle.italic,
            height: 1.55,
            color: cCol.textMuted,
          )
        : t.bodyMedium.copyWith(fontSize: 14, height: 1.7, color: cCol.textMuted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _MasteryChip(level: c.masteryLevel, label: _masteryLabel(c.masteryLevel, l)),
            const Spacer(),
            Text(
              c.reference,
              style: t.labelSmall.copyWith(color: cCol.primary, letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('“', style: t.displayMedium.copyWith(color: cCol.primary, fontSize: 42)),
        EmphasizedVerseText(
          text: primary,
          emphasize: !isAm,
          style: primaryStyle,
          textAlign: TextAlign.center,
        ),
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          EmphasizedVerseText(
            text: secondary,
            emphasize: !isAm,
            style: secondaryStyle,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        OutlinedButton.icon(
          onPressed: () => _speak(c, isAm),
          icon: const Icon(Icons.volume_up, size: 18),
          label: Text(l.hearTheVerse),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: () => setState(() => _stage = 1),
          child: Text(l.continueWord),
        ),
      ],
    );
  }

  Widget _buildBuild(VerseChallengeData c, AppLocalizations l, bool isAm) {
    final cCol = AppColors.of(context);
    final text = isAm ? (c.textAm ?? c.textEn) : c.textEn;
    final typeMode = !isAm && c.masteryLevel >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.buildPrompt,
          style: AppTextStyles.of(context).bodyMedium.copyWith(color: cCol.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md),
        _WordBuilder(
          key: ValueKey('${c.id}-$text'),
          text: text,
          difficulty: c.masteryLevel,
          typeMode: typeMode,
          onSuccess: _isReview ? _finishReview : _completeBuild,
        ),
      ],
    );
  }

  Widget _buildPrayAndAct(VerseChallengeData c, AppLocalizations l, bool isAm) {
    final cCol = AppColors.of(context);
    final theme = _themeWord(c.textEn);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.turnVerseIntoPrayer,
          style: AppTextStyles.of(context).displaySmall.copyWith(color: cCol.textPrimary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l.restInWord,
          style: AppTextStyles.of(context).bodyMedium.copyWith(color: cCol.textSecondary, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cCol.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cCol.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l.prayerTemplateThank} (${c.reference})\n'
                '${l.prayerTemplateAsk}\n'
                '${l.prayerTemplateRest}',
                style: AppTextStyles.of(context).bodyMedium.copyWith(
                      color: cCol.textMuted,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _prayerCtrl,
                maxLines: 4,
                maxLength: 400,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (v) => _prayer = v,
                decoration: InputDecoration(
                  hintText: l.prayerTemplateHint,
                  filled: true,
                  fillColor: cCol.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cCol.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cCol.border),
                  ),
                  counterText: '',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _prayed ? null : _savePrayer,
                child: Text(_prayed ? l.savedPrayer : l.savePrayer),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l.shareVerseToday,
          style: AppTextStyles.of(context).labelSmall.copyWith(
                color: cCol.textSecondary,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActChip(
          icon: Icons.people_outline,
          label: l.liveOutTheme(theme),
          onTap: _acted ? null : () => _chooseAct(l.liveOutTheme(theme)),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ActChip(
          icon: Icons.eco_outlined,
          label: l.actPrayBack,
          onTap: _acted ? null : () => _chooseAct(l.actPrayBack),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int segments;
  final int active;

  const _ProgressBar({required this.segments, required this.active});

  @override
  Widget build(BuildContext context) {
    final cCol = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          for (var i = 0; i < segments; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 5,
                margin: EdgeInsets.only(right: i < segments - 1 ? 6 : 0),
                decoration: BoxDecoration(
                  color: i < active ? cCol.primary : cCol.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MasteryChip extends StatelessWidget {
  final int level;
  final String label;

  const _MasteryChip({required this.level, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _WordChallengeScreenState._masteryColors[level.clamp(0, 2)];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.of(context).bodySmall.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cCol = AppColors.of(context);
    final done = onTap == null;
    return Material(
      color: done ? cCol.card : cCol.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: done ? cCol.success.withValues(alpha: 0.5) : cCol.border),
          ),
          child: Row(
            children: [
              Icon(done ? Icons.check_circle : icon,
                  size: 20, color: done ? cCol.success : cCol.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.of(context).bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: done ? cCol.success : cCol.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordWord {
  final String text;
  final int index;
  const _WordWord(this.text, this.index);
}

/// The Build stage: the verse is shown with some words missing, and the user
/// re-places them (tap the right order). At ROOTED the English verse is typed
/// from memory instead. Amharic always stays a tap-and-place game — fidel
/// keyboards are not a fair ask for anyone.
class _WordBuilder extends StatefulWidget {
  final String text;
  final int difficulty;
  final bool typeMode;
  final VoidCallback onSuccess;

  const _WordBuilder({
    super.key,
    required this.text,
    required this.difficulty,
    required this.typeMode,
    required this.onSuccess,
  });

  @override
  State<_WordBuilder> createState() => _WordBuilderState();
}

class _WordBuilderState extends State<_WordBuilder> {
  final List<_WordWord> _pool = [];
  late final List<_WordWord> _words;
  late final List<int> _blankIndices;
  final Map<int, _WordWord?> _filled = {};
  final TextEditingController _typeCtrl = TextEditingController();
  bool _done = false;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    final parts = widget.text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    _words = [for (var i = 0; i < parts.length; i++) _WordWord(parts[i], i)];
    _blankIndices = widget.difficulty <= 0 && _words.length > 4
        ? _pickBlanks(4)
        : [for (var i = 0; i < _words.length; i++) i];
    final shuffled = [..._blankIndices]..shuffle();
    for (final i in shuffled) {
      _pool.add(_words[i]);
    }
  }

  List<int> _pickBlanks(int count) {
    final idx = List<int>.generate(_words.length, (i) => i)..shuffle();
    return idx.take(count).toList()..sort();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  void _fill(_WordWord w) {
    final target = _blankIndices.firstWhere((i) => _filled[i] == null);
    setState(() {
      _pool.remove(w);
      _filled[target] = w;
    });
    _checkCompletion();
  }

  void _clearSlot(int i) {
    setState(() {
      _pool.add(_filled[i]!);
      _filled[i] = null;
    });
  }

  void _checkCompletion() {
    if (_blankIndices.every((i) => _filled[i] != null)) {
      _done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSuccess();
      });
    }
  }

  void _submitType() {
    final input = _normalize(_typeCtrl.text);
    final target = _normalize(widget.text);
    if (input == target) {
      setState(() => _done = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onSuccess();
      });
    } else {
      setState(() => _wrong = true);
    }
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  @override
  Widget build(BuildContext context) {
    final cCol = AppColors.of(context);
    final t = AppTextStyles.of(context);

    if (widget.typeMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _typeCtrl,
            minLines: 3,
            maxLines: 5,
            textAlign: TextAlign.center,
            enabled: !_done,
            style: t.bodyMedium.copyWith(fontFamily: 'CormorantGaramond', fontStyle: FontStyle.italic, fontSize: 18, height: 1.5),
            onChanged: (_) => _wrong = false,
            decoration: InputDecoration(
              hintText: '…',
              filled: true,
              fillColor: cCol.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _wrong ? cCol.success : cCol.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _wrong ? cCol.success : cCol.border),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _done ? null : _submitType,
            child: Text(_done ? '✓' : AppLocalizations.of(context)!.checkAnswer),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _words.length; i++)
              _blankIndices.contains(i)
                  ? _blankSlot(i)
                  : Container(
                      margin: const EdgeInsets.only(right: 4, bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                      child: Text(_words[i].text,
                          style: t.bodyMedium.copyWith(color: cCol.textMuted)),
                    ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_pool.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in _pool)
                ActionChip(
                  label: Text(w.text),
                  onPressed: _done ? null : () => _fill(w),
                ),
            ],
          )
        else
          Center(
            child: Text(
              '✓',
              style: t.displayMedium.copyWith(color: cCol.success),
            ),
          ),
      ],
    );
  }

  Widget _blankSlot(int i) {
    final cCol = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final filled = _filled[i];
    return InkWell(
      onTap: filled == null || _done ? null : () => _clearSlot(i),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(right: 4, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: cCol.card,
          borderRadius: BorderRadius.circular(6),
          border: Border(
            bottom: BorderSide(color: cCol.primary, width: 1.5),
          ),
        ),
        child: Text(
          filled?.text ?? '…',
          style: t.bodyMedium.copyWith(
            color: filled == null ? cCol.primary : cCol.textPrimary,
            fontWeight: filled == null ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
