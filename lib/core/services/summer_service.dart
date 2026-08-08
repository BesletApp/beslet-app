class SummerService {
  static final DateTime summerStart = DateTime(2026, 6, 8);
  static final DateTime summerEnd = DateTime(2026, 9, 11);
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
  static DateTime get nextSummerStart => DateTime(nextSummerYear, summerStart.month, summerStart.day);
  static double get progress => daysElapsed / totalSummerDays;
  static String get phase { final p = progress; if (p < 0.33) return 'Early Summer — Build Foundations'; if (p < 0.66) return 'Mid Summer — Deepen Roots'; return 'Late Summer — Bear Fruit'; }
  static String get urgencyMessage { final d = daysRemaining; if (d > 60) return 'Full season ahead. Begin gently.'; if (d > 30) return '$d days remain. Walk with steadiness.'; if (d > 14) return 'The season ripens, with $d days left.'; if (d > 7) return 'A little under two weeks remain. Carry on.'; if (d > 0) return '$d days left. Today is enough.'; return 'The harvest has come in. Rest in what God did.'; }
  static String get outsideMessage => 'Summer $nextSummerYear begins June 8 (Sene 1). Get ready!';
  static int get daysUntilNextSummer => nextSummerStart.difference(DateTime.now()).inDays;

  /// The shared season, spoken in the present tense — never a countdown.
  /// Returns (en, am) sentence pair. Pure and deterministic for tests.
  static ({String en, String am}) seasonFor(DateTime now) {
    if (now.isBefore(summerStart)) {
      return (en: 'The soil rests. The season of growth has not yet begun.', am: 'አፈሩ ያርፋል። የእድገት ወቅት ገና አልጀመረም።');
    }
    if (now.isAfter(summerEnd)) {
      return (en: 'The harvest has come in. The season of growth has closed.', am: 'መከሩ ገብቷል። የእድገት ወቅቱ ተዘግቷል።');
    }
    final p = now.difference(summerStart).inDays / totalSummerDays;
    if (p < 0.33) {
      return (en: 'The soil is turning. We are in early summer, laying foundations.', am: 'አፈሩ እየተዘጋጀ ነው። በበጋ መጀመሪያ ላይ ነን፣ መሠረትን እየጣልን ነው።');
    }
    if (p < 0.66) {
      return (en: 'The soil is warm. We are in mid-summer, deepening roots.', am: 'አፈሩ ሞቃታማ ነው። በበጋ መካከል ላይ ነን፣ ሥርን እያጠናከርን ነው።');
    }
    return (en: 'The days are full. We are in late summer, bearing fruit.', am: 'ቀናቶቹ ሙሉ ናቸው። በበጋ መጨረሻ ላይ ነን፣ ፍሬ እያፈራን ነው።');
  }
}
