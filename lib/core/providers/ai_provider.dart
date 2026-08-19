import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_key_store.dart';

/// The optional user-supplied Google AI key lives in the OS keychain.
final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());

/// Whether the reader has connected their own Gemini key. Watched by the study
/// panel so it never offers "Add my Gemini API key" after a key is already
/// stored.
final userKeyPresentProvider = FutureProvider<bool>((ref) async {
  final key = await ref.watch(aiKeyStoreProvider).readUserKey();
  return key != null && key.trim().isNotEmpty;
});