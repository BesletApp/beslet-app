import 'package:flutter/material.dart';
import 'types.dart';

final Map<VisualTone, ThemeConfig> _themes = {
  VisualTone.calm: ThemeConfig(
    backgroundFrom: const Color(0xFF0F1117),
    backgroundTo: const Color(0xFF0A0C10),
    backgroundColor: const Color(0xFF0A0A0A),
    textColor: const Color(0xFFD1D5DB),
    accentColor: const Color(0xFFC8942E),
    glowIntensity: 0.3,
    animationSoftness: 30,
    ambientOpacity: 0.12,
    glowColor: const Color(0x26C8942E),
    borderColor: const Color(0x14C8942E),
  ),
  VisualTone.warm: ThemeConfig(
    backgroundFrom: const Color(0xFF1A1208),
    backgroundTo: const Color(0xFF0F0B04),
    backgroundColor: const Color(0xFF0A0804),
    textColor: const Color(0xFFF5EDE0),
    accentColor: const Color(0xFFD4A030),
    glowIntensity: 0.45,
    animationSoftness: 25,
    ambientOpacity: 0.2,
    glowColor: const Color(0x40D4A030),
    borderColor: const Color(0x1FD4A030),
  ),
  VisualTone.highContrast: ThemeConfig(
    backgroundFrom: const Color(0xFF0A0A0A),
    backgroundTo: const Color(0xFF0A0A0A),
    backgroundColor: const Color(0xFF0A0A0A),
    textColor: const Color(0xFFFFFFFF),
    accentColor: const Color(0xFFF5C542),
    glowIntensity: 0.6,
    animationSoftness: 35,
    ambientOpacity: 0.3,
    glowColor: const Color(0x4DF5C542),
    borderColor: const Color(0x26F5C542),
  ),
  VisualTone.candlelight: ThemeConfig(
    backgroundFrom: const Color(0xFF100C06),
    backgroundTo: const Color(0xFF080603),
    backgroundColor: const Color(0xFF060402),
    textColor: const Color(0xFFE8DDD0),
    accentColor: const Color(0xFFC8942E),
    glowIntensity: 0.2,
    animationSoftness: 40,
    ambientOpacity: 0.08,
    glowColor: const Color(0x1AC8942E),
    borderColor: const Color(0x0DC8942E),
  ),
};

const Map<ExperienceIntent, ({VisualTone primary, VisualTone alt})> _intentToneMap = {
  ExperienceIntent.grounding: (primary: VisualTone.calm, alt: VisualTone.candlelight),
  ExperienceIntent.slowing: (primary: VisualTone.candlelight, alt: VisualTone.calm),
  ExperienceIntent.comforting: (primary: VisualTone.warm, alt: VisualTone.candlelight),
  ExperienceIntent.affirming: (primary: VisualTone.warm, alt: VisualTone.highContrast),
  ExperienceIntent.awakening: (primary: VisualTone.highContrast, alt: VisualTone.warm),
  ExperienceIntent.resting: (primary: VisualTone.candlelight, alt: VisualTone.calm),
};

ThemeConfig getTheme(ExperienceContext ctx, ExperienceIntent intent) {
  final toneMap = _intentToneMap[intent] ?? (primary: VisualTone.calm, alt: VisualTone.candlelight);
  final preferred = ctx.preferredVisualTone;

  final tone = (preferred == toneMap.primary || preferred == toneMap.alt)
      ? preferred
      : toneMap.primary;

  final base = _themes[tone]!;
  final glowMod = (ctx.timeOfDay == DayTime.deepNight || ctx.timeOfDay == DayTime.night) ? 0.7 : 1.0;

  return ThemeConfig(
    backgroundFrom: base.backgroundFrom,
    backgroundTo: base.backgroundTo,
    backgroundColor: base.backgroundColor,
    textColor: base.textColor,
    accentColor: base.accentColor,
    glowIntensity: base.glowIntensity * glowMod,
    animationSoftness: base.animationSoftness,
    ambientOpacity: base.ambientOpacity * glowMod,
    glowColor: base.glowColor,
    borderColor: base.borderColor,
  );
}
