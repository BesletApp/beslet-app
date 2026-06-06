class SummerService {
  static final DateTime summerStart = DateTime(2026, 6, 9);
  static final DateTime summerEnd = DateTime(2026, 8, 31);
  static int get totalSummerDays => summerEnd.difference(summerStart).inDays + 1;
  static int get daysElapsed {
    final now = DateTime.now();
    if (now.isBefore(summerStart)) return 0;
    if (now.isAfter(summerEnd)) return totalSummerDays;
    return now.difference(summerStart).inDays + 1;
  }
  static int get daysRemaining {
    final now = DateTime.now();
    if (now.isBefore(summerStart)) return totalSummerDays;
    if (now.isAfter(summerEnd)) return 0;
    return summerEnd.difference(now).inDays;
  }
  static bool get isInSummer {
    final now = DateTime.now();
    return !now.isBefore(summerStart) && !now.isAfter(summerEnd);
  }
  static int get nextSummerYear => DateTime.now().isAfter(summerEnd) ? summerStart.year + 1 : summerStart.year;
  static DateTime get nextSummerStart => DateTime(nextSummerYear, 6, 9);
  static double get progress => daysElapsed / totalSummerDays;
  static String get phase { final p = progress; if (p < 0.33) return 'Early Summer — Build Foundations'; if (p < 0.66) return 'Mid Summer — Deepen Roots'; return 'Late Summer — Bear Fruit'; }
  static String get urgencyMessage { final d = daysRemaining; if (d > 60) return 'Full summer ahead. Start strong!'; if (d > 30) return '$d days left. Keep the momentum!'; if (d > 14) return 'Only $d days remain. Finish well!'; if (d > 7) return 'Two weeks to go. Maximum impact!'; if (d > 0) return 'Final $d days. Make them count!'; return 'Summer completed. How did you grow?'; }
  static String get outsideMessage => 'Summer $nextSummerYear begins June 9. Get ready!';
  static int get daysUntilNextSummer => nextSummerStart.difference(DateTime.now()).inDays;
}
