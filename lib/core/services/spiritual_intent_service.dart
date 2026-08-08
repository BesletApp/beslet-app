/// The optional one-tap spiritual direction the user chose at onboarding.
/// It gently seeds the home focus and the day's first suggested action,
/// without ever becoming a gate or a scorecard.
class SpiritualIntentService {
  static const String growInPrayer = 'grow_in_prayer';
  static const String consistentBible = 'consistent_bible';
  static const String disciplinedDaily = 'disciplined_daily';

  /// A short, calm focus line shown near the home hero.
  static String focusLine(String intent, {required bool isAm}) {
    switch (intent) {
      case growInPrayer:
        return isAm ? 'እግዚአብሔር ጋር ባለህ ዕለታዊ ውይይት ውስጥ እያደጉ ነው።' : 'Your walk is growing in daily conversation with God.';
      case consistentBible:
        return isAm ? 'ቃሉን በተከታታይ በማንበብ ትቆያለህ።' : 'You are remaining steady in the Word each day.';
      case disciplinedDaily:
        return isAm ? 'በየቀኑ በዓላማ እየኖርህ ነው።' : 'You are living each day with purpose.';
      default:
        return isAm ? 'በእግዚአብሔር ዕለታዊ ግንኙነትህ እያደግክ ነው።' : 'Walking with God daily.';
    }
  }

  /// The first step the companion nudges today, based on the chosen intent.
  /// Never locks; it only gives the daily hero a gentle primary direction.
  static int defaultFlowStep(String intent) {
    switch (intent) {
      case growInPrayer:
        return 1; // Prayer
      case disciplinedDaily:
        return 2; // Act
      default:
        return 0; // Bible
    }
  }
}