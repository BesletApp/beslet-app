import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_backend.dart';
import '../ai/ai_boundary.dart';
import '../ai/ai_assembler.dart';
import '../ai/ai_content.dart';
import '../ai/ai_key_store.dart';
import '../ai/ai_service.dart';
import '../ai/ai_validator.dart';
import '../database/app_database.dart';
import '../secrets.dart';
import 'database_provider.dart';
import 'daily_flow_provider.dart';
import 'streak_provider.dart';
import 'user_provider.dart';

/// The optional user-supplied Google AI key lives in the OS keychain.
final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());

/// The curated content bank, loaded once and kept alive.
final aiContentBankProvider = FutureProvider<AiContentBank>((ref) async {
  return AiContentBank.load();
});

/// The Quiet Guide orchestrator. A FutureProvider because the bank is loaded
/// from the bundle; the moments that use it are all async anyway.
final aiServiceProvider = FutureProvider<AiService>((ref) async {
  final bank = await ref.watch(aiContentBankProvider.future);
  final db = ref.watch(databaseProvider);
  final keyStore = ref.watch(aiKeyStoreProvider);

  return AiService(
    bank: bank,
    gate: const AiBoundaryGate(),
    assembler: const AiContextAssembler(),
    validator: AiOutputValidator(bank),
    local: LocalRuleBackend(bank),
    gemini: GeminiBackend(
      bank: bank,
      bundledKey: defaultGeminiKey,
      userKeyProvider: () => keyStore.readUserKey(),
    ),
    momentCountFor: ({required dayKey}) async {
      final rows = await (db.select(db.aiMoments)
            ..where((t) => t.dayKey.equals(dayKey)))
          .get();
      return rows.length;
    },
    recordMoment: (moment) async {
      await db.into(db.aiMoments).insert(AiMomentsCompanion.insert(
            dayKey: moment.dayKey,
            type: moment.type.name,
            mode: moment.mode.name,
            source: moment.source.name,
            reference: Value(moment.reference),
            itemId: Value(moment.itemId),
            createdAt: moment.createdAt,
          ));
    },
  );
});

/// A ready-made context snapshot for the moments, so Phase 2 triggers only
/// need to call `decide` without assembling inputs themselves.
final aiContextProvider = Provider<({bool isAmharic, int streak, bool isRestDay, bool wasAway, bool completedToday})>((ref) {
  final lang = ref.watch(userProvider).valueOrNull?.lang ?? 'en';
  final streakState = ref.watch(streakStateProvider).valueOrNull;
  final flow = ref.watch(dailyFlowProvider);
  final streak = streakState?.currentStreak ?? 0;
  return (
    isAmharic: lang == 'am',
    streak: streak,
    isRestDay: streakState?.isSabbathToday ?? false,
    wasAway: streakState?.isBroken ?? false,
    completedToday: flow.done >= DailyFlow.totalSteps,
  );
});
