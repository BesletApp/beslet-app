import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/voice_journal/voice_journal_models.dart';
import '../../../core/ai/voice_journal/voice_journal_provider.dart';
import '../../../core/providers/ai_provider.dart';
import '../../../core/providers/journal_provider.dart';
import '../../../core/providers/voice_journal_provider.dart';
import '../../../core/speech/speech_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/widgets/gemini_key_dialog.dart';

/// Opens the Voice Journal sheet from Today's Journal. The sheet is the whole
/// flow: record → live transcript → (editable) transcript → AI organize →
/// editable organized sections → save to today's journal.
Future<void> showVoiceJournalSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    sheetAnimationStyle: AnimationStyle(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    ),
    builder: (_) => const VoiceJournalSheet(),
  );
}

enum _VjStep { record, transcript, organizing, review }

/// The AI-organized voice journal sheet.
///
/// The AI is an editor, not an author: it only organizes the reader's own
/// spoken words. The final organized journal is fully editable before it is
/// saved through the existing Today's Journal path — nothing in the existing
/// journal screen changes.
class VoiceJournalSheet extends ConsumerStatefulWidget {
  /// Optional injection for tests; production uses the real plugin gateway.
  final SpeechGateway? speechGateway;

  const VoiceJournalSheet({super.key, this.speechGateway});

  @override
  ConsumerState<VoiceJournalSheet> createState() => _VoiceJournalSheetState();
}

class _VoiceJournalSheetState extends ConsumerState<VoiceJournalSheet> {
  late final SpeechService _speech =
      SpeechService(widget.speechGateway ?? PluginSpeechGateway());

  _VjStep _step = _VjStep.record;
  bool _listening = false;
  bool _fallbackToEnglish = false;
  String _livePartial = '';
  String _transcript = '';
  SpeechFailure? _dictationFailure;
  bool _organizing = false;
  VoiceJournalUnavailability? _organizeFailure;
  bool _limitReached = false;
  String? _sessionId;
  bool _rawShown = false;
  final _transcriptController = TextEditingController();
  final Map<VoiceNoteSectionKind, TextEditingController> _sectionControllers = {};
  bool _notAvailable = false;

  static const List<VoiceNoteSectionKind> _canonicalOrder = [
    VoiceNoteSectionKind.whatHappened,
    VoiceNoteSectionKind.emotions,
    VoiceNoteSectionKind.spiritualMoments,
    VoiceNoteSectionKind.insights,
    VoiceNoteSectionKind.sentenceToRemember,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAvailability());
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    for (final c in _sectionControllers.values) {
      c.dispose();
    }
    _speech.stop();
    super.dispose();
  }

  bool get _isAm =>
      (Localizations.localeOf(context).languageCode == 'am') &&
      !_fallbackToEnglish;

  String get _localeId => _isAm ? SpeechService.amharicLocale : SpeechService.englishLocale;

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _checkAvailability() async {
    final locale = _isAm
        ? SpeechService.amharicLocale
        : SpeechService.englishLocale;
    final availability = await _speech.checkAvailability(locale);
    if (!mounted) return;
    final engineDown = !availability.engineAvailable;
    setState(() {
      _fallbackToEnglish = availability.requestedLocaleSupported == false &&
          _isAm &&
          availability.engineAvailable;
      _notAvailable = engineDown;
    });
  }

  Future<void> _startListening() async {
    if (_listening) return;
    setState(() {
      _listening = true;
      _dictationFailure = null;
      _livePartial = '';
    });
    SpeechSessionResult result;
    try {
      result = await _speech.dictate(
        localeId: _localeId,
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 20),
        onPartialText: (text, isFinal) {
          if (mounted && _listening) setState(() => _livePartial = text);
        },
      );
    } finally {
      if (mounted) setState(() => _listening = false);
    }
    if (!mounted) return;
    if (result.isAvailable) {
      _transcript = result.text;
      _transcriptController.text = result.text;
      setState(() => _step = _VjStep.transcript);
    } else {
      setState(() => _dictationFailure = result.failure);
    }
  }

  Future<String> _ensureSession() async {
    if (_sessionId != null) return _sessionId!;
    final notifier = ref.read(voiceJournalNotifierProvider.notifier);
    final id = await notifier.createSession(
      date: _today(),
      locale: _isAm ? 'am' : 'en',
      rawTranscript: capVoiceJournalTranscript(_transcript),
      status: 'recorded',
    );
    _sessionId = id;
    return id;
  }

  Future<void> _organize({bool bypassDisk = false}) async {
    if (_transcript.trim().isEmpty) return;
    final sessionId = await _ensureSession();
    final notifier = ref.read(voiceJournalNotifierProvider.notifier);
    setState(() {
      _organizing = true;
      _organizeFailure = null;
      _limitReached = false;
    });
    final request = VoiceJournalRequest(
      transcript: capVoiceJournalTranscript(_transcript),
      isAmharic: _isAm,
    );
    final service = await ref.read(voiceJournalServiceProvider.future);
    final result = bypassDisk
        ? await service.refresh(request, bypassDisk: true)
        : await service.organize(request);
    if (!mounted) return;
    setState(() {
      _organizing = false;
      if (result.isAvailable) {
        _rawShown = false;
        _sectionControllers.clear();
        for (final section in result.sections) {
          final c = TextEditingController(text: section.textFor(_isAm));
          _sectionControllers[section.kind] = c;
        }
        _step = _VjStep.review;
      } else if (result.limitReached) {
        _limitReached = true;
      } else {
        _organizeFailure = result.unavailability;
      }
    });
    await notifier.updateSession(
      id: sessionId,
      status: result.isAvailable
          ? 'organized'
          : 'failed',
      organizedContent: result.isAvailable
          ? _composeFinal(false)
          : null,
      errorReason: !result.isAvailable
          ? result.unavailability.name
          : null,
    );
  }

  String _composeFinal(bool includeRaw) {
    final l = AppLocalizations.of(context)!;
    final parts = <String>[];
    for (final kind in _canonicalOrder) {
      final controller = _sectionControllers[kind];
      final text = controller?.text.trim() ?? '';
      if (text.isEmpty) continue;
      parts.add('${_sectionLabel(l, kind)}\n$text');
    }
    final organized = parts.join('\n\n');
    if (includeRaw && _transcript.trim().isNotEmpty) {
      return '$organized\n\n${l.voiceJournalRawLabel}\n${_transcript.trim()}';
    }
    return organized;
  }

  String _sectionLabel(AppLocalizations l, VoiceNoteSectionKind kind) {
    switch (kind) {
      case VoiceNoteSectionKind.whatHappened:
        return l.voiceJournalWhatHappened;
      case VoiceNoteSectionKind.emotions:
        return l.voiceJournalEmotions;
      case VoiceNoteSectionKind.spiritualMoments:
        return l.voiceJournalSpiritualMoments;
      case VoiceNoteSectionKind.insights:
        return l.voiceJournalInsights;
      case VoiceNoteSectionKind.sentenceToRemember:
        return l.voiceJournalSentenceToRemember;
    }
  }

  Future<void> _saveToJournal() async {
    final text = _composeFinal(false);
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          _isAm ? 'ጽሑፉ ባዶ ነው' : 'The journal is empty',
          style: AppTextStyles.bodyMedium,
        ),
      ));
      return;
    }
    final current = (await ref.read(journalEntryProvider.future))?.content?.trim() ?? '';
    if (!mounted) return;
    if (current.isNotEmpty && current != text) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final l = AppLocalizations.of(ctx)!;
          final c = AppColors.of(ctx);
          return AlertDialog(
            backgroundColor: c.card,
            title: Text(l.voiceJournalReplaceTitle, style: AppTextStyles.labelLarge),
            content: Text(l.voiceJournalReplaceBody,
                style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.voiceJournalReplace),
              ),
            ],
          );
        },
      );
      if (replace != true || !mounted) return;
    }
    await ref.read(journalNotifierProvider.notifier).saveEntry(text);
    final notifier = ref.read(voiceJournalNotifierProvider.notifier);
    if (_sessionId != null) {
      await notifier.updateSession(id: _sessionId!, organizedContent: text);
      await notifier.markSaved(_sessionId!);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        _isAm ? 'የድምጽ ማስታወሻ ተቀምጧል' : 'Voice journal saved',
        style: AppTextStyles.bodyMedium,
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _saveDraft() async {
    final transcript = _transcript.trim();
    if (transcript.isEmpty) return;
    final current = (await ref.read(journalEntryProvider.future))?.content?.trim() ?? '';
    if (!mounted) return;
    final replace = current.isEmpty
        ? true
        : (await showDialog<bool>(
            context: context,
            builder: (ctx) {
              final l = AppLocalizations.of(ctx)!;
              final c = AppColors.of(ctx);
              return AlertDialog(
                backgroundColor: c.card,
                title: Text(l.voiceJournalReplaceTitle, style: AppTextStyles.labelLarge),
                content: Text(l.voiceJournalReplaceBody,
                    style: AppTextStyles.bodyMedium.copyWith(color: c.textSecondary)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(l.cancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text(l.voiceJournalReplace),
                  ),
                ],
              );
            },
          ) ??
          false);
    if (replace != true || !mounted) return;
    await ref.read(journalNotifierProvider.notifier).saveEntry(transcript);
    final notifier = ref.read(voiceJournalNotifierProvider.notifier);
    if (_sessionId != null) {
      await notifier.markSaved(_sessionId!);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        _isAm ? 'ረቂቅ ተቀምጧል' : 'Draft saved',
        style: AppTextStyles.bodyMedium,
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.of(context).pop();
  }

  Future<void> _addKeyAndRetry() async {
    final action = await showGeminiKeyDialog(context);
    if (!mounted) return;
    if (action == 'saved') {
      setState(() {
        _limitReached = false;
        _organizeFailure = null;
      });
      await _organize(bypassDisk: true);
    }
  }

  String _dictationFailureText(AppLocalizations l, SpeechFailure failure) {
    switch (failure) {
      case SpeechFailure.permissionDenied:
        return l.voiceJournalPermissionDenied;
      case SpeechFailure.noRecognitionEngine:
        return l.voiceJournalNoEngine;
      case SpeechFailure.languageNotSupported:
        return l.voiceJournalLanguageNotSupported;
      case SpeechFailure.audioUnavailable:
      case SpeechFailure.timedOut:
      case SpeechFailure.other:
        return l.voiceJournalNothingHeard;
    }
  }

  String _organizeFailureText(AppLocalizations l, VoiceJournalUnavailability reason) {
    switch (reason) {
      case VoiceJournalUnavailability.offline:
        return l.studyReasonOffline;
      case VoiceJournalUnavailability.rateLimited:
        return l.studyReasonRateLimited;
      case VoiceJournalUnavailability.timeout:
        return l.studyReasonTimeout;
      case VoiceJournalUnavailability.authInvalid:
        return l.studyReasonAuthInvalid;
      case VoiceJournalUnavailability.server:
        return l.studyReasonServer;
      case VoiceJournalUnavailability.contentRejected:
        return l.studyReasonContentRejected;
      case VoiceJournalUnavailability.tooLong:
        return l.voiceJournalTooLong;
      case VoiceJournalUnavailability.permissionDenied:
        return l.voiceJournalPermissionDenied;
      case VoiceJournalUnavailability.noRecognitionEngine:
        return l.voiceJournalNoEngine;
      case VoiceJournalUnavailability.languageNotSupported:
        return l.voiceJournalLanguageNotSupported;
      case VoiceJournalUnavailability.capped:
      case VoiceJournalUnavailability.none:
        return l.voiceJournalUnavailableTitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
          child: Row(children: [
            Text(l.voiceJournalTitle, style: AppTextStyles.labelLarge.copyWith(fontSize: 17)),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close, color: c.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]),
        ),
        Expanded(child: _buildBody(c, l)),
      ]),
    );
  }

  Widget _buildBody(ThemePalette c, AppLocalizations l) {
    switch (_step) {
      case _VjStep.record:
        return _buildRecordStep(c, l);
      case _VjStep.transcript:
        return _buildTranscriptStep(c, l);
      case _VjStep.organizing:
        return _buildOrganizing(c, l);
      case _VjStep.review:
        return _buildReviewStep(c, l);
    }
  }

  Widget _buildRecordStep(ThemePalette c, AppLocalizations l) {
    if (_notAvailable) {
      return _messageWithButton(
        c,
        Icons.mic_off_outlined,
        l.voiceJournalNoEngine,
        [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
        ],
      );
    }
    if (_fallbackToEnglish) {
      return _messageWithButton(
        c,
        Icons.language_outlined,
        l.voiceJournalLanguageNotSupported,
        [
          FilledButton.icon(
            onPressed: () {
              setState(() => _fallbackToEnglish = false);
              _checkAvailability();
            },
            icon: const Icon(Icons.record_voice_over_outlined, size: 18),
            label: Text(l.voiceJournalUseEnglish),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(children: [
        Text(
          l.voiceJournalRecordHint,
          textAlign: TextAlign.center,
          style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: AppSpacing.lg),
        GestureDetector(
          onTap: _listening ? null : _startListening,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _listening ? AppColors.primary : c.card,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: Icon(
              _listening ? Icons.graphic_eq : Icons.mic,
              size: 44,
              color: _listening ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          _listening ? l.voiceJournalListening : l.voiceJournalStartRecording,
          style: AppTextStyles.labelLarge.copyWith(color: c.textPrimary),
        ),
        if (_listening) ...[
          const SizedBox(height: AppSpacing.md),
          FilledButton.tonal(
            onPressed: () => _speech.stop(),
            child: Text(l.voiceJournalStop),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (_listening || _livePartial.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.voiceJournalLiveCaption,
                  style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
              const SizedBox(height: 6),
              Text(
                _livePartial.isEmpty ? l.voiceJournalNothingHeard : _livePartial,
                style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, height: 1.5),
              ),
            ]),
          ),
        ] else if (_dictationFailure != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border.withValues(alpha: 0.3)),
            ),
            child: Column(children: [
              Text(
                _dictationFailureText(l, _dictationFailure!),
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.voiceJournalRetry),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildTranscriptStep(ThemePalette c, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: TextField(
            controller: _transcriptController,
            maxLines: null,
            minLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, height: 1.6),
            onChanged: (v) => _transcript = v,
            decoration: InputDecoration(
              hintText: l.voiceJournalEmptyTranscript,
              hintStyle: TextStyle(color: c.textMuted),
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          OutlinedButton.icon(
            onPressed: () {
              _transcript = '';
              _transcriptController.clear();
              setState(() => _step = _VjStep.record);
            },
            icon: const Icon(Icons.graphic_eq, size: 18),
            label: Text(l.voiceJournalRecordAgain),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _transcript.trim().isEmpty ? null : _organize,
            child: Text(l.voiceJournalUseTranscript),
          ),
        ]),
      ]),
    );
  }

  Widget _buildOrganizing(ThemePalette c, AppLocalizations l) {
    if (_limitReached) {
      final hasKey = ref.read(userKeyPresentProvider).valueOrNull ?? false;
      return _messageWithButton(
        c,
        Icons.timer_outlined,
        l.voiceJournalLimitBody,
        [
          if (!hasKey)
            FilledButton(
              onPressed: _addKeyAndRetry,
              child: Text(l.voiceJournalLimitAddKey),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
        ],
      );
    }
    if (_organizeFailure != null) {
      final hasKey = ref.read(userKeyPresentProvider).valueOrNull ?? false;
      final showKey = !hasKey &&
          (_organizeFailure == VoiceJournalUnavailability.rateLimited ||
              _organizeFailure == VoiceJournalUnavailability.authInvalid ||
              _organizeFailure == VoiceJournalUnavailability.server ||
              _organizeFailure == VoiceJournalUnavailability.timeout);
      return _messageWithButton(
        c,
        Icons.info_outline,
        _organizeFailureText(l, _organizeFailure!),
        [
          if (_organizeFailure == VoiceJournalUnavailability.offline || !_organizing)
            FilledButton.icon(
              onPressed: _saveDraft,
              icon: const Icon(Icons.edit_note, size: 18),
              label: Text(l.voiceJournalSaveDraft),
            ),
          TextButton.icon(
            onPressed: _organize,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.voiceJournalRetry),
          ),
          if (showKey)
            TextButton(
              onPressed: _addKeyAndRetry,
              child: Text(l.voiceJournalLimitAddKey),
            ),
        ],
      );
    }
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(height: 16),
        Text(l.voiceJournalOrganizing,
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildReviewStep(ThemePalette c, AppLocalizations l) {
    final organized = _composeFinal(false);
    final editable = organized.trim().isNotEmpty;
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.voiceJournalReviewTitle, style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(l.voiceJournalOrganizeNote,
                style: TextStyle(color: c.textMuted, fontSize: 12, height: 1.4)),
            const SizedBox(height: AppSpacing.md),
            for (final kind in _canonicalOrder)
              if (_sectionControllers[kind]?.text.isNotEmpty == true) ...[
                Text(_sectionLabel(l, kind),
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border.withValues(alpha: 0.3)),
                  ),
                  child: TextField(
                    controller: _sectionControllers[kind],
                    maxLines: null,
                    minLines: 2,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, height: 1.6),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            TextButton.icon(
              onPressed: () => setState(() => _rawShown = !_rawShown),
              icon: Icon(_rawShown ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              label: Text(_rawShown ? l.voiceJournalHideRaw : l.voiceJournalShowRaw),
            ),
            if (_rawShown) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border.withValues(alpha: 0.3)),
                ),
                child: Text(_transcript.trim(),
                    style: TextStyle(color: c.textMuted, fontSize: 12.5, height: 1.5)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => setState(() => _step = _VjStep.transcript),
              icon: const Icon(Icons.graphic_eq, size: 18),
              label: Text(l.voiceJournalRecordAgain),
            ),
            const SizedBox(height: AppSpacing.md),
          ]),
        ),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: editable ? _saveToJournal : null,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: Text(l.voiceJournalSaveEntry),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _messageWithButton(ThemePalette c, IconData icon, String message, List<Widget> buttons) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 40, color: c.textMuted.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5)),
            const SizedBox(height: AppSpacing.lg),
            for (final button in buttons) ...[
              button,
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}