import 'package:flutter/material.dart';

class ThemePalette {
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color card;
  final Color background;
  final Color surface;
  final Color border;

  const ThemePalette._({
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.card,
    required this.background,
    required this.surface,
    required this.border,
  });

  factory ThemePalette({required bool isDark}) {
    if (isDark) {
      return const ThemePalette._(
        isDark: true,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        textMuted: AppColors.textMuted,
        card: AppColors.card,
        background: AppColors.background,
        surface: AppColors.surface,
        border: AppColors.border,
      );
    }
    return const ThemePalette._(
      isDark: false,
      textPrimary: AppColors.textPrimaryLight,
      textSecondary: AppColors.textSecondaryLight,
      textMuted: AppColors.textMutedLight,
      card: AppColors.cardLight,
      background: AppColors.backgroundLight,
      surface: AppColors.surfaceLight,
      border: AppColors.borderLightTheme,
    );
  }
}

class AppColors {
  // Obsidian depths — cool blue-black, 3-tier surface system
  static const Color background = Color(0xFF07090E);
  static const Color surface = Color(0xFF0F1018);
  static const Color card = Color(0xFF151820);
  static const Color cardElevated = Color(0xFF1C1F2A);

  // Single gold accent — 24k deep amber
  static const Color primary = Color(0xFFC8942E);
  static const Color primaryLight = Color(0xFFE0B04A);
  static const Color primaryDark = Color(0xFFA07820);

  // Status indicators — whispers only
  static const Color success = Color(0xFFC8942E);
  static const Color error = Color(0xFFB84A4A);
  static const Color warning = Color(0xFFC8942E);
  static const Color info = Color(0xFFC8942E);

  // Neutrals
  static const Color textPrimary = Color(0xFFF0EDE8);
  static const Color textSecondary = Color(0xFF9498A8);
  static const Color textMuted = Color(0xFF5C6070);

  // Borders
  static const Color border = Color(0xFF252840);
  static const Color borderLight = Color(0xFF303558);

  // Light theme
  static const Color backgroundLight = Color(0xFFF5F0EB);
  static const Color surfaceLight = Color(0xFFF5F0EB);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textMutedLight = Color(0xFF999999);
  static const Color borderLightTheme = Color(0xFFD4C9B8);

  // Semantic colors — 4-phase palette for visual hierarchy
  static const Color spiritualPurple = Color(0xFF9C27B0);
  static const Color progressGreen = Color(0xFF4CAF50);
  static const Color audioBlue = Color(0xFF2196F3);
  static const Color warningOrange = Color(0xFFFF6F00);

  /// Returns the correct palette for the current theme brightness
  static ThemePalette of(BuildContext context) => ThemePalette(
    isDark: Theme.of(context).brightness == Brightness.dark,
  );

  // Gold gradients
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFE0B04A), Color(0xFFC8942E), Color(0xFFD4A03A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Visible warm gold tint — 25% opacity so it reads as a warm glow
  static const LinearGradient gradientGoldSoft = LinearGradient(
    colors: [Color(0x40C8942E), Color(0x15C8942E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
