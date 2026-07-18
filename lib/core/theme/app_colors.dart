import 'package:flutter/material.dart';

enum AppThemeOption { classic, sepia, calmBlue, forestGreen, midnight }

class ThemePalette {
  final bool isDark;
  final AppThemeOption option;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color card;
  final Color cardElevated;
  final Color background;
  final Color surface;
  final Color border;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color spiritualPurple;
  final Color progressGreen;
  final Color audioBlue;
  final Color warningOrange;
  final LinearGradient gradientPrimary;
  final LinearGradient gradientPrimarySoft;

  const ThemePalette({
    required this.isDark,
    required this.option,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.card,
    required this.cardElevated,
    required this.background,
    required this.surface,
    required this.border,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.spiritualPurple,
    required this.progressGreen,
    required this.audioBlue,
    required this.warningOrange,
    required this.gradientPrimary,
    required this.gradientPrimarySoft,
  });
}

class AppColors {
  static const Map<AppThemeOption, Map<bool, ThemePalette>> _all = {
    AppThemeOption.classic: {
      false: _classicLight,
      true: _classicDark,
    },
    AppThemeOption.sepia: {
      false: _sepiaLight,
      true: _sepiaDark,
    },
    AppThemeOption.calmBlue: {
      false: _calmBlueLight,
      true: _calmBlueDark,
    },
    AppThemeOption.forestGreen: {
      false: _forestGreenLight,
      true: _forestGreenDark,
    },
    AppThemeOption.midnight: {
      false: _midnightLight,
      true: _midnightDark,
    },
  };

  static ThemePalette of(BuildContext context, {AppThemeOption? option}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opt = option ?? currentOption;
    return _all[opt]![isDark]!;
  }

  static ThemePalette forOption(AppThemeOption option, bool isDark) => _all[option]![isDark]!;

  static AppThemeOption currentOption = AppThemeOption.classic;

  // ─── Classic Gold ────────────────────────────────────────
  static const _classicLight = ThemePalette(
    isDark: false, option: AppThemeOption.classic,
    background: Color(0xFFF5F0EB), surface: Color(0xFFF5F0EB),
    card: Color(0xFFFFFFFF), cardElevated: Color(0xFFFDFAF7),
    textPrimary: Color(0xFF1A1A1A), textSecondary: Color(0xFF6B6B6B),
    textMuted: Color(0xFF999999), border: Color(0xFFD4C9B8),
    primary: Color(0xFFC8942E), primaryLight: Color(0xFFE0B04A), primaryDark: Color(0xFFA07820),
    success: Color(0xFF4CAF50), error: Color(0xFFB84A4A),
    warning: Color(0xFFFF6F00), info: Color(0xFF2196F3),
    spiritualPurple: Color(0xFF9C27B0), progressGreen: Color(0xFF4CAF50),
    audioBlue: Color(0xFF2196F3), warningOrange: Color(0xFFFF6F00),
    gradientPrimary: LinearGradient(colors: [Color(0xFFE0B04A), Color(0xFFC8942E), Color(0xFFD4A03A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x40C8942E), Color(0x15C8942E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  static const _classicDark = ThemePalette(
    isDark: true, option: AppThemeOption.classic,
    background: Color(0xFF07090E), surface: Color(0xFF0F1018),
    card: Color(0xFF151820), cardElevated: Color(0xFF1C1F2A),
    textPrimary: Color(0xFFF0EDE8), textSecondary: Color(0xFF9498A8),
    textMuted: Color(0xFF5C6070), border: Color(0xFF252840),
    primary: Color(0xFFC8942E), primaryLight: Color(0xFFE0B04A), primaryDark: Color(0xFFA07820),
    success: Color(0xFF4CAF50), error: Color(0xFFB84A4A),
    warning: Color(0xFFFF6F00), info: Color(0xFF2196F3),
    spiritualPurple: Color(0xFF9C27B0), progressGreen: Color(0xFF4CAF50),
    audioBlue: Color(0xFF2196F3), warningOrange: Color(0xFFFF6F00),
    gradientPrimary: LinearGradient(colors: [Color(0xFFE0B04A), Color(0xFFC8942E), Color(0xFFD4A03A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x40C8942E), Color(0x15C8942E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  // ─── Sepia Warm ─────────────────────────────────────────
  static const _sepiaLight = ThemePalette(
    isDark: false, option: AppThemeOption.sepia,
    background: Color(0xFFFAF0E6), surface: Color(0xFFF5EBE0),
    card: Color(0xFFFFF8F0), cardElevated: Color(0xFFFAF0E6),
    textPrimary: Color(0xFF2C1810), textSecondary: Color(0xFF6B4F3A),
    textMuted: Color(0xFF9C8A7A), border: Color(0xFFD4C0A8),
    primary: Color(0xFF8B6914), primaryLight: Color(0xFFA8842E), primaryDark: Color(0xFF6B4F00),
    success: Color(0xFF3D7A3D), error: Color(0xFFB84A4A),
    warning: Color(0xFFCC7000), info: Color(0xFF5B7FB5),
    spiritualPurple: Color(0xFF7B4A8B), progressGreen: Color(0xFF3D7A3D),
    audioBlue: Color(0xFF5B7FB5), warningOrange: Color(0xFFCC7000),
    gradientPrimary: LinearGradient(colors: [Color(0xFFA8842E), Color(0xFF8B6914), Color(0xFF9C7820)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x3A8B6914), Color(0x148B6914)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  static const _sepiaDark = ThemePalette(
    isDark: true, option: AppThemeOption.sepia,
    background: Color(0xFF1A1410), surface: Color(0xFF221C16),
    card: Color(0xFF2A241E), cardElevated: Color(0xFF342E28),
    textPrimary: Color(0xFFE8E0D4), textSecondary: Color(0xFFA09888),
    textMuted: Color(0xFF706858), border: Color(0xFF3A342E),
    primary: Color(0xFFD4A04A), primaryLight: Color(0xFFE0B060), primaryDark: Color(0xFFB88830),
    success: Color(0xFF5CAA5C), error: Color(0xFFCC5A5A),
    warning: Color(0xFFE08830), info: Color(0xFF5B9BD5),
    spiritualPurple: Color(0xFF9B5CB5), progressGreen: Color(0xFF5CAA5C),
    audioBlue: Color(0xFF5B9BD5), warningOrange: Color(0xFFE08830),
    gradientPrimary: LinearGradient(colors: [Color(0xFFE0B060), Color(0xFFD4A04A), Color(0xFFC89040)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x3AD4A04A), Color(0x14D4A04A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  // ─── Calm Blue ──────────────────────────────────────────
  static const _calmBlueLight = ThemePalette(
    isDark: false, option: AppThemeOption.calmBlue,
    background: Color(0xFFF0F4F8), surface: Color(0xFFE8EEF4),
    card: Color(0xFFFFFFFF), cardElevated: Color(0xFFFAFCFE),
    textPrimary: Color(0xFF1A222A), textSecondary: Color(0xFF5A6A7A),
    textMuted: Color(0xFF8A9AAA), border: Color(0xFFC8D4E0),
    primary: Color(0xFF4A7FB5), primaryLight: Color(0xFF6B9BD5), primaryDark: Color(0xFF2A5F95),
    success: Color(0xFF3D8A5A), error: Color(0xFFB84A4A),
    warning: Color(0xFFD08030), info: Color(0xFF4A7FB5),
    spiritualPurple: Color(0xFF7B5AAB), progressGreen: Color(0xFF3D8A5A),
    audioBlue: Color(0xFF4A7FB5), warningOrange: Color(0xFFD08030),
    gradientPrimary: LinearGradient(colors: [Color(0xFF6B9BD5), Color(0xFF4A7FB5), Color(0xFF5A8FC5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x254A7FB5), Color(0x0D4A7FB5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  static const _calmBlueDark = ThemePalette(
    isDark: true, option: AppThemeOption.calmBlue,
    background: Color(0xFF0D1117), surface: Color(0xFF13181F),
    card: Color(0xFF1A1F28), cardElevated: Color(0xFF222834),
    textPrimary: Color(0xFFE0E8F0), textSecondary: Color(0xFF8898A8),
    textMuted: Color(0xFF4A5A6A), border: Color(0xFF283040),
    primary: Color(0xFF5B9BD5), primaryLight: Color(0xFF7BB5E5), primaryDark: Color(0xFF3B7BB5),
    success: Color(0xFF4CAA6A), error: Color(0xFFCC5A5A),
    warning: Color(0xFFE09040), info: Color(0xFF5B9BD5),
    spiritualPurple: Color(0xFF9B6BBB), progressGreen: Color(0xFF4CAA6A),
    audioBlue: Color(0xFF5B9BD5), warningOrange: Color(0xFFE09040),
    gradientPrimary: LinearGradient(colors: [Color(0xFF7BB5E5), Color(0xFF5B9BD5), Color(0xFF6BABE5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x255B9BD5), Color(0x0D5B9BD5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  // ─── Forest Green ───────────────────────────────────────
  static const _forestGreenLight = ThemePalette(
    isDark: false, option: AppThemeOption.forestGreen,
    background: Color(0xFFF0F5F0), surface: Color(0xFFE8F0E8),
    card: Color(0xFFFFFFFF), cardElevated: Color(0xFFFAFCFA),
    textPrimary: Color(0xFF1A221A), textSecondary: Color(0xFF5A6A5A),
    textMuted: Color(0xFF8A9A8A), border: Color(0xFFC8D4C8),
    primary: Color(0xFF3D7A3D), primaryLight: Color(0xFF5A9A5A), primaryDark: Color(0xFF2A5A2A),
    success: Color(0xFF3D7A3D), error: Color(0xFFB84A4A),
    warning: Color(0xFFCC7000), info: Color(0xFF4A7FB5),
    spiritualPurple: Color(0xFF7B5A8B), progressGreen: Color(0xFF3D7A3D),
    audioBlue: Color(0xFF4A7FB5), warningOrange: Color(0xFFCC7000),
    gradientPrimary: LinearGradient(colors: [Color(0xFF5A9A5A), Color(0xFF3D7A3D), Color(0xFF4A8A4A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x253D7A3D), Color(0x0D3D7A3D)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  static const _forestGreenDark = ThemePalette(
    isDark: true, option: AppThemeOption.forestGreen,
    background: Color(0xFF0A140A), surface: Color(0xFF0F1A0F),
    card: Color(0xFF152015), cardElevated: Color(0xFF1A2A1A),
    textPrimary: Color(0xFFE0E8E0), textSecondary: Color(0xFF889888),
    textMuted: Color(0xFF4A5A4A), border: Color(0xFF203020),
    primary: Color(0xFF4CAF50), primaryLight: Color(0xFF6BCF6B), primaryDark: Color(0xFF2D8F30),
    success: Color(0xFF4CAF50), error: Color(0xFFCC5A5A),
    warning: Color(0xFFE08830), info: Color(0xFF5B9BD5),
    spiritualPurple: Color(0xFF9B6BAB), progressGreen: Color(0xFF4CAF50),
    audioBlue: Color(0xFF5B9BD5), warningOrange: Color(0xFFE08830),
    gradientPrimary: LinearGradient(colors: [Color(0xFF6BCF6B), Color(0xFF4CAF50), Color(0xFF5ABF5A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x254CAF50), Color(0x0D4CAF50)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  // ─── Midnight ───────────────────────────────────────────
  static const _midnightLight = ThemePalette(
    isDark: false, option: AppThemeOption.midnight,
    background: Color(0xFFF0F2F5), surface: Color(0xFFE8EAEF),
    card: Color(0xFFFFFFFF), cardElevated: Color(0xFFFAFBFC),
    textPrimary: Color(0xFF1A1D23), textSecondary: Color(0xFF5A5E6A),
    textMuted: Color(0xFF8A8E9A), border: Color(0xFFC8CCD4),
    primary: Color(0xFF4A5568), primaryLight: Color(0xFF6A7588), primaryDark: Color(0xFF2A3548),
    success: Color(0xFF3D7A5A), error: Color(0xFFB84A4A),
    warning: Color(0xFFCC7000), info: Color(0xFF4A6A8A),
    spiritualPurple: Color(0xFF7B5A8B), progressGreen: Color(0xFF3D7A5A),
    audioBlue: Color(0xFF4A6A8A), warningOrange: Color(0xFFCC7000),
    gradientPrimary: LinearGradient(colors: [Color(0xFF6A7588), Color(0xFF4A5568), Color(0xFF5A6578)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x204A5568), Color(0x0A4A5568)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  static const _midnightDark = ThemePalette(
    isDark: true, option: AppThemeOption.midnight,
    background: Color(0xFF000000), surface: Color(0xFF080808),
    card: Color(0xFF0F0F0F), cardElevated: Color(0xFF1A1D23),
    textPrimary: Color(0xFFE0E2E8), textSecondary: Color(0xFF808488),
    textMuted: Color(0xFF404448), border: Color(0xFF1A1D23),
    primary: Color(0xFF6A7588), primaryLight: Color(0xFF8A95A8), primaryDark: Color(0xFF4A5568),
    success: Color(0xFF4CAA6A), error: Color(0xFFCC5A5A),
    warning: Color(0xFFE09040), info: Color(0xFF5B7B9B),
    spiritualPurple: Color(0xFF9B6BAB), progressGreen: Color(0xFF4CAA6A),
    audioBlue: Color(0xFF5B7B9B), warningOrange: Color(0xFFE09040),
    gradientPrimary: LinearGradient(colors: [Color(0xFF8A95A8), Color(0xFF6A7588), Color(0xFF7A8598)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    gradientPrimarySoft: LinearGradient(colors: [Color(0x206A7588), Color(0x0A6A7588)], begin: Alignment.topLeft, end: Alignment.bottomRight),
  );

  // ─── Legacy static aliases (classic dark defaults) ──────
  // These exist so existing code that references AppColors.primary (etc.)
  // still compiles without migration.  They always resolve to the classic
  // dark palette.  New code should prefer AppColors.of(context).
  static const Color primary = Color(0xFFC8942E);
  static const Color primaryLight = Color(0xFFE0B04A);
  static const Color primaryDark = Color(0xFFA07820);
  static const Color background = Color(0xFF07090E);
  static const Color surface = Color(0xFF0F1018);
  static const Color card = Color(0xFF151820);
  static const Color cardElevated = Color(0xFF1C1F2A);
  static const Color textPrimary = Color(0xFFF0EDE8);
  static const Color textSecondary = Color(0xFF9498A8);
  static const Color textMuted = Color(0xFF5C6070);
  static const Color border = Color(0xFF252840);
  static const Color borderLight = Color(0xFF303558);
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFB84A4A);
  static const Color warning = Color(0xFFFF6F00);
  static const Color info = Color(0xFF2196F3);
  static const Color spiritualPurple = Color(0xFF9C27B0);
  static const Color progressGreen = Color(0xFF4CAF50);
  static const Color audioBlue = Color(0xFF2196F3);
  static const Color warningOrange = Color(0xFFFF6F00);
  static const LinearGradient gradientGold = LinearGradient(
    colors: [Color(0xFFE0B04A), Color(0xFFC8942E), Color(0xFFD4A03A)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const LinearGradient gradientGoldSoft = LinearGradient(
    colors: [Color(0x40C8942E), Color(0x15C8942E)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  // Light theme legacy aliases
  static const Color backgroundLight = Color(0xFFF5F0EB);
  static const Color surfaceLight = Color(0xFFF5F0EB);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textMutedLight = Color(0xFF999999);
  static const Color borderLightTheme = Color(0xFFD4C9B8);
}
