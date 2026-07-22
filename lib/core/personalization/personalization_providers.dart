import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'personalization_engine.dart';
import 'session_controller.dart';
import 'tone_service.dart';

final personalizationEngineProvider = Provider<PersonalizationEngine>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

final sessionControllerProvider = Provider<SessionController>((ref) {
  final engine = ref.watch(personalizationEngineProvider);
  return SessionController(engine);
});

final toneServiceProvider = Provider<ToneService>((ref) {
  final engine = ref.watch(personalizationEngineProvider);
  return ToneService(engine);
});
