import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData _baseTheme({required Brightness brightness, required ThemePalette c}) {
  final isDark = brightness == Brightness.dark;
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.primary,
      secondary: c.primary,
      surface: c.surface,
      error: c.error,
      onPrimary: isDark ? const Color(0xFF07090E) : Colors.white,
      onSecondary: isDark ? const Color(0xFF07090E) : Colors.white,
      onSurface: c.textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: c.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: c.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border, width: 0.5),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: c.card,
      selectedItemColor: c.primary,
      unselectedItemColor: c.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(color: c.border, thickness: 0.5),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: c.textMuted),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.primary,
        foregroundColor: isDark ? const Color(0xFF07090E) : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.primary,
        side: BorderSide(color: c.border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: c.primary,
      linearTrackColor: c.border,
      circularTrackColor: c.border,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'CormorantGaramond', fontSize: 32,
        fontWeight: FontWeight.w700, color: c.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'CormorantGaramond', fontSize: 26,
        fontWeight: FontWeight.w600, color: c.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'CormorantGaramond', fontSize: 20,
        fontWeight: FontWeight.w600, color: c.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter', fontSize: 16,
        fontWeight: FontWeight.w400, color: c.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter', fontSize: 14,
        fontWeight: FontWeight.w400, color: c.textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter', fontSize: 12,
        fontWeight: FontWeight.w400, color: c.textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter', fontSize: 14,
        fontWeight: FontWeight.w700, color: c.textPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter', fontSize: 10,
        fontWeight: FontWeight.w800, color: c.textMuted,
        letterSpacing: 1.5,
      ),
    ),
  );
}

class AppTheme {
  static ThemeData forPalette(ThemePalette c) =>
      _baseTheme(brightness: c.isDark ? Brightness.dark : Brightness.light, c: c);

  static ThemeData darkTheme([AppThemeOption option = AppThemeOption.classic]) {
    return forPalette(AppColors.forOption(option, true));
  }

  static ThemeData lightTheme([AppThemeOption option = AppThemeOption.classic]) {
    return forPalette(AppColors.forOption(option, false));
  }
}
