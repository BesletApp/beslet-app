import 'ai_models.dart';

/// The dependence guard. The Quiet Guide's success is measured by the user
/// needing it *less*, so this gate is deliberately conservative:
///   - a hard daily cap on quiet moments,
///   - mature users are heard less and less,
///   - a returning user receives one gentle pointer, then silence.
/// Grace first — this is a memory, never a score.
class AiBoundaryGate {
  static const int defaultDailyCap = 3;

  const AiBoundaryGate();

  /// Maximum moments per day for each maturity bucket.
  static int maxPerDay(AiMaturityBucket maturity) => switch (maturity) {
        AiMaturityBucket.seeding => 3,
        AiMaturityBucket.growing => 2,
        AiMaturityBucket.rooted => 1,
      };

  /// Returns true when a quiet moment is allowed right now.
  bool allows({
    required int todayMomentCount,
    required AiMaturityBucket maturity,
    required AiAbsenceBucket absence,
  }) {
    final max = maxPerDay(maturity);
    if (todayMomentCount >= max) return false;
    if (absence == AiAbsenceBucket.returning && todayMomentCount >= 1) {
      return false; // one gentle pointer on return, then silence
    }
    return true;
  }

  /// The local day key (yyyy-MM-dd) used to bucket the moment count.
  static String dayKeyFor(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
