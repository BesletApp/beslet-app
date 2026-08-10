import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai_key_store.dart';
import '../../secrets.dart';
import 'gemini_study_backend.dart';
import 'study_backend.dart';
import 'study_fallback_backend.dart';
import 'study_local_bank.dart';
import 'study_service.dart';
import 'study_usage_gate.dart';

/// The curated study bank, loaded once and kept alive.
final studyLocalBankProvider = FutureProvider<StudyLocalBank>((ref) {
  return StudyLocalBank.load();
});

/// The Study orchestrator. A FutureProvider because the bank is loaded from
/// the bundle; results are cached in SharedPreferences behind the same key
/// the panel derives from the request.
///
/// The chain (in `StudyFallbackBackend`):
///   1. curated offline bank — free, unlimited, canon-verified;
///   2. AI model — only for unbanked passages, when online, and within the
///      daily AI cap. Banked passages never touch the network. The UI never
///      sees Gemini, keys, models, or prompts.
final studyServiceProvider = FutureProvider<StudyService>((ref) async {
  final bank = await ref.watch(studyLocalBankProvider.future);
  final keyStore = AiKeyStore();
  final gemini = GeminiStudyBackend(
    transport: buildGeminiTransport(
      bundledKey: defaultGeminiKey,
      userKeyProvider: keyStore.readUserKey,
    ),
  );
  final backend = StudyFallbackBackend(
    local: LocalStudyBackend(bank),
    ai: gemini,
    isOnline: () async {
      try {
        final result = await Connectivity().checkConnectivity();
        return result.isNotEmpty;
      } catch (_) {
        return false;
      }
    },
    mayUseAi: () => StudyUsageGate.mayStudy(DateTime.now()),
    recordAiUse: () => StudyUsageGate.record(DateTime.now()),
  );
  return StudyService(
    backend: backend,
    readCache: (key) async =>
        (await SharedPreferences.getInstance()).getString(key),
    writeCache: (key, value) async =>
        (await SharedPreferences.getInstance()).setString(key, value),
  );
});