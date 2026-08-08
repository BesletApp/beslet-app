import 'package:shared_preferences/shared_preferences.dart';

class PersonalizationEngine {
  final SharedPreferences _prefs;

  int _appOpenCount = 0;
  int _sessionsToday = 0;
  DateTime? _lastOpenedAt;
  int _streakDays = 0;

  PersonalizationEngine._(this._prefs);

  static Future<PersonalizationEngine> init() async {
    final prefs = await SharedPreferences.getInstance();
    final engine = PersonalizationEngine._(prefs);
    await engine._load();
    await engine._recordSession();
    return engine;
  }

  Future<void> _load() async {
    _appOpenCount = _prefs.getInt('pe_appOpenCount') ?? 0;
    _sessionsToday = _prefs.getInt('pe_sessionsToday') ?? 0;
    _streakDays = _prefs.getInt('pe_streakDays') ?? 0;
    final lastStr = _prefs.getString('pe_lastOpenedAt');
    _lastOpenedAt = lastStr != null ? DateTime.tryParse(lastStr) : null;
  }

  Future<void> _recordSession() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _appOpenCount += 1;

    if (_lastOpenedAt == null) {
      _sessionsToday = 1;
      _streakDays = 1;
    } else {
      final lastDay = DateTime(_lastOpenedAt!.year, _lastOpenedAt!.month, _lastOpenedAt!.day);
      final diff = today.difference(lastDay).inDays;
      if (diff == 0) {
        _sessionsToday += 1;
      } else {
        _sessionsToday = 1;
        if (diff == 1) {
          _streakDays += 1;
        } else {
          _streakDays = 1;
        }
      }
    }

    _lastOpenedAt = now;

    await _prefs.setInt('pe_appOpenCount', _appOpenCount);
    await _prefs.setInt('pe_sessionsToday', _sessionsToday);
    await _prefs.setInt('pe_streakDays', _streakDays);
    await _prefs.setString('pe_lastOpenedAt', now.toIso8601String());
  }

  int get appOpenCount => _appOpenCount;
  int get sessionsToday => _sessionsToday;
  DateTime? get lastOpenedAt => _lastOpenedAt;
  int get streakDays => _streakDays;

  bool get isFirstSessionToday => _sessionsToday == 1;
  bool get isReturningUser => _appOpenCount > 1;
  bool get wasAwayForDays {
    if (_lastOpenedAt == null) return false;
    final diff = DateTime.now().difference(_lastOpenedAt!).inDays;
    return diff >= 2;
  }

  /// 0 = casual, 1 = engaged, 2 = deep
  int get sessionDepth {
    if (_sessionsToday <= 1) return 0;
    if (_sessionsToday <= 4) return 1;
    return 2;
  }
}
