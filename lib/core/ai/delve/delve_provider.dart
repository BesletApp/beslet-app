import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai_key_store.dart';
import '../../secrets.dart';
import '../study/study_provider.dart';
import 'delve_backend.dart';
import 'delve_service.dart';
import 'delve_usage_gate.dart';
import 'delve_validator.dart';

/// The deterministic canon shared with the Study layer, reused read-only so the
/// deep study's cross-references pass the exact same gate as the Study note.
final delveCanonProvider = studyCanonProvider;

/// The "Delve Deeper" orchestrator. A FutureProvider because the canon is
/// loaded from the bundle; deep results are cached in SharedPreferences behind
/// the same key the panel derives from the request.
///
/// The chain (in `DelveService`):
///   1. memory + disk cache — a repeated deep study of the same passage is
///      served instantly and never re-runs the backend;
///   2. connectivity gate — a definitive "no interface" fails with a clear
///      reason instead of silently spending the key;
///   3. usage gate — the free daily deep-study allowance, skipped entirely
///      when the reader has connected their own Gemini key;
///   4. AI backend — validated by `DelveValidator` before anything renders.
///
/// There is intentionally no offline fallback: a deep study is an on-demand AI
/// request, and its failure reason is always surfaced — never masked as
/// content.
final delveServiceProvider = FutureProvider<DelveService>((ref) async {
  final canon = await ref.watch(delveCanonProvider.future);
  final keyStore = AiKeyStore();
  final backend = DelveBackend(
    transport: buildDelveTransport(
      bundledKey: defaultGeminiKey,
      userKeyProvider: keyStore.readUserKey,
    ),
    validator: DelveValidator(canon: canon),
  );
  return DelveService(
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
    mayDelve: () async =>
        (await _hasUserKey(keyStore)) ||
        (await DelveUsageGate.mayDelve(DateTime.now())),
    recordDelveUse: () async {
      if (!(await _hasUserKey(keyStore))) {
        await DelveUsageGate.record(DateTime.now());
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
/// bypasses the app's free daily deep-study allowance entirely.
Future<bool> _hasUserKey(AiKeyStore keyStore) async {
  try {
    final k = await keyStore.readUserKey();
    return k != null && k.trim().isNotEmpty;
  } catch (_) {
    return false;
  }
}