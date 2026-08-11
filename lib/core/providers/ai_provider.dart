import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_key_store.dart';

/// The optional user-supplied Google AI key lives in the OS keychain.
final aiKeyStoreProvider = Provider<AiKeyStore>((ref) => AiKeyStore());
