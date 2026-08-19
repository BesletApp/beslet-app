import 'package:flutter/foundation.dart';

import 'study_models.dart';

/// A snapshot of the last study attempt's runtime path. This is observability
/// only — it never changes behavior — and it exists so a reader (or the
/// settings screen) can see exactly which step of the AI request failed
/// instead of only the friendly banner. Set from across the study chain and
/// surfaced in Settings; also written to the log so it can be captured with
/// `adb logcat`.
class StudyDiagnostics extends ChangeNotifier {
  StudyDiagnostics._();

  /// The single shared recorder. Safe to call from anywhere in the study chain.
  static final StudyDiagnostics instance = StudyDiagnostics._();

  String? keySource; // 'user' | 'bundled' | 'none'
  int? keyLength;
  StudyUnavailability? failureReason;
  String? failureDetail;
  String? httpStatus; // e.g. '400', '429', 'timeout'
  String? payloadSnippet; // first chars of a rejected AI payload
  bool? cacheHit;
  DateTime? lastAttemptAt;

  void record({
    String? keySource,
    int? keyLength,
    StudyUnavailability? failureReason,
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