import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VineChime {
  VineChime._();

  static const chimePrefKey = 'vineChimeEnabled';

  static AudioPlayer? _player;

  static bool _enabled = false;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(chimePrefKey) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(chimePrefKey, value);
  }

  static bool get enabled => _enabled;

  static Future<void> chime() async {
    if (!_enabled) return;
    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource('sounds/vine_chime.wav'), volume: 0.6);
    } catch (_) {}
  }
}
