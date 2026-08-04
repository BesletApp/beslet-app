import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SceneEventType { water, leafLight, branchGrow, fruitPop, bloom, milestone }

class SceneEvent {
  final SceneEventType type;
  final int id;
  const SceneEvent(this.type, this.id);
}

/// A tiny app-wide channel for one-shot scene animations. Any screen can ask
/// the living vine to "play a gesture" without knowing where the vine lives.
class SceneEventBus extends ValueNotifier<SceneEvent?> {
  SceneEventBus() : super(null);

  void emit(SceneEventType type) => value = SceneEvent(type, (value?.id ?? 0) + 1);
}

final sceneEventBusProvider = Provider<SceneEventBus>((ref) => SceneEventBus());
