import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextTheme {
  final TextStyle displayLarge;
  final TextStyle displayMedium;
  final TextStyle displaySmall;
  final TextStyle bodyLarge;
  final TextStyle bodyMedium;
  final TextStyle bodySmall;
  final TextStyle labelLarge;
  final TextStyle labelSmall;
  final TextStyle amharicDisplay;
  final TextStyle amharicBody;
  const AppTextTheme({
    required this.displayLarge, required this.displayMedium, required this.displaySmall,
    required this.bodyLarge, required this.bodyMedium, required this.bodySmall,
    required this.labelLarge, required this.labelSmall,
    required this.amharicDisplay, required this.amharicBody,
  });
}

class AppTextStyles {
  /// Build an [AppTextTheme] from a [ThemePalette]. When [isAm] is true the
  /// Ethiopic font (bundled NotoSansEthiopic) is used with taller line heights
  /// so fidel renders comfortably.
  static AppTextTheme forPalette(ThemePalette c, {bool isAm = false}) {
    final display = isAm ? 'NotoSansEthiopic' : 'CormorantGaramond';
    final body = isAm ? 'NotoSansEthiopic' : 'Inter';
    final dh = isAm ? 1.5 : 1.2;
    final dm = isAm ? 1.55 : 1.25;
    final ds = isAm ? 1.6 : 1.3;
    final bh = isAm ? 1.6 : 1.2;
    return AppTextTheme(
      displayLarge: TextStyle(fontFamily: display, fontSize: isAm ? 30 : 34, fontWeight: FontWeight.w700, color: c.textPrimary, height: dh),
      displayMedium: TextStyle(fontFamily: display, fontSize: isAm ? 25 : 28, fontWeight: FontWeight.w600, color: c.textPrimary, height: dm),
      displaySmall: TextStyle(fontFamily: display, fontSize: isAm ? 21 : 22, fontWeight: FontWeight.w600, color: c.textPrimary, height: ds),
      bodyLarge: TextStyle(fontFamily: body, fontSize: 16, fontWeight: FontWeight.w400, color: c.textPrimary, height: bh),
      bodyMedium: TextStyle(fontFamily: body, fontSize: 14, fontWeight: FontWeight.w400, color: c.textPrimary, height: bh),
      bodySmall: TextStyle(fontFamily: body, fontSize: 12, fontWeight: FontWeight.w400, color: c.textSecondary, height: bh),
      labelLarge: TextStyle(fontFamily: body, fontSize: 14, fontWeight: FontWeight.w700, color: c.textPrimary, height: bh),
      labelSmall: TextStyle(fontFamily: body, fontSize: 10, fontWeight: FontWeight.w800, color: c.textMuted, letterSpacing: isAm ? 0.5 : 1.5),
      amharicDisplay: TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 36, fontWeight: FontWeight.w700, color: c.primary),
      amharicBody: TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 14, fontWeight: FontWeight.w400, color: c.textPrimary),
    );
  }

  static final AppTextTheme _dark = forPalette(AppColors.forOption(AppThemeOption.classic, true));

  static AppTextTheme of(BuildContext context) =>
      forPalette(AppColors.of(context), isAm: Localizations.localeOf(context).languageCode == 'am');

  // Legacy static getters — kept for backward compat, return classic dark defaults
  static TextStyle get displayLarge => _dark.displayLarge;
  static TextStyle get displayMedium => _dark.displayMedium;
  static TextStyle get displaySmall => _dark.displaySmall;
  static TextStyle get bodyLarge => _dark.bodyLarge;
  static TextStyle get bodyMedium => _dark.bodyMedium;
  static TextStyle get bodySmall => _dark.bodySmall;
  static TextStyle get labelLarge => _dark.labelLarge;
  static TextStyle get labelSmall => _dark.labelSmall;
  static TextStyle get amharicDisplay => _dark.amharicDisplay;
  static TextStyle get amharicBody => _dark.amharicBody;

  static TextStyle forTheme(bool isDark, TextStyle dark, TextStyle light) =>
      isDark ? dark : light;
}
