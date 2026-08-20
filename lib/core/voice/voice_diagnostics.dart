import 'dart:developer' as developer;

/// Central, in-memory record of everything the voice pipeline observed. Every
/// stage writes here so a support session can reconstruct what happened without
/// ever logging raw audio bytes or API keys.
class VoiceDiagnostics {
  static final VoiceDiagnostics instance = VoiceDiagnostics._();

  VoiceDiagnostics._();

  String? phase;
  String? permissionStatus;
  bool? micDetected;
  List<String> supportedMimeTypes = const [];
  String? selectedMimeType;
  String? recordStartedAt;
  String? recordStoppedAt;
  int? recordedBytes;
  int? recordedDurationMs;
  bool? transcriptionOk;
  int? transcriptionMs;
  String? transcriptionError;
  bool? translationOk;
  int? translationMs;
  String? translationError;
  String? lastError;
  String? lastTechnicalError;

  void reset() {
    phase = null;
    permissionStatus = null;
    micDetected = null;
    supportedMimeTypes = const [];
    selectedMimeType = null;
    recordStartedAt = null;
    recordStoppedAt = null;
    recordedBytes = null;
    recordedDurationMs = null;
    transcriptionOk = null;
    transcriptionMs = null;
    transcriptionError = null;
    translationOk = null;
    translationMs = null;
    translationError = null;
    lastError = null;
    lastTechnicalError = null;
  }

  void record({
    String? phase,
    String? permissionStatus,
    bool? micDetected,
    List<String>? supportedMimeTypes,
    String? selectedMimeType,
    String? recordStartedAt,
    String? recordStoppedAt,
    int? recordedBytes,
    int? recordedDurationMs,
    bool? transcriptionOk,
    int? transcriptionMs,
    String? transcriptionError,
    bool? translationOk,
    int? translationMs,
    String? translationError,
    String? lastError,
    String? lastTechnicalError,
  }) {
    if (phase != null) this.phase = phase;
    if (permissionStatus != null) this.permissionStatus = permissionStatus;
    if (micDetected != null) this.micDetected = micDetected;
    if (supportedMimeTypes != null) this.supportedMimeTypes = supportedMimeTypes;
    if (selectedMimeType != null) this.selectedMimeType = selectedMimeType;
    if (recordStartedAt != null) this.recordStartedAt = recordStartedAt;
    if (recordStoppedAt != null) this.recordStoppedAt = recordStoppedAt;
    if (recordedBytes != null) this.recordedBytes = recordedBytes;
    if (recordedDurationMs != null) this.recordedDurationMs = recordedDurationMs;
    if (transcriptionOk != null) this.transcriptionOk = transcriptionOk;
    if (transcriptionMs != null) this.transcriptionMs = transcriptionMs;
    if (transcriptionError != null) this.transcriptionError = transcriptionError;
    if (translationOk != null) this.translationOk = translationOk;
    if (translationMs != null) this.translationMs = translationMs;
    if (translationError != null) this.translationError = translationError;
    if (lastError != null) this.lastError = lastError;
    if (lastTechnicalError != null) this.lastTechnicalError = lastTechnicalError;
    developer.log(
      'voice: ${phase ?? _summarise()}',
      name: 'voice',
    );
  }

  String _summarise() {
    final parts = <String>[
      if (permissionStatus != null) 'permission=$permissionStatus',
      if (selectedMimeType != null) 'mime=$selectedMimeType',
      if (recordedDurationMs != null) 'ms=$recordedDurationMs',
      if (recordedBytes != null) 'bytes=$recordedBytes',
      if (transcriptionOk != null) 'asr=${transcriptionOk! ? 'ok' : 'fail'}',
      if (translationOk != null) 'translate=${translationOk! ? 'ok' : 'fail'}',
      if (lastError != null) 'error=$lastError',
    ];
    return parts.isEmpty ? 'no activity' : parts.join(', ');
  }

  String toDebugString() {
    final lines = <String>[
      'Phase: ${phase ?? '-'}',
      'Permission: ${permissionStatus ?? '-'}',
      'Mic detected: ${micDetected ?? '-'}',
      'Supported MIME: ${supportedMimeTypes.isEmpty ? '-' : supportedMimeTypes.join(', ')}',
      'Selected MIME: ${selectedMimeType ?? '-'}',
      'Recorded: ${recordedStartedLabel()}',
      'Transcription: ${transcriptionLabel()}',
      'Translation: ${translationLabel()}',
      'Last error: ${lastError ?? '-'}',
      if (lastTechnicalError != null) 'Detail: $lastTechnicalError',
    ];
    return lines.join('\n');
  }

String recordedStartedLabel() {
    if (recordStartedAt == null) return '-';
    final stopped = recordStoppedAt ?? '-';
    final ms = recordedDurationMs != null ? '${recordedDurationMs}ms' : '-';
    final bytes = recordedBytes != null ? '$recordedBytes bytes' : '-';
    return '$recordStartedAt \u2192 $stopped ($ms, $bytes)';
  }

  String transcriptionLabel() {
    if (transcriptionOk == null) return '-';
    final ms = transcriptionMs != null ? ' in ${transcriptionMs}ms' : '';
    return transcriptionOk! ? 'ok$ms' : 'failed (${transcriptionError ?? '-'})';
  }

  String translationLabel() {
    if (translationOk == null) return '-';
    final ms = translationMs != null ? ' in ${translationMs}ms' : '';
    return translationOk! ? 'ok$ms' : 'failed (${translationError ?? '-'})';
  }
}