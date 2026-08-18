import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/provocative_question_service.dart';

/// Today's curated self-examination question, picked by a deterministic
/// date-based rotation over the bundled local dataset. Offline and stateless.
final todayQuestionProvider = FutureProvider<ProvocativeQuestion>((ref) async {
  final library = await ProvocativeQuestionService.load();
  final question = library.questionFor(DateTime.now());
  if (question == null) {
    throw StateError('no questions bundled');
  }
  return question;
});