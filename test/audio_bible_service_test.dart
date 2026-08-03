import 'package:flutter_test/flutter_test.dart';
import 'package:beslet_app/core/services/audio_bible_service.dart';

Map<String, dynamic> voice({
  required String name,
  required String locale,
  String quality = 'normal',
  String networkRequired = '0',
}) {
  return {
    'name': name,
    'locale': locale,
    'quality': quality,
    'latency': 'normal',
    'network_required': networkRequired,
    'features': '',
  };
}

void main() {
  group('selectTtsVoice', () {
    test('picks neural very-high-quality voice over robotic default', () {
      final voices = [
        voice(name: 'en-US-language', locale: 'en-US', quality: 'normal'),
        voice(name: 'en-us-x-tfg-network', locale: 'en-US', quality: 'very high'),
      ];
      final chosen = selectTtsVoice(voices, 'en-US');
      expect(chosen?['name'], 'en-us-x-tfg-network');
    });

    test('handles quality as string without throwing (regression)', () {
      final voices = [
        voice(name: 'en-us-a-local', locale: 'en-US', quality: 'low'),
        voice(name: 'en-us-b-local', locale: 'en-US', quality: 'very high'),
      ];
      final chosen = selectTtsVoice(voices, 'en-US');
      expect(chosen?['name'], 'en-us-b-local');
    });

    test('prefers exact locale at equal quality and neural-ness', () {
      final voices = [
        voice(name: 'en-us-x-tfg-network', locale: 'en-CA', quality: 'very high'),
        voice(name: 'en-us-x-tfg-network', locale: 'en-US', quality: 'very high'),
        voice(name: 'en-us-x-tfg-network', locale: 'en', quality: 'very high'),
      ];
      final chosen = selectTtsVoice(voices, 'en-US');
      expect(chosen?['locale'], 'en-US');
    });

    test('prefers offline voice among ties', () {
      final voices = [
        voice(name: 'en-us-x-tfg-network', locale: 'en-US', quality: 'very high', networkRequired: '1'),
        voice(name: 'en-us-x-sfg-network', locale: 'en-US', quality: 'very high', networkRequired: '0'),
      ];
      final chosen = selectTtsVoice(voices, 'en-US');
      expect(chosen?['network_required'], '0');
    });

    test('ignores voices of other languages', () {
      final voices = [
        voice(name: 'am-et-...-voice', locale: 'am-ET', quality: 'very high'),
        voice(name: 'en-US-language', locale: 'en-US', quality: 'normal'),
      ];
      final chosen = selectTtsVoice(voices, 'en-US');
      expect(chosen?['locale'], 'en-US');
      final am = selectTtsVoice(voices, 'am-ET');
      expect(am?['locale'], 'am-ET');
    });

    test('returns null when no voice matches', () {
      expect(selectTtsVoice([], 'en-US'), isNull);
      expect(selectTtsVoice([
        voice(name: 'am-et-...-voice', locale: 'am-ET'),
      ], 'en-US'), isNull);
    });
  });
}
