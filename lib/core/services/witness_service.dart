class WitnessService {
  static String phaseMessage(int phaseIdx, int day, bool isAm) {
    final phases = isAm ? _phasesAm : _phasesEn;
    return phases[phaseIdx.clamp(0, 3)].replaceAll('{day}', '$day');
  }

  static String? quoteForBook(String bookId, {bool isAm = false}) {
    final q = isAm ? _quotesAm[bookId] : _quotesEn[bookId];
    return q ?? _quotesEn[bookId];
  }

  static String? milestoneMessage(int booksCompleted, bool isAm) {
    if (booksCompleted == 0) return null;
    final msgs = isAm ? _milestonesAm : _milestonesEn;
    return msgs[booksCompleted.clamp(0, msgs.length - 1)];
  }

  static String readingRhythmPrompt(int chaptersThisWeek, int lastWeek, bool isAm) {
    if (chaptersThisWeek > lastWeek) {
      return isAm ? 'ይህ ሳምንት ካለፈው የበለጠ አንብበሃል! 🌱' : 'You\'re reading more this week than last! 🌱';
    }
    if (chaptersThisWeek == 0) {
      return isAm ? 'ዛሬ ማንበብ ልትጀምር ትችላለህ' : 'Start your reading today';
    }
    return isAm ? 'ሳምንታዊ ንባብህን ቀጥል' : 'Keep up your weekly rhythm';
  }

  static const _phasesEn = [
    'Day {day} — Discipline Phase. Each day shapes a holy habit.',
    'Day {day} — Faith Phase. Trust grows in the daily return.',
    'Day {day} — Obedience Phase. Not just hearers, but doers.',
    'Day {day} — Impact Phase. Your growth blesses others.',
  ];
  static const _phasesAm = [
    'ቀን {day} — የዲሲፕሊን ምዕራፍ። በየቀኑ ቅዱስ ልማድን ይቀርጻል።',
    'ቀን {day} — የእምነት ምዕራፍ። በየቀኑ መመለስ እምነትን ያሳድጋል።',
    'ቀን {day} — የመታዘዝ ምዕራፍ። ሰሚዎች ብቻ ሳይሆን አድራጊዎችም።',
    'ቀን {day} — የተፅዕኖ ምዕራፍ። እድገትህ ሌሎችን ይባርካል።',
  ];

  static const _milestonesEn = [
    '',
    'You finished your first book! Well done.',
    'Two books complete. Your consistency is growing.',
    'Three books! The Word is taking root in your life.',
    'Keep going — your dedication is building something beautiful.',
  ];
  static const _milestonesAm = [
    '',
    'የመጀመሪያውን መጽሐፍህን ጨርሰሃል! በጣም ጥሩ።',
    'ሁለት መጻሕፍት ተጠናቀዋል። ቅንነትህ እያደገ ነው።',
    'ሦስት መጻሕፍት! ቃሉ በሕይወትህ ውስጥ ሥር እየሰደ ነው።',
    'ቀጥል — ቅንነትህ ውብ ነገርን እየገነባ ነው።',
  ];

  static const Map<String, String> _quotesEn = {
    'GEN': '"The New Testament lies hidden in the Old, and the Old is unveiled in the New." — Augustine',
    'EXO': '"The Exodus is the greatest salvation event of the Old Testament, a shadow of the cross." — St. Athanasius',
    'PSA': '"Most of Scripture speaks to us, but the Psalms speak for us." — Athanasius of Alexandria',
    'PRO': '"The fear of the Lord is the beginning of wisdom. A simple verse that holds all of life." — St. John Chrysostom',
    'ISA': '"The prophet Isaiah saw the glory of the Lord fill the temple — a vision that sustains the faithful." — Ethiopian Tradition',
    'MAT': '"The Sermon on the Mount contains the whole of Christian ethics in seed form." — Augustine',
    'JHN': '"The Gospel of John is like a pool deep enough for an elephant to swim and shallow enough for a lamb to wade." — Gregory the Great',
    'ROM': '"The book of Romans is the purest gospel — it needs no other exposition than itself." — Martin Luther',
    'COR': '"Love is the greatest gift. Without it, all else is noise." — St. John Chrysostom on 1 Corinthians 13',
    'REV': '"The Revelation of John is a book of comfort for the suffering church." — Ethiopian Orthodox Tradition',
  };

  static const Map<String, String> _quotesAm = {
    'GEN': '"ብሉይ ኪዳን በሐዲስ ኪዳን ውስጥ ተሸሽጎ ይገኛል፤ ሐዲስም በብሉይ ውስጥ ይገለጣል።" — አውጉስቲኖስ',
    'EXO': '"ዘፀአት የብሉይ ኪዳን ታላቅ የመዳን ክስተት ነው፤ የመስቀል ጥላ ነው።" — ቅዱስ አትናቴዎስ',
    'PSA': '"አብዛኛው መጽሐፍ ቅዱስ ይነግረናል፤ መዝሙረ ዳዊት ግን ስለ እኛ ይናገራል።" — አትናቴዎስ የእስክንድርያው',
    'PRO': '"እግዚአብሔርን መፍራት የጥበብ መጀመሪያ ነው። ቀላል ቃል ሕይወትን ሁሉ የያዘ።" — ቅዱስ ዮሐንስ አፈወርቅ',
    'ISA': '"ነቢዩ ኢሳይያስ የእግዚአብሔርን ክብር ቤተ መቅደስን ሲሞላ አየ — ምእመናንን የሚደግፍ ራእይ።" — የኢትዮጵያ ትውፊት',
    'MAT': '"የደብረ ታቦር ስብከት የክርስቲያናዊ ሥነ ምግባርን ሁሉ በዘር ይዟል።" — አውጉስቲኖስ',
    'JHN': '"የዮሐንስ ወንጌል ዝሆን የሚዋኝበት ጠልቆ በግምባር የሚራመድበት ጥልቅ ኩሬ ነው።" — ጎርጎርዮስ ታላቁ',
    'ROM': '"የሮሜ መልእክት ንጹሑ ወንጌል ነው — ከራሱ በቀር ሌላ ትርጓሜ አያስፈልገውም።" — ማርቲን ሉተር',
    'COR': '"ፍቅር ታላቁ ስጦታ ነው። ያለ እርሱ ሁሉም ድምፅ ነው።" — ቅዱስ ዮሐንስ አፈወርቅ',
    'REV': '"የዮሐንስ ራእይ ለሚሠቃዩ ቤተ ክርስቲያን የማጽናኛ መጽሐፍ ነው።" — የኢትዮጵያ ኦርቶዶክስ ትውፊት',
  };
}
