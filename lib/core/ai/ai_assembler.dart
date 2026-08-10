import '../emotional/experience_profile.dart';
import 'ai_models.dart';

/// Builds the coarse, non-personal [ContextPacket] the selectors may see.
///
/// This is the anti-surveillance boundary: the assembler receives only coarse
/// signals (language, day part, maturity, engagement, absence) and outputs
/// only enums and booleans. It never touches journal text, names, locations,
/// or raw counts. The shape of [ContextPacket] makes it impossible to leak
/// them.
class AiContextAssembler {
  const AiContextAssembler();

  ContextPacket assemble({
    required bool isAmharic,
    required DateTime now,
    required int currentStreak,
    required bool isRestDay,
    required bool wasAwayForDays,
    required bool completedToday,
  }) {
    final season = AppSeason.fromStreak(currentStreak);
    return ContextPacket(
      language: isAmharic ? AiLanguageBucket.amharic : AiLanguageBucket.english,
      dayPart: _dayPart(now.hour),
      maturity: switch (season) {
        AppSeason.seedling => AiMaturityBucket.seeding,
        AppSeason.rooting || AppSeason.flourishing => AiMaturityBucket.growing,
        AppSeason.established || AppSeason.rooted => AiMaturityBucket.rooted,
      },
      engagement: completedToday
          ? AiEngagementBucket.deep
          : (currentStreak > 0 ? AiEngagementBucket.steady : AiEngagementBucket.low),
      absence: wasAwayForDays ? AiAbsenceBucket.returning : AiAbsenceBucket.present,
      isRestDay: isRestDay,
      // Fasting / church-season awareness is filled in Phase 2 from the
      // Ethiopian church calendar; the bucket already exists so the selectors
      // and the bank can grow into it without a breaking change.
      isFastingSeason: false,
    );
  }

  static AiDayPartBucket _dayPart(int hour) {
    if (hour < 5) return AiDayPartBucket.night;
    if (hour < 12) return AiDayPartBucket.morning;
    if (hour < 17) return AiDayPartBucket.afternoon;
    if (hour < 21) return AiDayPartBucket.evening;
    return AiDayPartBucket.night;
  }
}
