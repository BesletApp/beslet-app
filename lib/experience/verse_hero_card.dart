import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/bible_read_provider.dart' as bible;
import '../features/home/providers/experience_provider.dart';
import 'types.dart';
import 'content.dart';
import 'phases.dart';

class VerseHeroCard extends ConsumerStatefulWidget {
  final String? className;
  final VoidCallback? onComplete;
  final VoidCallback? onReceive;
  final bool autoStart;

  const VerseHeroCard({
    super.key,
    this.className,
    this.onComplete,
    this.onReceive,
    this.autoStart = true,
  });

  @override
  ConsumerState<VerseHeroCard> createState() => _VerseHeroCardState();
}

class _VerseHeroCardState extends ConsumerState<VerseHeroCard>
    with SingleTickerProviderStateMixin {
  VersePhase _currentPhase = VersePhase.entering;
  bool _hasReceived = false;
  bool _isComplete = false;
  bool _hasStarted = false;

  ExperienceState? _frozenState;
  Timer? _phaseTimer;
  Timer? _phraseTimer;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  InvitationContent? _invitation;
  BlessingContent? _blessing;
  List<String>? _phrases;
  List<String>? _phrasesAm;
  int _revealedPhraseCount = 0;
  String _language = 'en';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _clearTimers();
    _fadeController.dispose();
    super.dispose();
  }

  void _clearTimers() {
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _phraseTimer?.cancel();
    _phraseTimer = null;
  }

  int _transitionDuration(VersePhase current, VersePhase next) {
    if (current == VersePhase.resting && next == VersePhase.inviting) return 350;
    if (current == VersePhase.receiving && next == VersePhase.blessing) return 350;
    return 600;
  }

  void _advancePhase(VersePhase next) {
    if (!mounted) return;
    setState(() {
      _currentPhase = next;
      if (next == VersePhase.complete) {
        _isComplete = true;
      }
    });
    _fadeController
      ..duration = Duration(milliseconds: _transitionDuration(_currentPhase, next))
      ..forward(from: 0);
    if (_frozenState != null) {
      _startPhaseTimers(_frozenState!);
    }
  }

  void _handleAdvance(
      List<VersePhase> skippedPhases, Map<VersePhase, PhaseConfig> phaseConfigs) {
    final next = getNextPhase(_currentPhase, skippedPhases);
    _advancePhase(next);
  }

  void _handleReceive() {
    final exp = _frozenState;
    if (exp == null || _hasReceived) return;
    _hasReceived = true;
    widget.onReceive?.call();

    try {
      ref.read(bible.bibleNotifierProvider.notifier).markAsRead(exp.scripture.reference);
    } catch (_) {}

    _clearTimers();
    final next = getNextPhase(_currentPhase, exp.skippedPhases);
    _advancePhase(next);
  }

  void _startPhaseTimers(ExperienceState exp) {
    _clearTimers();

    final config = exp.phaseConfigs[_currentPhase];
    if (config == null) return;

    if (_currentPhase == VersePhase.entering && config.skipAllowed) {
      final next = getNextPhase(_currentPhase, exp.skippedPhases);
      _advancePhase(next);
      return;
    }

    if (_currentPhase == VersePhase.revealing) {
      final phrases = _phrases ?? splitVerseIntoPhrases(exp.scripture.text);
      final perPhraseMs =
          (config.durationMs ~/ phrases.length).clamp(400, 1200);
      _revealedPhraseCount = 0;

      int accumulated = 0;
      for (int i = 0; i < phrases.length; i++) {
        final perMs = (perPhraseMs * (1.0 + (Random().nextDouble() - 0.5) * 0.3)).round();
        accumulated += perMs;
        _phraseTimer = Timer(Duration(milliseconds: accumulated), () {
          if (!mounted) return;
          setState(() {
            _revealedPhraseCount = i + 1;
          });
        });
      }

      _phaseTimer = Timer(Duration(milliseconds: config.durationMs + 400), () {
        if (!mounted) return;
        _handleAdvance(exp.skippedPhases, exp.phaseConfigs);
      });
      return;
    }

    if (_currentPhase == VersePhase.inviting) return;

    final phaseDuration = _currentPhase == VersePhase.receiving
        ? config.durationMs + 300
        : config.durationMs;

    _phaseTimer = Timer(Duration(milliseconds: phaseDuration), () {
      if (!mounted) return;
      _handleAdvance(exp.skippedPhases, exp.phaseConfigs);
    });
  }

  ExperienceState? _initFromProvider(ExperienceState exp) {
    if (!_hasStarted && widget.autoStart) {
      _hasStarted = true;
      _frozenState = exp;
      _language = exp.context.preferredLanguage;
      _invitation = getInvitationText(exp.context, exp.intent);
      _blessing = getBlessingText(exp.context, exp.intent);
      _phrases = splitVerseIntoPhrases(exp.scripture.text);
      _phrasesAm = exp.scripture.textAm != null
          ? splitVerseIntoPhrases(exp.scripture.textAm!, isAmharic: true)
          : _phrases;
      _revealedPhraseCount = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fadeController.forward(from: 0);
        _startPhaseTimers(_frozenState!);
      });
    }
    return _frozenState;
  }

  @override
  Widget build(BuildContext context) {
    final expAsync = ref.watch(experienceProvider);

    return expAsync.when(
      loading: () => const _LoadingPhase(),
      error: (err, _) => _ErrorPhase(
        providerRef: ref,
      ),
      data: (exp) {
        final frozen = _initFromProvider(exp);
        if (frozen == null) {
          return const SizedBox(height: 300);
        }

        if (_isComplete && widget.onComplete != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onComplete?.call();
          });
        }

        final theme = frozen.theme;
        final reduced = frozen.context.hasReducedMotion;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [theme.backgroundFrom, theme.backgroundTo],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: theme.borderColor),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          theme.glowColor.withValues(alpha: theme.ambientOpacity),
                          Colors.transparent,
                        ],
                        center: const Alignment(0, -0.2),
                        radius: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildPhaseContent(frozen, reduced),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhaseContent(ExperienceState exp, bool reduced) {
    final isAmharic = _language != 'en';

    switch (_currentPhase) {
      case VersePhase.entering:
        return _EnteringPhase(
          key: const ValueKey('entering'),
          theme: exp.theme,
          reduced: reduced,
        );
      case VersePhase.revealing:
        return _RevealingPhase(
          key: const ValueKey('revealing'),
          phrases: isAmharic ? _phrasesAm! : _phrases!,
          reference: exp.scripture.reference,
          revealedCount: _revealedPhraseCount,
          reduced: reduced,
          isAmharic: isAmharic,
        );
      case VersePhase.resting:
        return _RestingPhase(
          key: const ValueKey('resting'),
          phrases: isAmharic ? _phrasesAm! : _phrases!,
          reference: exp.scripture.reference,
          theme: exp.theme,
          reduced: reduced,
          isAmharic: isAmharic,
        );
      case VersePhase.inviting:
        return _InvitingPhase(
          key: const ValueKey('inviting'),
          invitation: _invitation!,
          theme: exp.theme,
          reduced: reduced,
          onReceive: _handleReceive,
          hasReceived: _hasReceived,
          isAmharic: isAmharic,
        );
      case VersePhase.receiving:
        return _ReceivingPhase(
          key: const ValueKey('receiving'),
          theme: exp.theme,
          reduced: reduced,
        );
      case VersePhase.blessing:
        return _BlessingPhase(
          key: const ValueKey('blessing'),
          blessing: _blessing!,
          theme: exp.theme,
          reduced: reduced,
          isAmharic: isAmharic,
        );
      case VersePhase.complete:
        return _CompletePhase(
          key: const ValueKey('complete'),
          theme: exp.theme,
        );
    }
  }
}

class _EnteringPhase extends StatefulWidget {
  final ThemeConfig theme;
  final bool reduced;

  const _EnteringPhase({super.key, required this.theme, required this.reduced});

  @override
  State<_EnteringPhase> createState() => _EnteringPhaseState();
}

class _EnteringPhaseState extends State<_EnteringPhase>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    if (!widget.reduced) {
      _glowController.repeat(reverse: true);
    } else {
      _glowController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.theme.glowColor
                        .withValues(alpha: _glowAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Be still…',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 22,
            fontWeight: FontWeight.w300,
            color: widget.theme.textColor,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _RevealingPhase extends StatelessWidget {
  final List<String> phrases;
  final String reference;
  final int revealedCount;
  final bool reduced;
  final bool isAmharic;

  const _RevealingPhase({
    super.key,
    required this.phrases,
    required this.reference,
    required this.revealedCount,
    required this.reduced,
    this.isAmharic = false,
  });

  @override
  Widget build(BuildContext context) {
    final allRevealed = revealedCount >= phrases.length;
    final fontFamily = isAmharic ? 'NotoSansEthiopic' : 'CormorantGaramond';
    final phraseSize = isAmharic ? 24.0 : 22.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(phrases.length, (idx) {
          final visible = reduced || idx < revealedCount;
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: visible ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 500),
                offset: visible ? Offset.zero : const Offset(0, 0.15),
                child: Opacity(
                  opacity: visible ? 0.9 : 0.0,
                  child: Text(
                    phrases[idx],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: fontFamily,
                      fontSize: phraseSize,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 500),
          opacity: allRevealed ? 1.0 : 0.0,
          child: Text(
            reference,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _RestingPhase extends StatefulWidget {
  final List<String> phrases;
  final String reference;
  final ThemeConfig theme;
  final bool reduced;
  final bool isAmharic;

  const _RestingPhase({
    super.key,
    required this.phrases,
    required this.reference,
    required this.theme,
    required this.reduced,
    this.isAmharic = false,
  });

  @override
  State<_RestingPhase> createState() => _RestingPhaseState();
}

class _RestingPhaseState extends State<_RestingPhase>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (!widget.reduced) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.reduced) {
      return _buildContent(1.0);
    }
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Opacity(opacity: _pulseAnimation.value, child: child);
      },
      child: _buildContent(1.0),
    );
  }

  Widget _buildContent(double opacity) {
    final fontFamily = widget.isAmharic ? 'NotoSansEthiopic' : 'CormorantGaramond';
    final phraseSize = widget.isAmharic ? 24.0 : 22.0;

    return Opacity(
      opacity: opacity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.phrases.map((phrase) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  phrase,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: phraseSize,
                    height: 1.5,
                  ),
                ),
              )),
          const SizedBox(height: 24),
          Text(
            widget.reference,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvitingPhase extends StatefulWidget {
  final InvitationContent invitation;
  final ThemeConfig theme;
  final bool reduced;
  final VoidCallback onReceive;
  final bool hasReceived;
  final bool isAmharic;

  const _InvitingPhase({
    super.key,
    required this.invitation,
    required this.theme,
    required this.reduced,
    required this.onReceive,
    required this.hasReceived,
    this.isAmharic = false,
  });

  @override
  State<_InvitingPhase> createState() => _InvitingPhaseState();
}

class _InvitingPhaseState extends State<_InvitingPhase> {
  double _textOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500 + Random().nextInt(400)), () {
      if (!mounted) return;
      setState(() => _textOpacity = 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.invitation.am.isNotEmpty ? widget.invitation.am : widget.invitation.en;
    final fontFamily = widget.isAmharic ? 'NotoSansEthiopic' : 'CormorantGaramond';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: widget.reduced ? 1.0 : _textOpacity,
          curve: const Cubic(0.25, 0.1, 0.25, 1.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 20,
              height: 1.6,
              color: widget.theme.textColor.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _ReceiveButton(
          onTap: widget.hasReceived ? null : widget.onReceive,
          accentColor: widget.theme.accentColor,
          backgroundColor: widget.theme.backgroundColor,
          reduced: widget.reduced,
        ),
      ],
    );
  }
}

class _ReceiveButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Color accentColor;
  final Color backgroundColor;
  final bool reduced;

  const _ReceiveButton({
    super.key,
    this.onTap,
    required this.accentColor,
    required this.backgroundColor,
    required this.reduced,
  });

  @override
  State<_ReceiveButton> createState() => _ReceiveButtonState();
}

class _ReceiveButtonState extends State<_ReceiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              if (!widget.reduced) _scaleController.forward();
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              if (!widget.reduced) _scaleController.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () {
        if (!widget.reduced) _scaleController.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 15),
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? widget.accentColor.withValues(alpha: 0.5)
                : widget.accentColor,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            'I receive this word',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: widget.backgroundColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceivingPhase extends StatelessWidget {
  final ThemeConfig theme;
  final bool reduced;

  const _ReceivingPhase({super.key, required this.theme, required this.reduced});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: reduced
              ? const Duration(milliseconds: 200)
              : const Duration(milliseconds: 1200),
          curve: const Cubic(0.4, 0.0, 0.2, 1.0),
          builder: (context, value, child) {
            final amenOpacity = ((value - 0.3) / 0.7).clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + value * 2.0,
                  child: Opacity(
                    opacity: 1.0 - pow(value, 1.4),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            theme.accentColor.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Opacity(
                  opacity: amenOpacity,
                  child: Text(
                    'Amen',
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: theme.textColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BlessingPhase extends StatefulWidget {
  final BlessingContent blessing;
  final ThemeConfig theme;
  final bool reduced;
  final bool isAmharic;

  const _BlessingPhase({
    super.key,
    required this.blessing,
    required this.theme,
    required this.reduced,
    this.isAmharic = false,
  });

  @override
  State<_BlessingPhase> createState() => _BlessingPhaseState();
}

class _BlessingPhaseState extends State<_BlessingPhase>
    with SingleTickerProviderStateMixin {
  late AnimationController _blessingController;
  late Animation<double> _blessingAnimation;

  @override
  void initState() {
    super.initState();
    final blessDuration = Duration(milliseconds: 700 + Random().nextInt(200));
    _blessingController = AnimationController(
      vsync: this,
      duration: blessDuration,
    );
    _blessingAnimation = CurvedAnimation(
      parent: _blessingController,
      curve: const Cubic(0.25, 0.1, 0.25, 1.0),
    );
    if (!widget.reduced) {
      _blessingController.forward();
    } else {
      _blessingController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _blessingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.blessing.am.isNotEmpty ? widget.blessing.am : widget.blessing.en;
    final fontFamily = widget.isAmharic ? 'NotoSansEthiopic' : 'CormorantGaramond';

    if (widget.reduced) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 22,
              height: 1.6,
              color: widget.theme.textColor,
            ),
          ),
        ],
      );
    }

    return AnimatedBuilder(
      animation: _blessingAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 8.0 * (1.0 - _blessingAnimation.value)),
          child: Opacity(
            opacity: _blessingAnimation.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 22,
              height: 1.6,
              color: widget.theme.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletePhase extends StatelessWidget {
  final ThemeConfig theme;

  const _CompletePhase({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Until we meet again, dear one.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 18,
        color: theme.textColor.withValues(alpha: 0.6),
      ),
    );
  }
}

class _LoadingPhase extends StatelessWidget {
  const _LoadingPhase();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 0.8),
          duration: const Duration(milliseconds: 1500),
          builder: (context, value, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC8942E).withValues(alpha: value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC8942E).withValues(alpha: value * 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '✦',
                      style: TextStyle(
                        color: const Color(0xFFC8942E).withValues(alpha: value),
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Preparing...',
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 16,
                    color: const Color(0xFFC8942E).withValues(alpha: value),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorPhase extends StatelessWidget {
  final WidgetRef providerRef;

  const _ErrorPhase({
    required this.providerRef,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Come back soon, dear one.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 20,
                color: const Color(0xFFC8942E).withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => providerRef.invalidate(experienceProvider),
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFC8942E)),
              label: Text(
                'Return when you\'re ready',
                style: TextStyle(
                  color: const Color(0xFFC8942E).withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
