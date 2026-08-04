/// Pure, deterministic vitality model for the living vine. Today's disciplines
/// feed vividness and animation only — the vine's structure still grows on the
/// journey clock. A quiet day sits at a grace floor, never at zero.
class GrowthVitality {
  final double hydration01;
  final double leafGlow01;
  final double branchOpen01;
  final double ripen01;
  final int? mood;

  const GrowthVitality({
    required this.hydration01,
    required this.leafGlow01,
    required this.branchOpen01,
    required this.ripen01,
    this.mood,
  });

  static const double graceFloor = 0.35;

  static GrowthVitality compute({
    required bool prayed,
    required bool read,
    required bool connected,
    required int habitsDone,
    required int bestStreak,
    int? mood,
  }) {
    return GrowthVitality(
      hydration01: prayed ? 1.0 : graceFloor,
      leafGlow01: read ? 1.0 : graceFloor,
      branchOpen01: connected ? 1.0 : graceFloor,
      ripen01: (((habitsDone > 0 ? 1 : 0) * 0.5) +
              (bestStreak.clamp(0, 30) / 60))
          .clamp(0.0, 1.0),
      mood: mood,
    );
  }

  static const GrowthVitality quiet = GrowthVitality(
    hydration01: graceFloor,
    leafGlow01: graceFloor,
    branchOpen01: graceFloor,
    ripen01: 0,
  );
}
