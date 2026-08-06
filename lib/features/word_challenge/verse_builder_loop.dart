import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/word_challenge_provider.dart';
import '../../core/services/widget_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../l10n/app_localizations.dart';
import 'emphasized_verse_text.dart';

/// The "Hide the Word" loop (Psalm 119:11): a single, silent, continuous
/// practice — see the verse, rebuild it from shuffled words, and want to do
/// it again. No stages, no screens, no buttons, no audio.
///
/// Collapsed it is the Home anchor card. Tapped, it expands in place into the
/// loop. A spaced review that has come due peeks out as a quiet pill.
class VerseBuilderCard extends ConsumerStatefulWidget {
  const VerseBuilderCard({super.key});

  @override
  ConsumerState<VerseBuilderCard> createState() => _VerseBuilderCardState();
}

class _VerseBuilderCardState extends ConsumerState<VerseBuilderCard> {
  bool _expanded = false;

  static const List<Color> _masteryColors = [
    Color(0xFF9CBD8A),
    Color(0xFF6FA85A),
    Color(0xFF2E7D32),
  ];

  String _masteryLabel(int level, AppLocalizations l) => switch (level) {
        1 => l.masteryGrowing,
        2 => l.masteryRooted,
        _ => l.masteryNew,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = AppColors.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final challenge = ref.watch(todayWordChallengeProvider);
    final reviewDue = ref.watch(reviewDueCountProvider).valueOrNull ?? 0;

    final light = WidgetService.lightStateFor(DateTime.now());
    final lightTint = switch (light) {
      LampLight.dawn => const Color(0x14C8A96E),
      LampLight.noon => const Color(0x149FD0F0),
      LampLight.dusk => const Color(0x14E8965C),
      LampLight.night => const Color(0x148F8FD0),
    };

    return Column(
      children: [
        Divider(height: 1, thickness: 0.5, color: c.border.withValues(alpha: 0.15)),
        const SizedBox(height: AppSpacing.md),
        Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: lightTint,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: c.border.withValues(alpha: 0.15)),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: challenge.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(child: Text(l.somethingWentWrong)),
                ),
                data: (v) => _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ExpandedHeader(
                            verse: v,
                            masteryLabel: _masteryLabel(v.masteryLevel, l),
                            masteryColor: _VerseBuilderCardState._masteryColors[v.masteryLevel.clamp(0, 2)],
                            onCollapse: () => setState(() => _expanded = false),
                          ),
                          VersePracticeLoop(
                            key: ValueKey(v.id),
                            verse: v,
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () => setState(() => _expanded = true),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  _MasteryPill(level: v.masteryLevel),
                                  const Spacer(),
                                  if (reviewDue > 0)
                                    _ReviewPill(count: reviewDue)
                                  else
                                    Text(
                                      v.reference,
                                      style: AppTextStyles.of(context).labelSmall.copyWith(
                                            color: c.primary.withValues(alpha: 0.7),
                                            letterSpacing: 0.5,
                                          ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                isAm ? (v.textAm ?? v.textEn) : v.textEn,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: isAm
                                    ? AppTextStyles.of(context).bodyMedium.copyWith(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: c.textSecondary.withValues(alpha: 0.95),
                                      )
                                    : AppTextStyles.of(context).displaySmall.copyWith(
                                        fontFamily: 'CormorantGaramond',
                                        fontStyle: FontStyle.italic,
                                        height: 1.5,
                                        fontSize: 18,
                                        color: c.textSecondary.withValues(alpha: 0.85),
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l.tapToPractice,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.of(context).labelSmall.copyWith(
                                      color: c.primary.withValues(alpha: 0.8),
                                      letterSpacing: 0.5,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                l.enterThreshold,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.of(context).bodySmall.copyWith(
                                      fontSize: 11,
                                      color: c.textMuted,
                                      decoration: TextDecoration.underline,
                                      decorationColor: c.textMuted.withValues(alpha: 0.5),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandedHeader extends StatelessWidget {
  final VerseChallengeData verse;
  final String masteryLabel;
  final Color masteryColor;
  final VoidCallback onCollapse;

  const _ExpandedHeader({
    required this.verse,
    required this.masteryLabel,
    required this.masteryColor,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.xs, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: masteryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: masteryColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, size: 14, color: masteryColor),
                const SizedBox(width: 5),
                Text(
                  masteryLabel,
                  style: AppTextStyles.of(context).bodySmall.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: masteryColor,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              verse.reference,
              style: AppTextStyles.of(context).labelSmall.copyWith(
                    color: c.primary.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
            ),
          ),
          IconButton(
            onPressed: onCollapse,
            tooltip: l.close,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.keyboard_arrow_up, size: 20),
            color: c.textMuted,
          ),
        ],
      ),
    );
  }
}

class _MasteryPill extends StatelessWidget {
  final int level;

  const _MasteryPill({required this.level});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = _VerseBuilderCardState._masteryColors[level.clamp(0, 2)];
    final label = switch (level) {
      1 => l.masteryGrowing,
      2 => l.masteryRooted,
      _ => l.masteryNew,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.eco, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.of(context).bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPill extends StatelessWidget {
  final int count;

  const _ReviewPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Material(
      color: c.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => context.push('/memory-garden'),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                l.reviewDue(count),
                style: AppTextStyles.of(context).bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The continuous practice loop. Phases: see the verse → build it from
/// shuffled words → "Well done 🌱" → reshuffle → build again.
class VersePracticeLoop extends ConsumerStatefulWidget {
  final VerseChallengeData verse;

  /// When set, the first completed pass records a spaced review instead of
  /// the day's build (used by the Memory Garden).
  final String? reviewId;
  final VoidCallback? onReviewed;

  const VersePracticeLoop({
    super.key,
    required this.verse,
    this.reviewId,
    this.onReviewed,
  });

  @override
  ConsumerState<VersePracticeLoop> createState() => _VersePracticeLoopState();
}

enum _LoopPhase { showVerse, build, celebrate }

class _VersePracticeLoopState extends ConsumerState<VersePracticeLoop> {
  _LoopPhase _phase = _LoopPhase.showVerse;
  late List<List<_Token>> _chunks;
  int _activeChunk = 0;
  Set<int> _blankIndices = {};
  Map<int, _Token> _filled = {};
  List<_Token> _pool = [];
  int _difficulty = 0;
  int _shakeTick = 0;
  _Token? _shakeChip;
  int _shakeSlot = -1;
  bool _reviewedOnce = false;
  final TextEditingController _typeCtrl = TextEditingController();
  bool _typeWrong = false;
  bool _typeDone = false;
  Timer? _timer;

  bool get _isAm => Localizations.localeOf(context).languageCode == 'am';
  bool get _typeMode => !_isAm && _difficulty >= 2;
  String get _text => _isAm ? (widget.verse.textAm ?? widget.verse.textEn) : widget.verse.textEn;

  @override
  void initState() {
    super.initState();
    _difficulty = widget.verse.masteryLevel;
    _enterSeePhase();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _typeCtrl.dispose();
    super.dispose();
  }

  void _enterSeePhase() {
    _phase = _LoopPhase.showVerse;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) _startBuild();
    });
  }

  void _startBuild() {
    setState(() {
      _phase = _LoopPhase.build;
      _chunks = _chunkTokens(_text);
      _activeChunk = 0;
      _initChunk();
    });
  }

  void _initChunk() {
    final chunk = _chunks[_activeChunk];
    if (_typeMode) {
      _blankIndices = {};
      _filled = {};
      _pool = [];
      _typeCtrl.clear();
      _typeWrong = false;
      _typeDone = false;
      return;
    }
    if (_difficulty <= 0) {
      // Fading cues: keep the first token as an anchor, blank the tail.
      final count = chunk.length <= 4 ? math.max(1, chunk.length - 1) : 3;
      _blankIndices = {
        for (var i = chunk.length - count; i < chunk.length; i++) i,
      };
    } else {
      _blankIndices = {for (var i = 0; i < chunk.length; i++) i};
    }
    _filled = {};
    _pool = [..._blankIndices].map((i) => chunk[i]).toList()..shuffle();
  }

  int? _nextEmptySlot() {
    for (final i in _blankIndices) {
      if (_filled[i] == null) return i;
    }
    return null;
  }

  void _tapChip(_Token t) {
    if (_phase != _LoopPhase.build || _typeMode) return;
    final slot = _nextEmptySlot();
    if (slot == null) return;
    _place(t, slot);
  }

  void _dropOnSlot(int slot, _Token t) {
    if (_phase != _LoopPhase.build || _typeMode) return;
    if (!_blankIndices.contains(slot)) return;
    if (_filled[slot] != null) return;
    _place(t, slot);
  }

  void _place(_Token t, int slot) {
    final correct = _chunks[_activeChunk][slot].text == t.text;
    if (correct) {
      setState(() {
        _pool.remove(t);
        _filled[slot] = t;
      });
      _checkChunkDone();
    } else {
      setState(() {
        _shakeChip = t;
        _shakeSlot = -1;
        _shakeTick++;
      });
    }
  }

  void _checkChunkDone() {
    if (_blankIndices.every((i) => _filled[i] != null)) {
      final next = _activeChunk + 1;
      if (next < _chunks.length) {
        Timer(const Duration(milliseconds: 350), () {
          if (!mounted) return;
          setState(() {
            _activeChunk = next;
            _initChunk();
          });
        });
      } else {
        _celebrate();
      }
    }
  }

  Future<void> _celebrate() async {
    setState(() => _phase = _LoopPhase.celebrate);
    if (widget.reviewId != null) {
      if (!_reviewedOnce) {
        _reviewedOnce = true;
        await ref.read(wordChallengeNotifierProvider.notifier).reviewVerse(widget.reviewId!);
        widget.onReviewed?.call();
      }
    } else {
      // completeBuild only writes the Word step + mastery on the first pass
      // of the day; later loops are pure practice.
      await ref.read(wordChallengeNotifierProvider.notifier).completeBuild();
    }
    if (!mounted) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      final m = ref
              .read(todayWordChallengeProvider)
              .valueOrNull
              ?.masteryLevel ??
          widget.verse.masteryLevel;
      setState(() {
        _difficulty = m;
        _reviewedOnce = widget.reviewId == null ? _reviewedOnce : true;
      });
      _enterSeePhase();
    });
  }

  void _submitType() {
    final input = _normalize(_typeCtrl.text);
    final target = _normalize(_text);
    if (input == target) {
      setState(() => _typeDone = true);
      _celebrate();
    } else {
      setState(() => _typeWrong = true);
    }
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Phrase-chunks a long verse so the loop stays in working memory; short
  /// verses stay a single chunk.
  List<List<_Token>> _chunkTokens(String text) {
    final parts = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final tokens = [for (var i = 0; i < parts.length; i++) _Token(parts[i], i)];
    if (tokens.length <= 9) return [tokens];
    final chunks = <List<_Token>>[];
    var cur = <_Token>[];
    for (final t in tokens) {
      cur.add(t);
      final ends = RegExp(r'[,;—–:!?…]$').hasMatch(t.text);
      if ((ends && cur.length >= 3) || cur.length >= 7) {
        chunks.add(cur);
        cur = [];
      }
    }
    if (cur.isNotEmpty) chunks.add(cur);
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_phase) {
          _LoopPhase.showVerse => _VerseTextDisplay(
              key: const ValueKey('see'),
              text: _text,
              isAm: _isAm,
            ),
          _LoopPhase.celebrate => _Celebrate(
              key: const ValueKey('done'),
              label: AppLocalizations.of(context)!.wellDone,
            ),
          _LoopPhase.build => _buildArea(),
        },
      ),
    );
  }

  Widget _buildArea() {
    if (_typeMode) return _buildTypeArea();
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_chunks.length > 1)
          Center(
            child: Text(
              l.phraseOf(_activeChunk + 1, _chunks.length),
              style: AppTextStyles.of(context).labelSmall.copyWith(
                    color: AppColors.of(context).textMuted,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        _WordWrapDragArea(
          chunks: _chunks,
          activeChunk: _activeChunk,
          blankIndices: _blankIndices,
          filled: _filled,
          shakeTick: _shakeTick,
          shakeSlot: _shakeSlot,
          onDrop: _dropOnSlot,
          onRemove: (slot) {
            final t = _filled[slot];
            if (t == null) return;
            setState(() {
              _filled.remove(slot);
              _pool.add(t);
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChipPool(
          pool: _pool,
          shakeTick: _shakeTick,
          shakeChip: _shakeChip,
          onTap: _tapChip,
        ),
      ],
    );
  }

  Widget _buildTypeArea() {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context)!.hiddenInYourHeart,
          textAlign: TextAlign.center,
          style: AppTextStyles.of(context).labelSmall.copyWith(
                color: c.textMuted,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _typeCtrl,
          minLines: 3,
          maxLines: 6,
          enabled: !_typeDone,
          textAlign: TextAlign.center,
          style: AppTextStyles.of(context).bodyMedium.copyWith(
                fontFamily: 'CormorantGaramond',
                fontStyle: FontStyle.italic,
                fontSize: 18,
                height: 1.5,
              ),
          onChanged: (_) => _typeWrong = false,
          decoration: InputDecoration(
            hintText: '…',
            filled: true,
            fillColor: c.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _typeWrong ? c.success : c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _typeWrong ? c.success : c.border),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: _typeDone ? null : _submitType,
          child: Text(_typeDone ? '✓' : AppLocalizations.of(context)!.checkAnswer),
        ),
      ],
    );
  }
}

class _Token {
  final String text;
  final int index;
  const _Token(this.text, this.index);
}

/// The full verse, quietly readable — the "see" phase.
class _VerseTextDisplay extends StatelessWidget {
  final String text;
  final bool isAm;

  const _VerseTextDisplay({super.key, required this.text, required this.isAm});

  @override
  Widget build(BuildContext context) {
    final t = AppTextStyles.of(context);
    final c = AppColors.of(context);
    final style = isAm
        ? t.displaySmall.copyWith(fontSize: 20, height: 1.7)
        : t.displaySmall.copyWith(
            fontFamily: 'CormorantGaramond',
            fontStyle: FontStyle.italic,
            fontSize: 22,
            height: 1.6,
          );
    return Column(
      children: [
        EmphasizedVerseText(
          text: text,
          emphasize: !isAm,
          style: style.copyWith(color: c.textSecondary.withValues(alpha: 0.9)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)!.hiddenInYourHeart,
          style: AppTextStyles.of(context).labelSmall.copyWith(
                color: c.textMuted,
                letterSpacing: 0.5,
              ),
        ),
      ],
    );
  }
}

class _Celebrate extends StatelessWidget {
  final String label;

  const _Celebrate({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),
        Icon(Icons.eco, color: _VerseBuilderCardState._masteryColors[2], size: 34),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.of(context).displaySmall.copyWith(color: c.success),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppLocalizations.of(context)!.hiddenInYourHeart,
          style: AppTextStyles.of(context).labelSmall.copyWith(color: c.textMuted),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// The verse laid out as word slots: finished phrases shown statically, the
/// active phrase as tappable (and drop-target) blanks, later phrases dimmed.
class _WordWrapDragArea extends StatelessWidget {
  final List<List<_Token>> chunks;
  final int activeChunk;
  final Set<int> blankIndices;
  final Map<int, _Token> filled;
  final int shakeTick;
  final int shakeSlot;
  final void Function(int slot, _Token t) onDrop;
  final void Function(int slot) onRemove;

  const _WordWrapDragArea({
    required this.chunks,
    required this.activeChunk,
    required this.blankIndices,
    required this.filled,
    required this.shakeTick,
    required this.shakeSlot,
    required this.onDrop,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final items = <Widget>[];
    for (var ci = 0; ci < chunks.length; ci++) {
      final chunk = chunks[ci];
      for (var ti = 0; ti < chunk.length; ti++) {
        final token = chunk[ti];
        if (ci < activeChunk) {
          items.add(_staticWord(context, token.text, c.textMuted));
        } else if (ci == activeChunk) {
          if (blankIndices.contains(ti)) {
            items.add(_blankSlot(context, ti));
          } else {
            items.add(_staticWord(context, token.text, c.textSecondary));
          }
        } else {
          items.add(_staticWord(context, token.text, c.textMuted.withValues(alpha: 0.45)));
        }
        items.add(const SizedBox(width: 7));
      }
      items.add(const SizedBox(width: 12));
    }
    return Wrap(children: items);
  }

  Widget _staticWord(BuildContext context, String text, Color color) {
    final t = AppTextStyles.of(context);
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: isAm
            ? t.bodyMedium.copyWith(fontSize: 15, height: 1.6, color: color, fontWeight: FontWeight.w600)
            : t.bodyMedium.copyWith(
                fontFamily: 'CormorantGaramond',
                fontStyle: FontStyle.italic,
                fontSize: 17,
                height: 1.4,
                color: color,
                fontWeight: FontWeight.w600,
              ),
      ),
    );
  }

  Widget _blankSlot(BuildContext context, int slot) {
    final c = AppColors.of(context);
    final t = AppTextStyles.of(context);
    final token = filled[slot];
    return _ShakeBox(
      trigger: shakeSlot == slot ? shakeTick : 0,
      child: DragTarget<_Token>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (d) => onDrop(slot, d.data),
        builder: (context, candidates, rejected) {
          final highlighted = candidates.isNotEmpty;
          return InkWell(
            onTap: token == null ? null : () => onRemove(slot),
            borderRadius: BorderRadius.circular(6),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 6, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: highlighted
                    ? c.primary.withValues(alpha: 0.10)
                    : (token == null ? c.card : c.primary.withValues(alpha: 0.10)),
                borderRadius: BorderRadius.circular(6),
                border: Border(
                  bottom: BorderSide(
                    color: highlighted ? c.primary : c.primary.withValues(alpha: 0.8),
                    width: 1.6,
                  ),
                ),
              ),
              child: Text(
                token?.text ?? '…',
                style: token == null
                    ? t.bodyMedium.copyWith(color: c.primary, fontSize: 15)
                    : t.bodyMedium.copyWith(color: c.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The shuffled word chips to place. Tap to place into the next blank;
/// long-press and drag to drop onto a specific blank.
class _ChipPool extends StatelessWidget {
  final List<_Token> pool;
  final int shakeTick;
  final _Token? shakeChip;
  final void Function(_Token t) onTap;

  const _ChipPool({
    required this.pool,
    required this.shakeTick,
    required this.shakeChip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (pool.isEmpty) return const SizedBox.shrink();
    final t = AppTextStyles.of(context);
    final c = AppColors.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final token in pool)
          _ShakeBox(
            trigger: shakeChip == token ? shakeTick : 0,
            child: LongPressDraggable<_Token>(
              data: token,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              feedback: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(token.text, style: t.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              child: ActionChip(
                label: Text(token.text),
                onPressed: () => onTap(token),
              ),
            ),
          ),
      ],
    );
  }
}

/// Plays a small horizontal shake once whenever [trigger] changes.
class _ShakeBox extends StatefulWidget {
  final int trigger;
  final Widget child;

  const _ShakeBox({required this.trigger, required this.child});

  @override
  State<_ShakeBox> createState() => _ShakeBoxState();
}

class _ShakeBoxState extends State<_ShakeBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  int _last = 0;

  @override
  void initState() {
    super.initState();
    _last = widget.trigger;
  }

  @override
  void didUpdateWidget(_ShakeBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != _last && widget.trigger != 0) {
      _last = widget.trigger;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value;
        final dx = math.sin(v * math.pi * 4) * 4 * (1 - v);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
