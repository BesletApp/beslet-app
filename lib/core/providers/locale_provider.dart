import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _localeKey = 'app_locale';

final localeCodeProvider = StateProvider<String>((ref) => 'en');

final localeProvider = Provider<Locale>((ref) {
  return Locale(ref.watch(localeCodeProvider));
});

Future<void> loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(_localeKey) ?? 'en';
  _localeCode = code;
}

String _localeCode = 'en';

String get currentLocaleCode => _localeCode;

void setLocaleCode(String code) {
  _localeCode = code;
}

Future<void> saveLocale(String code) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_localeKey, code);
}
