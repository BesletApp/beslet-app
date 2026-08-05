import 'package:flutter/foundation.dart';

/// The rare, earned moments when the garden transcends its quiet routine — a
/// dawn greeting, a lamp flare of Word-light, a season turning. Always gentle,
/// never a score: they simply *remember* what the day gave.
enum SceneMomentKind { dawnGrace, lampFlare, seasonTurn }

/// A tiny channel for the Growth Zone to ask the living vine for a moment.
/// The vine plays it and then clears itself, so a moment never stacks.
class SceneMomentController extends ChangeNotifier {
  SceneMomentKind? _current;
  int _serial = 0;

  SceneMomentKind? get current => _current;
  int get serial => _serial;

  void play(SceneMomentKind kind) {
    _current = kind;
    _serial++;
    notifyListeners();
  }

  void clear() {
    if (_current == null) return;
    _current = null;
    notifyListeners();
  }
}
