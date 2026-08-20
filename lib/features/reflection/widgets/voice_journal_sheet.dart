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
import '../../../core/voice/recording_adapter.dart';
import '../../../core/voice/transcription_service.dart';
import '../../../core/voice/translation_service.dart';
import '../../../core/voice/voice_ai_transports.dart';
import '../../../core/voice/voice_capability_probe.dart';
import '../../../core/voice/voice_controller.dart';
import '../../../core/voice/voice_models.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/widgets/gemini_key_dialog.dart';

/// Opens the Voice Journal sheet from Today's Journal. The sheet is the whole
/// flow: record → transcribe → (editable) transcript → optional translate →
/// AI organize → editable organized sections → save to today's journal.
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
/// spoken words. Recording is real audio captured to a temp file, transcribed
/// by the AI backend (Gemini), and optionally translated — everything is
/// retryable without re-recording.
class VoiceJournalSheet extends ConsumerStatefulWidget {
  /// Optional injection for tests; production uses the real recorder + Gemini.
  final SpeechGateway? speechGateway;
  final RecordingAdapter? recordingAdapter;
  final TranscriptionService? transcriptionService;
  final TranslationService? translationService;

  const VoiceJournalSheet({
    super.key,
    this.speechGateway,
    this.recordingAdapter,
    this.transcriptionService,
    this.translationService,
  });

  @override
  ConsumerState<VoiceJournalSheet> createState() => _VoiceJournalSheetState();
}

class _VoiceJournalSheetState extends ConsumerState<VoiceJournalSheet> {
  late final RecordingAdapter _adapter =
      widget.recordingAdapter ?? RecordRecorderAdapter();
  late final VoiceController _voice = VoiceController(
    recorder: _adapter,
    transcription: widget.transcriptionService ?? _defaultTranscription(),
    translator: widget.translationService ??
        GeminiTranslationService(transport: buildGeminiTextTransport()),
    probe: VoiceCapabilityProbe(adapter: _adapter),
  );

  _VjStep _step = _VjStep.record;
  String _transcript = '';
  bool _organizing = false;
  VoiceJournalUnavailability? _organizeFailure;
  bool _limitReached = false;
  String? _sessionId;
  bool _rawShown = false;
  final _transcriptController = TextEditingController();
  final Map<VoiceNoteSectionKind, TextEditingController> _sectionControllers = {};
  Timer? _ticker;

  static const List<VoiceNoteSectionKind> _canonicalOrder = [
    VoiceNoteSectionKind.whatHappened,
    VoiceNoteSectionKind.emotions,
    VoiceNoteSectionKind.spiritualMoments,
    VoiceNoteSectionKind.insights,
    VoiceNoteSectionKind.sentenceToRemember,
  ];

  TranscriptionService _defaultTranscription() {
    final gateway = widget.speechGateway;
    if (gateway != null) {
      final speech = SpeechService(gateway);
      return StreamingFallbackTranscriptionService(
        dictate: () async {
          final result = await speech.dictate(
            localeId: _localeId,
            listenFor: const Duration(seconds: 120),
            pauseFor: const Duration(seconds: 20),
          );
          if (result.isAvailable) {
            return VoiceTranscript(result.text, detectedLanguage: _isAm ? 'am' : 'en');
          }
          throw VoicePipelineException(
            _speechFailureToVoiceError(result.failure ?? SpeechFailure.other),
            result.failure?.name ?? 'dictation failed',
          );
        },
      );
    }
    return GeminiTranscriptionService(transport: buildGeminiAudioTransport());
  }

  @override
  void initState() {
    super.initState();
    _voice.addListener(_onVoiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_probeOnly());
    });
  }

  @override
  void dispose() {
    _stopTicker();
    _transcriptController.dispose();
    for (final c in _sectionControllers.values) {
      c.dispose();
    }
    unawaited(_voice.cancel());
    _voice.dispose();
    super.dispose();
  }

  bool get _isAm =>
      (Localizations.localeOf(context).languageCode == 'am');

  String get _localeId => _isAm ? SpeechService.amharicLocale : SpeechService.englishLocale;

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  void _onVoiceChanged() {
    if (!mounted) return;
    final t = _voice.transcript;
    if (t != null) {
      _transcript = t.text;
      _transcriptController.text = t.text;
      if (_step == _VjStep.record) {
        _step = _VjStep.transcript;
      }
    }
    if (_voice.isRecording) {
      _ensureTicker();
    } else {
      _stopTicker();
    }
    setState(() {});
  }

  void _ensureTicker() {
    if (_ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _ticker?.cancel();
        _ticker = null;
        return;
      }
      setState(() {});
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> _probeOnly() async {
    try {
      await _voice.probe.probe();
    } catch (_) {}
  }

  Future<void> _startRecording() async {
    _stopTicker();
    if (_voice.phase != VoicePhase.idle) {
      _voice.clear();
    }
    _transcript = '';
    _transcriptController.clear();
    setState(() => _step = _VjStep.record);
    await _voice.start();
  }

  Future<void> _stopRecording() async {
    await _voice.stop();
    _stopTicker();
  }

  Future<void> _cancelRecording() async {
    await _voice.cancel();
    _stopTicker();
    setState(() {});
  }

  Future<void> _retryTranscription() async {
    await _voice.retryTranscription();
    setState(() {});
  }

  VoiceError _speechFailureToVoiceError(SpeechFailure failure) {
    switch (failure) {
      case SpeechFailure.permissionDenied:
        return VoiceError.permissionDenied;
      case SpeechFailure.noRecognitionEngine:
        return VoiceError.recordingUnavailable;
      case SpeechFailure.languageNotSupported:
        return VoiceError.transcriptionFailed;
      case SpeechFailure.audioUnavailable:
        return VoiceError.microphoneUnavailable;
      case SpeechFailure.timedOut:
        return VoiceError.timeout;
      case SpeechFailure.other:
        return VoiceError.unknown;
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
      status: result.isAvailable ? 'organized' : 'failed',
      organizedContent:
          result.isAvailable ? _composeFinal(false) : null,
      errorReason: !result.isAvailable ? result.unavailability.name : null,
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

  String _organizeFailureText(
      AppLocalizations l, VoiceJournalUnavailability reason) {
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
        return l.voicePermissionDenied;
      case VoiceJournalUnavailability.noRecognitionEngine:
        return l.voiceRecordingUnavailable;
      case VoiceJournalUnavailability.languageNotSupported:
        return l.voiceTranscriptionFailed;
      case VoiceJournalUnavailability.capped:
      case VoiceJournalUnavailability.none:
        return l.voiceJournalUnavailableTitle;
    }
  }

  String _errorText(AppLocalizations l, VoiceError err) {
    switch (err) {
      case VoiceError.permissionDenied:
        return l.voicePermissionDenied;
      case VoiceError.permissionPermanentlyDenied:
        return l.voicePermissionPermanentlyDenied;
      case VoiceError.microphoneUnavailable:
        return l.voiceMicrophoneUnavailable;
      case VoiceError.microphoneInUse:
        return l.voiceMicrophoneInUse;
      case VoiceError.insecureContext:
        return l.voiceInsecureContext;
      case VoiceError.browserRestricted:
        return l.voiceBrowserRestricted;
      case VoiceError.recordingUnavailable:
        return l.voiceRecordingUnavailable;
      case VoiceError.emptyAudio:
        return l.voiceEmptyAudio;
      case VoiceError.transcriptionFailed:
        return l.voiceTranscriptionFailed;
      case VoiceError.network:
        return l.voiceNetwork;
      case VoiceError.authOrConfig:
        return l.voiceAuthOrConfig;
      case VoiceError.timeout:
        return l.voiceTimeout;
      case VoiceError.translationFailed:
        return l.voiceTranslationUnavailable;
      case VoiceError.unknown:
        return l.voiceUnknown;
    }
  }

  String _formatElapsed(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
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
    final err = _voice.error;
    if (err != null) return _buildErrorStep(c, l, err);
    final phase = _voice.phase;
    if (phase == VoicePhase.requestingPermission) {
      return _buildProgressStep(c, l, l.voicePermissionRequesting);
    }
    if (phase == VoicePhase.transcribing) {
      return _buildProgressStep(c, l, l.voiceTranscribing);
    }
    if (phase == VoicePhase.translating) {
      return _buildProgressStep(c, l, l.voiceTranslating);
    }
    final recording = _voice.isRecording;
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
          onTap: recording ? null : _startRecording,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: recording ? AppColors.primary : c.card,
              border: Border.all(
                color: recording ? Colors.redAccent : AppColors.primary,
                width: 2,
              ),
            ),
            child: Icon(
              recording ? Icons.stop_circle_outlined : Icons.mic,
              size: 44,
              color: recording ? Colors.white : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          recording ? _formatElapsed(_voice.elapsed) : l.voiceJournalStartRecording,
          style: AppTextStyles.labelLarge.copyWith(color: c.textPrimary),
        ),
        if (recording) ...[
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ((_voice.level + 60).clamp(0.0, 60.0)) / 60.0,
              minHeight: 6,
              backgroundColor: c.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: _stopRecording,
                icon: const Icon(Icons.stop, size: 18),
                label: Text(l.voiceStopRecording),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _cancelRecording,
                icon: const Icon(Icons.close, size: 18),
                label: Text(l.voiceCancelRecording),
              ),
            ],
          ),
        ],
      ]),
    );
  }

  Widget _buildProgressStep(ThemePalette c, AppLocalizations l, String message) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(height: 16),
        Text(message, style: TextStyle(color: c.textSecondary, fontSize: 13)),
      ]),
    );
  }

  Widget _buildErrorStep(ThemePalette c, AppLocalizations l, VoiceError err) {
    final icon = switch (err) {
      VoiceError.permissionPermanentlyDenied => Icons.settings,
      VoiceError.permissionDenied => Icons.mic_off_outlined,
      VoiceError.microphoneUnavailable => Icons.mic_off_outlined,
      VoiceError.microphoneInUse => Icons.headset_off_outlined,
      VoiceError.insecureContext => Icons.lock_outline,
      VoiceError.browserRestricted => Icons.public_off_outlined,
      VoiceError.recordingUnavailable => Icons.record_voice_over_outlined,
      VoiceError.emptyAudio => Icons.mic_none_outlined,
      VoiceError.transcriptionFailed => Icons.graphic_eq,
      VoiceError.network => Icons.wifi_off_outlined,
      VoiceError.authOrConfig => Icons.key_off_outlined,
      VoiceError.timeout => Icons.timer_outlined,
      VoiceError.translationFailed => Icons.translate,
      VoiceError.unknown => Icons.error_outline,
    };
    return _messageWithButton(c, icon, _errorText(l, err), _errorButtons(l, err));
  }

  List<Widget> _errorButtons(AppLocalizations l, VoiceError err) {
    switch (err) {
      case VoiceError.permissionPermanentlyDenied:
        return [
          FilledButton.icon(
            onPressed: () async {
              await _voice.openSettings();
            },
            icon: const Icon(Icons.settings, size: 18),
            label: Text(l.voiceOpenSettings),
          ),
          TextButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.voiceJournalRetry),
          ),
        ];
      case VoiceError.transcriptionFailed:
      case VoiceError.network:
      case VoiceError.timeout:
      case VoiceError.authOrConfig:
        return [
          FilledButton.icon(
            onPressed: _retryTranscription,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.voiceRetryTranscription),
          ),
          TextButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.mic, size: 18),
            label: Text(l.voiceJournalRecordAgain),
          ),
        ];
      default:
        return [
          FilledButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.voiceJournalRetry),
          ),
        ];
    }
  }

  Widget _buildTranscriptStep(ThemePalette c, AppLocalizations l) {
    final translation = _voice.translation;
    final transErr = _voice.translationError;
    final translating = _voice.phase == VoicePhase.translating;
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _transcriptController,
              maxLines: null,
              minLines: 6,
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
            const SizedBox(height: AppSpacing.md),
            if (translating)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 10),
                    Text(l.voiceTranslating,
                        style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  ],
                ),
              )
            else if (translation != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.voiceYouSaid,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(_transcript.trim(),
                      style: TextStyle(color: c.textMuted, fontSize: 13, height: 1.5)),
                  const SizedBox(height: 12),
                  Text(l.voiceTranslationCaption,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(translation.text,
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, height: 1.6)),
                ]),
              ),
            ] else if (transErr != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Text(l.voiceTranslationUnavailable,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.textSecondary, fontSize: 13)),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => _voice.retryTranslation(text: _transcript),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l.voiceRetryTranslation),
                  ),
                ]),
              ),
            ] else
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed:
                      _transcript.trim().isEmpty ? null : () => _voice.translate(text: _transcript),
                  icon: const Icon(Icons.translate, size: 18),
                  label: Text(l.voiceTranslate),
                ),
              ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        child: Row(children: [
          OutlinedButton.icon(
            onPressed: _startRecording,
            icon: const Icon(Icons.graphic_eq, size: 18),
            label: Text(l.voiceJournalRecordAgain),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _transcript.trim().isEmpty ? null : _organize,
            child: Text(l.voiceJournalUseTranscript),
          ),
        ]),
      ),
    ]);
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

  Widget _messageWithButton(
      ThemePalette c, IconData icon, String message, List<Widget> buttons) {
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