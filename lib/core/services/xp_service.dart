class XpService {
  static const int habitComplete = 10;
  static const int bibleRead = 20;
  static const int prayerPerMinute = 1;
  static const int skillSession = 5;
  static const int reflectionComplete = 15;

  static int calculateLevel(int xp) {
    if (xp < 100) return 0;
    if (xp < 300) return 1;
    if (xp < 600) return 2;
    if (xp < 1000) return 3;
    return 4;
  }

  static String getLevelName(int level) {
    switch (level) { case 0: return 'Seed'; case 1: return 'Growing'; case 2: return 'Rooted'; case 3: return 'Mature'; case 4: return 'Leader'; default: return 'Seed'; }
  }

  static String getLevelNameAmharic(int level) {
    switch (level) { case 0: return 'ዘር'; case 1: return 'ማደግ'; case 2: return 'ሥር የሰደደ'; case 3: return 'ብስለት'; case 4: return 'መሪ'; default: return 'ዘር'; }
  }

  static int xpForNextLevel(int level) {
    switch (level) { case 0: return 100; case 1: return 300; case 2: return 600; case 3: return 1000; default: return 1000; }
  }

  static double xpProgress(int xp) {
    final level = calculateLevel(xp);
    final currentLevelXp = level == 0 ? 0 : xpForNextLevel(level - 1);
    final nextLevelXp = xpForNextLevel(level);
    final xpInLevel = xp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    if (xpNeeded <= 0) return 1.0;
    return (xpInLevel / xpNeeded).clamp(0.0, 1.0);
  }
}
