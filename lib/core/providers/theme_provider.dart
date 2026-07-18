import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) => ThemeModeNotifier());

final themePaletteProvider = StateNotifierProvider<ThemePaletteNotifier, AppThemeOption>((ref) => ThemePaletteNotifier());

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('darkMode') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setBool('darkMode', false);
    } else {
      state = ThemeMode.dark;
      await prefs.setBool('darkMode', true);
    }
  }
}

class ThemePaletteNotifier extends StateNotifier<AppThemeOption> {
  ThemePaletteNotifier() : super(AppThemeOption.classic) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('themePalette') ?? 'classic';
    state = AppThemeOption.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => AppThemeOption.classic,
    );
    AppColors.currentOption = state;
  }

  Future<void> select(AppThemeOption option) async {
    state = option;
    AppColors.currentOption = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themePalette', option.name);
  }
}
