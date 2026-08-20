import 'package:flutter/foundation.dart';

import 'delve_models.dart';

/// A snapshot of the last deep-study attempt's runtime path. This is
/// observability only — it never changes behavior — and it mirrors the Study
/// layer's recorder so the two gates stay independent and readable.
class DelveDiagnostics extends ChangeNotifier {
  DelveDiagnostics._();

  /// The single shared recorder. Safe to call from anywhere in the deep-study
  /// chain.
  static final DelveDiagnostics instance = DelveDiagnostics._();

  String? keySource; // 'user' | 'bundled' | 'none'
  int? keyLength;
  DelveUnavailability? failureReason;
  String? failureDetail;
  String? httpStatus; // e.g. '400', '429', 'timeout'
  String? payloadSnippet; // first chars of a rejected AI payload
  bool? cacheHit;
  DateTime? lastAttemptAt;

  void record({
    String? keySource,
    int? keyLength,
    DelveUnavailability? failureReason,
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