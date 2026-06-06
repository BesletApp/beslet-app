import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF121212);
  static const Color card = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFFC8A96E);
  static const Color primaryLight = Color(0xFFE8C97E);
  static const Color primaryDark = Color(0xFFA8883A);
  static const Color success = Color(0xFF34D399);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF60A5FA);
  static const Color textPrimary = Color(0xFFF5F0E8);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textMuted = Color(0xFF6B6B6B);
  static const Color border = Color(0xFF2A2A2A);
  static const Color borderLight = Color(0xFF3A3A3A);

  static const Color backgroundLight = Color(0xFFF5F0EB);
  static const Color surfaceLight = Color(0xFFF5F0EB);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF666666);
  static const Color textMutedLight = Color(0xFF999999);
  static const Color borderLightTheme = Color(0xFFD4C9B8);

  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFE8C97E), Color(0xFFC8A96E), Color(0xFFD4B06A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientGoldSoft = LinearGradient(
    colors: [Color(0x26C8A96E), Color(0x0DC8A96E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
