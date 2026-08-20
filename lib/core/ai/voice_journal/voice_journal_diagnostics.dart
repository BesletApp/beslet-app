import 'package:flutter/foundation.dart';

import 'voice_journal_models.dart';

/// A snapshot of the last voice-journal attempt's runtime path. This is
/// observability only — it never changes behavior — and mirrors the Study and
/// Delve layers' recorders so each gate stays independent and readable.
class VoiceJournalDiagnostics extends ChangeNotifier {
  VoiceJournalDiagnostics._();

  /// The single shared recorder. Safe to call from anywhere in the chain.
  static final VoiceJournalDiagnostics instance = VoiceJournalDiagnostics._();

  String? keySource; // 'user' | 'bundled' | 'none'
  int? keyLength;
  VoiceJournalUnavailability? failureReason;
  String? failureDetail;
  String? httpStatus;
  String? payloadSnippet;
  bool? cacheHit;
  DateTime? lastAttemptAt;

  void record({
    String? keySource,
    int? keyLength,
    VoiceJournalUnavailability? failureReason,
    String? failureDetail,
    String? httpStatus,
    String? payloadSnippet,
    bool? cacheHit,
  }) {
    this.keySource = keySource;
    this.keyLength = keyLength;
    this.failureReason = failureReason;
    this.failureDetail = failureDetail;
    this.httpStatus = httpStatus;
    this.payloadSnippet = payloadSnippet;
    this.cacheHit = cacheHit;
    lastAttemptAt = DateTime.now();
    notifyListeners();
  }

  void recordCacheHit(bool hit) {
    cacheHit = hit;
    lastAttemptAt = DateTime.now();
    notifyListeners();
  }

  void reset() {
    keySource = null;
    keyLength = null;
    failureReason = null;
    failureDetail = null;
    httpStatus = null;
    payloadSnippet = null;
    cacheHit = null;
    lastAttemptAt = null;
    notifyListeners();
  }
}