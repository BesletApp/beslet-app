import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Dark-mode defaults
  static const TextStyle displayLarge = TextStyle(fontFamily: 'CormorantGaramond', fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2);
  static const TextStyle displayMedium = TextStyle(fontFamily: 'CormorantGaramond', fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.25);
  static const TextStyle displaySmall = TextStyle(fontFamily: 'CormorantGaramond', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3);
  static const TextStyle bodyLarge = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const TextStyle bodyMedium = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const TextStyle bodySmall = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle labelLarge = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const TextStyle labelSmall = TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted, letterSpacing: 1.5);
  static const TextStyle amharicDisplay = TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary);
  static const TextStyle amharicBody = TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  // Light-mode variants
  static const TextStyle displayLargeLight = TextStyle(fontFamily: 'CormorantGaramond', fontSize: 34, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight, height: 1.2);
  static const TextStyle displayMediumLight = TextStyle(fontFamily: 'CormorantGaramond', fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight, height: 1.25);
  static const TextStyle displaySmallLight = TextStyle(fontFamily: 'CormorantGaramond', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight, height: 1.3);
  static const TextStyle bodyLargeLight = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight);
  static const TextStyle bodyMediumLight = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight);
  static const TextStyle bodySmallLight = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondaryLight);
  static const TextStyle labelLargeLight = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimaryLight);
  static const TextStyle labelSmallLight = TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMutedLight, letterSpacing: 1.5);
  static const TextStyle amharicDisplayLight = TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary);
  static const TextStyle amharicBodyLight = TextStyle(fontFamily: 'NotoSansEthiopic', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimaryLight);

  /// Returns the dark or light variant of a text style based on isDark
  static TextStyle forTheme(bool isDark, TextStyle dark, TextStyle light) =>
      isDark ? dark : light;
}
