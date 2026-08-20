import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai_key_store.dart';
import '../../secrets.dart';
import 'voice_journal_backend.dart';
import 'voice_journal_service.dart';
import 'voice_journal_usage_gate.dart';
import 'voice_journal_validator.dart';

/// The "Voice Journal" orchestrator. A FutureProvider because underlying setup
/// is async; organized journals are cached in SharedPreferences behind the key
/// the service derives from the exact transcript.
///
/// The chain (in `VoiceJournalService`):
///   1. memory + disk cache — re-organizing the same transcript is served
///      instantly and never re-runs the backend;
///   2. transcript cap — a runaway transcript fails honestly;
///   3. connectivity gate — a definitive "no interface" fails with a clear
///      reason instead of silently spending the key;
///   4. usage gate — the free daily voice-journal allowance, skipped entirely
///      when the reader has connected their own Gemini key;
///   5. AI backend — validated by `VoiceJournalValidator` before anything
///      renders.
///
/// There is intentionally no offline fallback: organizing is an on-demand AI
/// request, and its failure reason is always surfaced — never masked as
/// content.
final voiceJournalServiceProvider = FutureProvider<VoiceJournalService>((ref) async {
  final keyStore = AiKeyStore();
  final backend = VoiceJournalBackend(
    transport: buildVoiceJournalTransport(
      bundledKey: defaultGeminiKey,
      userKeyProvider: keyStore.readUserKey,
    ),
    validator: const VoiceJournalValidator(),
  );
  return VoiceJournalService(
    backend: backend,
    isOnline: () async {
      try {
        final result = await Connectivity().checkConnectivity();
        if (result.isEmpty) return true;
        return result.any((c) => c != ConnectivityResult.none);
      } catch (_) {
        return true;
      }
    },
    mayOrganize: () async =>
        (await _hasUserKey(keyStore)) ||
        (await VoiceJournalUsageGate.mayOrganize(DateTime.now())),
    recordVoiceJournalUse: () async {
      if (!(await _hasUserKey(keyStore))) {
        await VoiceJournalUsageGate.record(DateTime.now());
      }
    },
    readCache: (key) async =>
        (await SharedPreferences.getInstance()).getString(key),
    writeCache: (key, value) async =>
        (await SharedPreferences.getInstance()).setString(key, value),
    removeCache: (key) async =>
        (await SharedPreferences.getInstance()).remove(key),
  );
});

/// Whether the reader has connected their own Gemini key. A personal key
/// bypasses the app's free daily voice-journal allowance entirely.
Future<bool> _hasUserKey(AiKeyStore keyStore) async {
  try {
    final k = await keyStore.readUserKey();
    return k != null && k.trim().isNotEmpty;
  } catch (_) {
    return false;
  }
}