import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../personalization/personalization_providers.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) => AiService());

final hasApiKeyProvider = FutureProvider<bool>((ref) async {
  final svc = ref.watch(aiServiceProvider);
  return svc.hasApiKey;
});

final aiGreetingProvider = FutureProvider.family<String, ({int hour, String userName})>((ref, params) async {
  final ai = ref.watch(aiServiceProvider);
  final engine = ref.watch(personalizationEngineProvider);
  final hasKey = await ref.watch(hasApiKeyProvider.future);
  if (!hasKey) throw Exception('no key');
  return ai.greeting(
    isAm: false,
    hour: params.hour,
    streakDays: engine.streakDays,
    isReturningAfterAbsence: engine.wasAwayForDays,
    appOpenCount: engine.appOpenCount,
  );
});

final aiCompletionMessageProvider = FutureProvider.family<String, ({String userName, String taskName})>((ref, params) async {
  final ai = ref.watch(aiServiceProvider);
  final hasKey = await ref.watch(hasApiKeyProvider.future);
  if (!hasKey) throw Exception('no key');
  return ai.completionMessage(
    isAm: false,
    userName: params.userName,
    task: params.taskName,
  );
});
