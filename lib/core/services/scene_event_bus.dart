import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vine_life_provider.dart';
import 'vine_chime_service.dart';

enum SceneEventType { water, leafLight, branchGrow, fruitPop, bloom, milestone }

/// A single gesture from a logged discipline. Timestamped so the vine can
/// remember what happened even if the user was looking at another screen.
class SceneEvent {
  final SceneEventType type;
  final int id;
  final DateTime at;

  SceneEvent(this.type, this.id, {DateTime? at}) : at = at ?? DateTime.now();
}

/// A tiny app-wide channel for scene gestures. Any screen can ask the living
/// vine to "play a gesture" without knowing where the vine lives.
///
/// Events are also kept in a short today-memory: when the Growth Zone is
/// opened, anything that happened elsewhere is replayed so the vine is always
/// honest about what the day did — a discipline is never silent.
class SceneEventBus extends ValueNotifier<SceneEvent?> {
  SceneEventBus() : super(null);

  /// Optional persistence hook: after a gesture fires, the living garden can
  /// remember it so it keeps living even when the Growth Zone is closed.
  Future<void> Function(SceneEvent event)? onPersist;

  final List<SceneEvent> _history = [];
  String _dayKey = _dateOnly(DateTime.now());

  /// Fires the gesture immediately (so a visible vine can burst) and keeps a
  /// gentle haptic at the point of the action. Also records the event for the
  /// next time the Growth Zone is opened and hands it to the garden's memory.
  void emit(SceneEventType type) {
    final event = SceneEvent(type, (value?.id ?? 0) + 1);
    value = event;
    _prune();
    _history.add(event);
    unawaited(_buzz());
    unawaited(VineChime.chime());
    final persist = onPersist;
    if (persist != null) {
      unawaited(persist(event));
    }
  }

  Future<void> _buzz() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {
      // Some environments (tests, web, older devices) have no haptics channel.
    }
  }

  /// Today's gestures not yet replayed to the user, oldest first.
  List<SceneEvent> pendingRecap() {
    _prune();
    return List.unmodifiable(_history);
  }

  /// Marks the given event as already seen (e.g. it burst live on the vine).
  void markRecappedThrough(int id) {
    _history.removeWhere((e) => e.id == id);
  }

  /// Clears the today-memory after the recap has been replayed.
  void markRecapped() {
    _history.clear();
  }

  void _prune() {
    final today = _dateOnly(DateTime.now());
    if (_dayKey != today) {
      _dayKey = today;
      _history.clear();
    }
  }

  static String _dateOnly(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

final sceneEventBusProvider = Provider<SceneEventBus>((ref) {
  unawaited(VineChime.init());
  final bus = SceneEventBus();
  final writer = VineLifeWriter(ref);
  bus.onPersist = writer.recordEvent;
  return bus;
});
